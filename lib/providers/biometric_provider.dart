import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;

class BiometricProvider extends ChangeNotifier {
  final LocalAuthentication _auth = LocalAuthentication();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _canCheckBiometrics = false;
  bool _isBiometricEnabled = false;
  String? _savedUsername;
  String? _savedPassword;
  String? _savedLoginMode; // 'guru', 'santri', atau 'orangTua'
  bool _isLoading = false;
  String? _lastError;

  bool get canCheckBiometrics => _canCheckBiometrics;
  bool get isBiometricEnabled => _isBiometricEnabled;
  String? get savedUsername => _savedUsername;
  String? get savedPassword => _savedPassword;
  String? get savedLoginMode => _savedLoginMode;
  bool get isLoading => _isLoading;

  /// Pesan terakhir saat autentikasi/perizinan biometrik gagal (utk UI).
  String? get lastError => _lastError;

  BiometricProvider() {
    _initBiometrics();
  }

  Future<void> _initBiometrics() async {
    try {
      // isDeviceSupported() mencakup biometrik maupun kredensial perangkat
      // (PIN/pola/sandi sistem) — sesuai perilaku "ikut yang ada di system".
      final isDeviceSupported = await _auth.isDeviceSupported();
      final canCheckBiometrics = await _auth.canCheckBiometrics;
      _canCheckBiometrics = isDeviceSupported || canCheckBiometrics;

      await loadSavedCredentials();
    } catch (e) {
      debugPrint('Error init biometrics: $e');
    }
    notifyListeners();
  }

  /// Memuat status kredensial biometrik yang tersimpan.
  Future<void> loadSavedCredentials() async {
    try {
      _savedUsername = await _storage.read(key: 'bio_username');
      _savedPassword = await _storage.read(key: 'bio_password');
      _savedLoginMode = await _storage.read(key: 'bio_mode');
    } catch (e) {
      // Secure storage bisa gagal sesaat (mis. setelah update aplikasi /
      // keystore reset). Degradasi anggun — jangan biarkan status menggantung.
      debugPrint('Error membaca kredensial biometrik: $e');
      _savedUsername = null;
      _savedPassword = null;
      _savedLoginMode = null;
    }

    _isBiometricEnabled = _savedUsername != null &&
        _savedPassword != null &&
        _savedLoginMode != null;
    notifyListeners();
  }

  /// Menyimpan kredensial pengguna secara terenkripsi saat login sukses.
  Future<void> saveCredentials({
    required String username,
    required String password,
    required String loginMode,
  }) async {
    try {
      await _storage.write(key: 'bio_username', value: username);
      await _storage.write(key: 'bio_password', value: password);
      await _storage.write(key: 'bio_mode', value: loginMode);
    } catch (e) {
      debugPrint('Error menyimpan kredensial biometrik: $e');
    }
    await loadSavedCredentials();
  }

  /// Perbarui password tersimpan tanpa mematikan login sidik jari.
  /// Dipakai setelah pengguna mengganti password akun.
  Future<void> updatePassword(String newPassword) async {
    if (_savedUsername == null || _savedLoginMode == null) return;
    try {
      await _storage.write(key: 'bio_password', value: newPassword);
    } catch (e) {
      debugPrint('Error memperbarui password biometrik: $e');
    }
    await loadSavedCredentials();
  }

  /// Menghapus kredensial biometrik (Disable Fingerprint).
  Future<void> clearCredentials() async {
    try {
      await _storage.delete(key: 'bio_username');
      await _storage.delete(key: 'bio_password');
      await _storage.delete(key: 'bio_mode');
    } catch (e) {
      debugPrint('Error menghapus kredensial biometrik: $e');
    }
    await loadSavedCredentials();
  }

  /// Memverifikasi biometrik/kredensial perangkat MANDIRI — tidak mensyaratkan
  /// kredensial akun tersimpan. Memakai kunci perangkat yang sudah terdaftar di
  /// sistem (sidik jari ATAU PIN/pola), tanpa proses pendaftaran sidik jari baru.
  Future<bool> verifyDeviceLock({
    String reason = 'Pindai sidik jari / masukkan PIN perangkat Anda',
  }) async {
    if (!_canCheckBiometrics) return false;
    return _authenticateDevice(reason: reason);
  }

  /// Melakukan verifikasi sidik jari/biometrik utk login aplikasi.
  Future<bool> authenticate() async {
    if (!_canCheckBiometrics || !_isBiometricEnabled) return false;
    return _authenticateDevice(reason: 'Pindai sidik jari Anda untuk masuk ke aplikasi');
  }

  Future<bool> _authenticateDevice({required String reason}) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final authenticated = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
          useErrorDialogs: true,
        ),
      );
      _isLoading = false;
      notifyListeners();
      return authenticated;
    } on PlatformException catch (e) {
      _isLoading = false;
      _lastError = _messageForCode(e.code);
      debugPrint('Biometric PlatformException: ${e.code} — ${e.message}');
      notifyListeners();
      return false;
    } on MissingPluginException {
      _isLoading = false;
      _lastError = 'Biometrik tidak tersedia di perangkat ini.';
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _lastError = 'Verifikasi biometrik gagal: $e';
      notifyListeners();
      return false;
    }
  }

  String _messageForCode(String code) {
    switch (code) {
      case auth_error.notEnrolled:
        return 'Belum ada sidik jari / kunci layar terdaftar di perangkat. '
            'Daftarkan dulu di Pengaturan perangkat.';
      case auth_error.notAvailable:
        return 'Biometrik tidak tersedia di perangkat ini.';
      case auth_error.passcodeNotSet:
        return 'Kunci layar (PIN/pola/sandi) belum diatur di perangkat.';
      case auth_error.lockedOut:
        return 'Verifikasi biometrik terkunci sementara. Coba lagi sebentar.';
      case auth_error.permanentlyLockedOut:
        return 'Biometrik terkunci. Buka kunci lewat PIN/sandi perangkat dulu.';
      default:
        return 'Verifikasi biometrik gagal atau dibatalkan.';
    }
  }
}
