import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../data/api/api_service.dart';
import '../data/local/local_storage.dart';
import '../services/notification_center.dart';
import '../utils/password_strength.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoading = false;
  bool _isLoggedIn = false;
  bool _isInitialized = false;
  Map<String, dynamic>? _user;
  String? _errorMessage;
  String? _successMessage;
  String? _googleNeedLinkEmail;
  bool _registrationPending = false;

  // ── Kredensial sesi terakhir (hanya di memori, tidak dipersist) ──
  // Dipakai agar pengaktifan login sidik jari dari Pengaturan tidak perlu
  // meminta password ulang (password diambil dari sesi yang sedang aktif).
  String? _lastLoginPassword;

  // ── Diagnosa kegagalan login terakhir ──
  // true bila server MENOLAK kredensial (HTTP 401/403) — dipakai login page utk
  // membersihkan kredensial sidik jari yg basi. false utk error jaringan.
  bool _lastLoginAuthFailed = false;

  // ── Wajib ganti password (login santri dgn password awal) ──
  bool _mustChangePassword = false;
  String? _pendingLoginNim;
  String? _pendingLoginPassword;

  /// True bila login santri memakai password awal (tanggal lahir / default)
  /// yang tidak memenuhi kriteria kekuatan password — dashboard wajib memunculkan
  /// dialog ganti password.
  bool get mustChangePassword => _mustChangePassword;

  /// NIM santri dari login terakhir dgn password lemah (dipakai utk re-login
  /// setelah ganti password). Hanya di memori — tidak pernah dipersist.
  String? get pendingLoginNim => _pendingLoginNim;

  /// Password (plaintext) dari login terakhir dgn password lemah — dipakai sbg
  /// currentPassword saat ganti password. Hanya di memori.
  String? get pendingLoginPassword => _pendingLoginPassword;

  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  bool get isInitialized => _isInitialized;
  Map<String, dynamic>? get user => _user;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  String? get googleNeedLinkEmail => _googleNeedLinkEmail;
  /// True bila permintaan registrasi Google saat ini berstatus PENDING
  /// (menunggu konfirmasi admin) — dipakai login page utk tampil pesan khusus.
  bool get registrationPending => _registrationPending;

  /// Password plaintext dari login manual TERAKHIR yang berhasil (hanya di
  /// memori). Dipakai utk mengaktifkan login sidik jari tanpa meminta input
  /// password lagi. null bila sesi dipulihkan tanpa login (restore) atau login
  /// melalui Google.
  String? get lastLoginPassword => _lastLoginPassword;

  /// True bila percobaan login terakhir ditolak server (kredensial salah),
  /// bukan karena masalah jaringan.
  bool get lastLoginAuthFailed => _lastLoginAuthFailed;
  String? get userRole => _user?['role'];
  bool get isAdmin => _user?['role'] == 'admin';
  bool get isTeacher => _user?['role'] == 'teacher';
  bool get isStudent => _user?['role'] == 'user';
  bool get isParent => _user?['role'] == 'parent';
  String? get userLembaga => _user?['lembaga'];

  // ── Guru merangkap pimpinan (v3.4x) ──
  // Flag dari backend: user login bertipe guru yang juga terdaftar sebagai
  // pimpinan aktif (tabel pimpinan.teacher_id, aktif = 1).
  bool get isPimpinan => _user?['is_pimpinan'] == true;
  String? get pimpinanJabatan => _user?['pimpinan_jabatan']?.toString();
  bool get canUsePimpinanMode => isAdmin || isPimpinan;

  bool _pimpinanMode = false;

  /// Sedang berada di "Mode Pimpinan" (menu kelola lembaga tampil bagi guru
  /// yang merangkap pimpinan). Murni state lokal app — tidak mengganti login.
  bool get isPimpinanMode => _pimpinanMode;

  void setPimpinanMode(bool value) {
    if (_pimpinanMode == value) return;
    _pimpinanMode = value;
    notifyListeners();
  }

  Future<void> init() async {
    // Saat interceptor mendeteksi sesi tak bisa dipulihkan → paksa kembali ke login.
    ApiService.onSessionExpired = _forceSessionExpired;

    final token = await LocalStorage.getAccessToken();
    if (token == null) {
      _finishInit();
      return;
    }

    final user = await LocalStorage.getUser();
    if (user == null) {
      // Token ada tapi user hilang (corrupt prefs), bersihkan agar tidak stuck.
      await LocalStorage.clearAuth();
      _finishInit();
      return;
    }

    _user = user;
    _isLoggedIn = true;

    // Validasi sesi: pastikan token masih berlaku di server & identitas user diketahui.
    if (!await _restoreSession()) {
      // Bersihkan token basi agar restart berikutnya tidak mengulang validasi gagal.
      await LocalStorage.clearAuth();
      _forceSessionExpired();
    }

    // Self-heal: segarkan status "guru merangkap pimpinan" tiap kali app dibuka,
    // supaya avatar bisa membuka dialog Mode Pimpinan walau sesi tersimpan lama
    // (payload refresh/login sebelumnya belum memuat flag is_pimpinan).
    if (_isLoggedIn && (isTeacher || isAdmin)) {
      debugPrint('[PIMPINAN] init: role=$userRole -> mulai _refreshPimpinanStatus()');
      await _refreshPimpinanStatus();
    } else {
      debugPrint('[PIMPINAN] init: role=$userRole (bukan guru/admin), self-heal dilewati');
    }
    debugPrint('[PIMPINAN] init(SELESAI): isPimpinan=$isPimpinan jabatan=$pimpinanJabatan');

    _finishInit();
  }

  /// GET /auth/me/identities lalu sinkronkan flag is_pimpinan/pimpinan_jabatan
  /// (dan akun wali terkait) ke state + LocalStorage. Silent — tidak ubah pesan
  /// error/loading agar tidak mengganggu layar login saat startup.
  Future<void> _refreshPimpinanStatus() async {
    debugPrint('[PIMPINAN] refresh: memanggil GET /auth/me/identities ...');
    try {
      final response = await _api.dio.get('/auth/me/identities');
      final data = response.data;
      debugPrint('[PIMPINAN] refresh: HTTP ${response.statusCode} raw=${(data is Map) ? data.keys : data}');
      if (data is! Map || data['success'] != true) {
        debugPrint('[PIMPINAN] refresh: success != true -> TIDAK update');
        return;
      }
      final identities = data['identities'];
      if (identities is! Map) {
        debugPrint('[PIMPINAN] refresh: identities bukan Map -> TIDAK update');
        return;
      }

      final teacher = identities['teacher'];
      final parent = identities['parent'];
      _linkedParent = parent is Map ? Map<String, dynamic>.from(parent) : null;

      if (teacher is Map) {
        debugPrint('[PIMPINAN] refresh: teacher=$teacher');
        debugPrint('[PIMPINAN] refresh: teacher["is_pimpinan"]=${teacher['is_pimpinan']} (tipe ${teacher['is_pimpinan'].runtimeType})');
      }

      if (teacher is Map && teacher['is_pimpinan'] != null) {
        final merged = {
          ...?_user,
          'is_pimpinan': teacher['is_pimpinan'],
          'pimpinan_jabatan': teacher['pimpinan_jabatan'],
        };
        await LocalStorage.saveUser(merged);
        _user = merged;
        debugPrint('[PIMPINAN] refresh: SUDAH update -> isPimpinan=$isPimpinan jabatan=$pimpinanJabatan');
      } else {
        debugPrint('[PIMPINAN] refresh: teacher kosong/tanpa is_pimpinan -> TIDAK update');
      }
      notifyListeners();
    } on DioException catch (e) {
      debugPrint('[PIMPINAN] refresh: GAGAL DioException type=${e.type} status=${e.response?.statusCode} msg=${e.message}');
    } catch (e) {
      debugPrint('[PIMPINAN] refresh: GAGAL $e');
    }
  }

  /// Post /auth/refresh-token utk memvalidasi & memperbarui sesi saat app dibuka.
  /// Return true bila sesi dipertahankan. Return false bila server menolak sesi.
  Future<bool> _restoreSession() async {
    final refreshToken = await LocalStorage.getRefreshToken();
    if (refreshToken == null) return false;

    try {
      final response = await _api.dio.post(
        '/auth/refresh-token',
        data: {'refreshToken': refreshToken},
      );

      final data = response.data;
      final accessToken = data?['accessToken']?.toString();
      if (accessToken == null) return false;

      final newRefresh =
          data['refreshToken']?.toString() ?? refreshToken;
      await LocalStorage.saveAuthTokens(accessToken, newRefresh);

      // Sinkronkan identitas user terbaru dari server (bila disertakan).
      final freshUser = data['user'];
      if (freshUser is Map) {
        final merged = {...?_user, ...Map<String, dynamic>.from(freshUser)};
        await LocalStorage.saveUser(merged);
        _user = merged;
        debugPrint('[PIMPINAN] refresh-token: freshUser keys=${freshUser.keys} | is_pimpinan=${freshUser['is_pimpinan']} jabatan=${freshUser['pimpinan_jabatan']}');
        debugPrint('[PIMPINAN] refresh-token: setelah merge -> isPimpinan=$isPimpinan');
      } else {
        debugPrint('[PIMPINAN] refresh-token: server TIDAK mengirim key "user"');
      }
      return true;
    } on DioException catch (e) {
      // Server menolak token (mati/revoked) → sesi berakhir.
      if (e.response != null) return false;
      // Error jaringan/timeout → pertahankan sesi (network mungkin pulih).
      return true;
    }
  }

  void _finishInit() {
    _isInitialized = true;
    notifyListeners();
  }

  /// Efek samping dari ApiService.onSessionExpired: reset state agar AuthGate
  /// kembali ke LoginPage dengan pesan "Sesi berakhir".
  void _forceSessionExpired() {
    _isLoggedIn = false;
    _user = null;
    _pimpinanMode = false;
    _mustChangePassword = false;
    _pendingLoginNim = null;
    _pendingLoginPassword = null;
    _errorMessage = 'Sesi berakhir. Silakan login ulang.';
    notifyListeners();
  }

  // ── Public login methods ──

  Future<bool> login(String username, String password) async {
    return _loginInternal(
      endpoint: '/auth/login',
      payload: {'username': username.trim(), 'password': password.trim()},
    );
  }

  Future<bool> loginStudent(String nim, String password) async {
    return _loginInternal(
      endpoint: '/auth/login-student',
      payload: {'nim': nim.trim(), 'password': password.trim()},
    );
  }

  Future<bool> loginParent(String phone, String password) async {
    // Normalisasi phone: hapus spasi/dash, trim.
    final normalizedPhone = phone.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
    return _loginInternal(
      endpoint: '/auth/login-parent',
      payload: {'phone': normalizedPhone, 'password': password.trim()},
    );
  }

  /// POST /auth/change-password — ubah password sendiri lalu re-login utk
  /// memperbarui refresh token (backend mencabut seluruh refresh token saat
  /// password diganti). Identitas login diperoleh dari akun sesi saat ini
  /// (NIM santri / username guru-admin / phone orang tua), atau dari NIM yg
  /// disimpan saat login santri dgn password awal.
  /// Return true bila password berhasil diubah (sesi diperbarui bila memungkinkan).
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
    try {
      final response = await _api.dio.post(
        '/auth/change-password',
        data: {'currentPassword': currentPassword, 'newPassword': newPassword},
      );
      final data = response.data;
      if (data is Map && data['success'] == true) {
        _successMessage =
            data['message']?.toString() ?? 'Password berhasil diubah.';
        _mustChangePassword = false;
        await _reloginAfterChange(newPassword);
        _pendingLoginNim = null;
        _pendingLoginPassword = null;
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _errorMessage = data is Map
          ? (data['message']?.toString() ?? 'Gagal mengubah password.')
          : 'Gagal mengubah password.';
      _isLoading = false;
      notifyListeners();
      return false;
    } on DioException catch (e) {
      _errorMessage = _dioErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Login ulang dgn password baru agar refresh token (yg di-revoke backend)
  /// diperbarui. Best-effort — gagal re-login tidak menggagalkan perubahan.
  Future<bool> _reloginAfterChange(String newPassword) async {
    final role = _user?['role'];
    if (role == 'user') {
      final nim = (_pendingLoginNim ?? _user?['nim'])?.toString();
      if (nim == null || nim.isEmpty) return false;
      return _loginInternal(
        endpoint: '/auth/login-student',
        payload: {'nim': nim, 'password': newPassword},
      );
    }
    if (role == 'parent') {
      final phone = _user?['phone']?.toString();
      if (phone == null || phone.isEmpty) return false;
      return _loginInternal(
        endpoint: '/auth/login-parent',
        payload: {'phone': phone, 'password': newPassword},
      );
    }
    if (role == 'admin' || role == 'teacher') {
      final username = _user?['username']?.toString();
      if (username == null || username.isEmpty) return false;
      return _loginInternal(
        endpoint: '/auth/login',
        payload: {'username': username, 'password': newPassword},
      );
    }
    return false;
  }

  /// Login lewat Google (admin & guru) — memakai idToken hasil google_sign_in.
  /// Backend memverifikasi idToken dan menolak bila akun Google belum tertaut (401 needLink).
  Future<bool> loginGoogle(String idToken) async {
    return _loginInternal(
      endpoint: '/auth/google',
      payload: {'idToken': idToken},
    );
  }

  /// Daftar akun baru via Google (POST /auth/register-google) — publik.
  /// Registrasi disimpan berstatus PENDING menunggu konfirmasi admin.
  /// Return true bila pendaftaran terkirim (201). Bila akun sudah terhubung /
  /// sudah pernah mendaftar → false + [errorMessage] (registrationPending ikut diset).
  Future<bool> registerGoogle(String idToken, {String? catatan}) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    _googleNeedLinkEmail = null;
    _registrationPending = false;
    notifyListeners();

    try {
      final response = await _api.dio.post(
        '/auth/register-google',
        data: {'idToken': idToken, 'catatan': catatan?.trim().isEmpty == true ? null : catatan?.trim()},
      );

      final data = response.data;
      if (response.statusCode == 201 && data is Map && data['success'] == true) {
        _registrationPending = true;
        _successMessage =
            data['message']?.toString() ?? 'Pendaftaran berhasil! Menunggu konfirmasi admin.';
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _errorMessage = data is Map
          ? (data['message']?.toString() ?? 'Gagal mengirim pendaftaran.')
          : 'Gagal mengirim pendaftaran.';
      _isLoading = false;
      notifyListeners();
      return false;
    } on DioException catch (e) {
      _errorMessage = _dioErrorMessage(e);
      if (e.response?.statusCode == 409) {
        final data = e.response?.data;
        if (data is Map && data['registrationPending'] == true) {
          _registrationPending = true;
        }
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Status tautan Google akun sendiri (GET /auth/google/status).
  /// Return null bila gagal (pesan error di [_errorMessage]).
  Future<Map<String, dynamic>?> getGoogleAuthStatus() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await _api.dio.get('/auth/google/status');
      final data = response.data;
      if (data is Map && data['success'] == true) {
        _isLoading = false;
        notifyListeners();
        return Map<String, dynamic>.from(data);
      }
      _errorMessage = data is Map
          ? (data['message']?.toString() ?? 'Gagal memuat status Google.')
          : 'Gagal memuat status Google.';
      _isLoading = false;
      notifyListeners();
      return null;
    } on DioException catch (e) {
      _errorMessage = _dioErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Tautkan akun Google ke akun saat ini (POST /auth/link-google).
  Future<bool> linkGoogle(String idToken) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
    try {
      final response = await _api.dio.post(
        '/auth/link-google',
        data: {'idToken': idToken},
      );
      final data = response.data;
      if (data is Map && data['success'] == true) {
        final googleEmail = data['google_email']?.toString();
        if (googleEmail != null) {
          final merged = {...?_user, 'google_email': googleEmail};
          await LocalStorage.saveUser(merged);
          _user = merged;
        }
        _successMessage =
            data['message']?.toString() ?? 'Akun Google berhasil ditautkan.';
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _errorMessage = data is Map
          ? (data['message']?.toString() ?? 'Gagal menautkan akun Google.')
          : 'Gagal menautkan akun Google.';
      _isLoading = false;
      notifyListeners();
      return false;
    } on DioException catch (e) {
      _errorMessage = _dioErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Putuskan tautan Google akun sendiri (DELETE /auth/link-google).
  Future<bool> unlinkGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
    try {
      final response = await _api.dio.delete('/auth/link-google');
      final data = response.data;
      if (data is Map && data['success'] == true) {
        final merged = {...?_user};
        merged.remove('google_email');
        await LocalStorage.saveUser(merged);
        _user = merged;
        _successMessage =
            data['message']?.toString() ?? 'Tautan Google berhasil diputuskan.';
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _errorMessage = data is Map
          ? (data['message']?.toString() ?? 'Gagal memutuskan tautan Google.')
          : 'Gagal memutuskan tautan Google.';
      _isLoading = false;
      notifyListeners();
      return false;
    } on DioException catch (e) {
      _errorMessage = _dioErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ── Portal Wali + Guru (v3.40): guru yang juga orang tua ──

  Map<String, dynamic>? _linkedParent;
  Map<String, dynamic>? _teacherSessionBackup;

  /// Akun wali (orang tua) yg terhubung ke akun guru yg sedang login (bila ada).
  Map<String, dynamic>? get linkedParent => _linkedParent;

  /// Ada sesi guru yg disimpan sementara saat sedang di portal wali
  /// (dipakai tombol "Kembali ke Portal Guru").
  bool get hasTeacherSessionBackup => _teacherSessionBackup != null;

  /// GET /auth/me/identities — identitas guru + akun wali yg terkait.
  Future<bool> getMyIdentities() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await _api.dio.get('/auth/me/identities');
      final data = response.data;
      if (data is Map && data['success'] == true) {
        final identities = data['identities'];
        if (identities is Map) {
          final parent = identities['parent'];
          _linkedParent = parent is Map
              ? Map<String, dynamic>.from(parent)
              : null;
        }
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _errorMessage = data is Map
          ? (data['message']?.toString() ?? 'Gagal memuat identitas.')
          : 'Gagal memuat identitas.';
      _isLoading = false;
      notifyListeners();
      return false;
    } on DioException catch (e) {
      _errorMessage = _dioErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// POST /auth/me/parent-link — hubungkan akun wali via No HP.
  Future<bool> linkParentAccount(String phone) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
    try {
      final response = await _api.dio.post(
        '/auth/me/parent-link',
        data: {'phone': phone.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '')},
      );
      final data = response.data;
      if (data is Map && data['success'] == true) {
        final parent = data['parent'];
        _linkedParent = parent is Map ? Map<String, dynamic>.from(parent) : null;
        _successMessage = data['message']?.toString() ?? 'Akun wali berhasil dihubungkan.';
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _errorMessage = data is Map
          ? (data['message']?.toString() ?? 'Gagal menghubungkan akun wali.')
          : 'Gagal menghubungkan akun wali.';
      _isLoading = false;
      notifyListeners();
      return false;
    } on DioException catch (e) {
      _errorMessage = _dioErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// DELETE /auth/me/parent-link — putuskan kaitan akun wali.
  Future<bool> unlinkParentAccount() async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
    try {
      final response = await _api.dio.delete('/auth/me/parent-link');
      final data = response.data;
      if (data is Map && data['success'] == true) {
        _linkedParent = null;
        _successMessage = data['message']?.toString() ?? 'Kaitan akun wali diputuskan.';
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _errorMessage = data is Map
          ? (data['message']?.toString() ?? 'Gagal memutuskan kaitan akun wali.')
          : 'Gagal memutuskan kaitan akun wali.';
      _isLoading = false;
      notifyListeners();
      return false;
    } on DioException catch (e) {
      _errorMessage = _dioErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// POST /auth/switch-parent — login silang ke portal wali.
  /// Sesi guru disimpan sementara agar bisa kembali (switchBackToTeacher).
  Future<bool> switchToParent() async {
    if (!isParent) {
      final access = await LocalStorage.getAccessToken();
      final refresh = await LocalStorage.getRefreshToken();
      _teacherSessionBackup = {
        'accessToken': access,
        'refreshToken': refresh,
        'user': {...?_user},
      };
    }
    final ok = await _loginInternal(endpoint: '/auth/switch-parent', payload: {});
    if (!ok) {
      _teacherSessionBackup = null;
    }
    return ok;
  }

  /// Pulihkan sesi guru yg disimpan sementara saat switchToParent.
  Future<bool> switchBackToTeacher() async {
    final backup = _teacherSessionBackup;
    if (backup == null) return false;
    final access = backup['accessToken'];
    final refresh = backup['refreshToken'];
    final user = backup['user'];
    if (access is! String || refresh is! String || user is! Map) return false;

    await LocalStorage.saveAuthTokens(access, refresh);
    await LocalStorage.saveUser(Map<String, dynamic>.from(user));
    _user = Map<String, dynamic>.from(user);
    _isLoggedIn = true;
    _teacherSessionBackup = null;
    _successMessage = 'Kembali ke portal guru.';
    notifyListeners();
    return true;
  }

  // ── Generic internal login (DRY) ──

  Future<bool> _loginInternal({
    required String endpoint,
    required Map<String, dynamic> payload,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    _googleNeedLinkEmail = null;
    _lastLoginAuthFailed = false;
    notifyListeners();

    try {
      final response = await _api.dio.post(endpoint, data: payload);

      if (response.statusCode == 200 && response.data['success'] == true) {
        final accessToken = response.data['accessToken'] as String?;
        final refreshToken = response.data['refreshToken'] as String?;

        // Login santri: deteksi password awal (tanggal lahir / default) lewat
        // kriteria kekuatan password. Lemah → wajib ganti password setelah masuk.
        if (endpoint == '/auth/login-student') {
          final pwd = payload['password'] as String? ?? '';
          _mustChangePassword = !isStrongPassword(pwd);
          if (_mustChangePassword) {
            _pendingLoginNim = payload['nim']?.toString();
            _pendingLoginPassword = pwd;
          } else {
            _pendingLoginNim = null;
            _pendingLoginPassword = null;
          }
        }

        if (accessToken == null || refreshToken == null) {
          _errorMessage = 'Token tidak diterima dari server.';
          _isLoading = false;
          notifyListeners();
          return false;
        }

        await LocalStorage.saveAuthTokens(accessToken, refreshToken);

        final user = response.data['user'];
        if (user is Map<String, dynamic>) {
          await LocalStorage.saveUser(user);
          _user = user;
        } else if (user is Map) {
          final casted = Map<String, dynamic>.from(user);
          await LocalStorage.saveUser(casted);
          _user = casted;
        }
        debugPrint('[PIMPINAN] login($endpoint): role=${user?['role']} keys=${(user is Map) ? user.keys : 'no-user'} | is_pimpinan=${user?['is_pimpinan']} jabatan=${user?['pimpinan_jabatan']}');
        _successMessage = response.data['message']?.toString() ?? 'Login berhasil';
        _isLoggedIn = true;
        // Simpan password sesi (null utk login Google) agar pengaktifan sidik
        // jari dari Pengaturan tidak perlu meminta password ulang.
        _lastLoginPassword = payload['password'] as String?;
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _errorMessage = response.data['message']?.toString() ?? 'Login gagal.';
      _isLoading = false;
      notifyListeners();
      return false;
    } on DioException catch (e) {
      _errorMessage = _dioErrorMessage(e);
      // Tandai bila server menolak kredensial (bukan error jaringan).
      final status = e.response?.statusCode;
      _lastLoginAuthFailed = status == 401 || status == 403;
      if (endpoint == '/auth/google') {
        final data = e.response?.data;
        if (data is Map && data['needLink'] == true) {
          final email = data['google_email']?.toString();
          _googleNeedLinkEmail = email;
          if (email != null && email.isNotEmpty) {
            _errorMessage = _buildNeedLinkMessage(email);
          }
        }
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Pesan jelas saat akun Google yg dipakai belum tertaut — mencantumkan EMAIL
  /// akun Google yg dicoba agar pengguna tahu akun mana yg dikirim ke server
  /// (bukan sekadar "belum terhubung" yg membingungkan).
  String _buildNeedLinkMessage(String googleEmail) {
    return 'Akun Google "$googleEmail" belum terhubung ke akun MMU mana pun.\n'
        'Gunakan akun Google yg sama dgn saat menghubungkan, atau login pakai '
        'username/password lalu hubungkan via menu Profil → Akun Google.';
  }

  String _dioErrorMessage(DioException e) {
    if (e.response != null) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
      final code = e.response?.statusCode;
      // Pesan ramah per status
      if (code == 401) return data is Map && data['message'] != null ? data['message'].toString() : 'Username/NIM/No HP atau password salah.';
      if (code == 403) return data is Map && data['message'] != null ? data['message'].toString() : 'Akses ditolak. Silakan login ulang.';
      if (code != null && code >= 500) return 'Server sedang bermasalah. Coba lagi nanti.';
      return 'Login gagal (HTTP $code).';
    }
    // Timeout / network
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return 'Koneksi timeout. Periksa jaringan Anda.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Tidak dapat terhubung ke server. Periksa API_URL dan jaringan.';
    }
    return 'Terjadi kesalahan koneksi: ${e.message}';
  }

  Future<void> logout() async {
    try {
      final refreshToken = await LocalStorage.getRefreshToken();
      if (refreshToken != null) {
        await _api.dio.post(
          '/auth/logout',
          data: {'refreshToken': refreshToken},
        );
      }
    } catch (_) {}
    // Batalkan reminder jadwal yang dijadwalkan guru sebelumnya (ganti akun).
    LocalNotificationCenter.instance.clearScheduleReminders();
    await LocalStorage.clearAuth();
    _isLoggedIn = false;
    _user = null;
    _linkedParent = null;
    _teacherSessionBackup = null;
    _pimpinanMode = false;
    _mustChangePassword = false;
    _pendingLoginNim = null;
    _pendingLoginPassword = null;
    _lastLoginPassword = null;
    _lastLoginAuthFailed = false;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
