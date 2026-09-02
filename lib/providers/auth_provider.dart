import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../data/api/api_service.dart';
import '../data/local/local_storage.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoading = false;
  bool _isLoggedIn = false;
  bool _isInitialized = false;
  Map<String, dynamic>? _user;
  String? _errorMessage;
  String? _successMessage;

  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  bool get isInitialized => _isInitialized;
  Map<String, dynamic>? get user => _user;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  String? get userRole => _user?['role'];
  bool get isAdmin => _user?['role'] == 'admin';
  bool get isTeacher => _user?['role'] == 'teacher';
  bool get isStudent => _user?['role'] == 'user';
  bool get isParent => _user?['role'] == 'parent';
  String? get userLembaga => _user?['lembaga'];

  Future<void> init() async {
    final token = await LocalStorage.getAccessToken();
    if (token != null) {
      _user = await LocalStorage.getUser();
      _isLoggedIn = _user != null;
      // Jika token ada tapi user hilang (corrupt prefs), bersihkan agar tidak stuck.
      if (_user == null) {
        await LocalStorage.clearAuth();
        _isLoggedIn = false;
      }
    }
    _isInitialized = true;
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

  // ── Generic internal login (DRY) ──

  Future<bool> _loginInternal({
    required String endpoint,
    required Map<String, dynamic> payload,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final response = await _api.dio.post(endpoint, data: payload);

      if (response.statusCode == 200 && response.data['success'] == true) {
        final accessToken = response.data['accessToken'] as String?;
        final refreshToken = response.data['refreshToken'] as String?;

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
        _successMessage = response.data['message']?.toString() ?? 'Login berhasil';
        _isLoggedIn = true;
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
    await LocalStorage.clearAuth();
    _isLoggedIn = false;
    _user = null;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
