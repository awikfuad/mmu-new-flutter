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

  bool get canCheckBiometrics => _canCheckBiometrics;
  bool get isBiometricEnabled => _isBiometricEnabled;
  String? get savedUsername => _savedUsername;
  String? get savedPassword => _savedPassword;
  String? get savedLoginMode => _savedLoginMode;
  bool get isLoading => _isLoading;

  BiometricProvider() {
    _initBiometrics();
  }

  Future<void> _initBiometrics() async {
    try {
      final canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      _canCheckBiometrics = canAuthenticateWithBiometrics && isDeviceSupported;

      await loadSavedCredentials();
    } catch (e) {
      debugPrint('Error init biometrics: $e');
    }
    notifyListeners();
  }

  /// Memuat status kredensial biometrik yang tersimpan
  Future<void> loadSavedCredentials() async {
    _savedUsername = await _storage.read(key: 'bio_username');
    _savedPassword = await _storage.read(key: 'bio_password');
    _savedLoginMode = await _storage.read(key: 'bio_mode');

    _isBiometricEnabled = _savedUsername != null &&
        _savedPassword != null &&
        _savedLoginMode != null;
    notifyListeners();
  }

  /// Menyimpan kredensial pengguna secara terenkripsi saat login sukses pertama kali
  Future<void> saveCredentials({
    required String username,
    required String password,
    required String loginMode,
  }) async {
    await _storage.write(key: 'bio_username', value: username);
    await _storage.write(key: 'bio_password', value: password);
    await _storage.write(key: 'bio_mode', value: loginMode);
    await loadSavedCredentials();
  }

  /// Menghapus kredensial biometrik (Disable Fingerprint)
  Future<void> clearCredentials() async {
    await _storage.delete(key: 'bio_username');
    await _storage.delete(key: 'bio_password');
    await _storage.delete(key: 'bio_mode');
    await loadSavedCredentials();
  }

  /// Verifikasi biometrik mandiri (dipakai saat mengaktifkan login sidik jari
  /// dari pengaturan akun) — tidak mensyaratkan kredensial sudah tersimpan.
  Future<bool> verifyFingerprint() async {
    if (!_canCheckBiometrics) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final authenticated = await _auth.authenticate(
        localizedReason: 'Pindai sidik jari Anda untuk mengaktifkan login sidik jari',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      _isLoading = false;
      notifyListeners();
      return authenticated;
    } on PlatformException catch (e) {
      _isLoading = false;
      notifyListeners();
      if (e.code == auth_error.notEnrolled) {
        debugPrint('Biometric belum terdaftar di perangkat');
      }
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Melakukan verifikasi sidik jari/biometrik
  Future<bool> authenticate() async {
    if (!_canCheckBiometrics || !_isBiometricEnabled) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final authenticated = await _auth.authenticate(
        localizedReason: 'Pindai sidik jari Anda untuk masuk ke aplikasi',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      _isLoading = false;
      notifyListeners();
      return authenticated;
    } on PlatformException catch (e) {
      _isLoading = false;
      notifyListeners();
      if (e.code == auth_error.notEnrolled) {
        debugPrint('Biometric belum terdaftar di perangkat');
      }
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}