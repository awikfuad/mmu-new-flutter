// ignore_for_file: deprecated_member_use
// DEPRECATED: Gunakan AuthProvider (providers/auth_provider.dart) sebagai source of truth.
// File ini dipertahankan hanya untuk kompatibilitas; jangan dipakai di kode baru.
import 'package:dio/dio.dart';
import '../data/api/api_service.dart';
import '../data/local/local_storage.dart';

@Deprecated('Gunakan AuthProvider. AuthController akan dihapus di rilis berikutnya.')
class AuthController {
  final ApiService _apiService = ApiService();

  // Fungsi login ke backend MMU A-44 (Express)
  // Endpoint gabungan /auth/login menangani role guru & admin sekaligus.
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _apiService.dio.post(
        '/auth/login',
        data: {
          'username': username,
          'password': password,
        },
      );

      // Backend mengembalikan accessToken + refreshToken + user
      if (response.statusCode == 200 && response.data['success'] == true) {
        final String accessToken = response.data['accessToken'];
        final String refreshToken = response.data['refreshToken'];

        // Simpan token ke SharedPreferences
        await LocalStorage.saveAuthTokens(accessToken, refreshToken);

        final user = response.data['user'];
        if (user is Map<String, dynamic>) {
          await LocalStorage.saveUser(user);
        }

        return {
          'success': true,
          'message': response.data['message'],
          'user': user,
        };
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'Login gagal.',
      };
    } on DioException catch (e) {
      String errorMessage = 'Terjadi kesalahan koneksi.';
      if (e.response != null) {
        final dynamic data = e.response?.data;
        if (data is Map && data['message'] != null) {
          errorMessage = data['message'].toString();
        } else {
          errorMessage = 'Login gagal (HTTP ${e.response?.statusCode}).';
        }
      } else {
        errorMessage = 'Terjadi kesalahan koneksi: ${e.message}';
      }
      return {
        'success': false,
        'message': errorMessage,
      };
    }
  }

  // Login santri/murid (mobile): NIM + password tanggal lahir
  Future<Map<String, dynamic>> loginStudent(String nim, String password) async {
    try {
      final response = await _apiService.dio.post(
        '/auth/login-student',
        data: {
          'nim': nim,
          'password': password,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final String accessToken = response.data['accessToken'];
        final String refreshToken = response.data['refreshToken'];

        await LocalStorage.saveAuthTokens(accessToken, refreshToken);

        final user = response.data['user'];
        if (user is Map<String, dynamic>) {
          await LocalStorage.saveUser(user);
        }

        return {
          'success': true,
          'message': response.data['message'],
          'user': user,
        };
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'Login gagal.',
      };
    } on DioException catch (e) {
      String errorMessage = 'Terjadi kesalahan koneksi.';
      if (e.response != null) {
        final dynamic data = e.response?.data;
        if (data is Map && data['message'] != null) {
          errorMessage = data['message'].toString();
        } else {
          errorMessage = 'Login gagal (HTTP ${e.response?.statusCode}).';
        }
      } else {
        errorMessage = 'Terjadi kesalahan koneksi: ${e.message}';
      }
      return {
        'success': false,
        'message': errorMessage,
      };
    }
  }

  // Logout: revoke refresh token di server + bersihkan token lokal
  Future<void> logout() async {
    try {
      final refreshToken = await LocalStorage.getRefreshToken();
      if (refreshToken != null) {
        await _apiService.dio.post(
          '/auth/logout',
          data: {'refreshToken': refreshToken},
        );
      }
    } catch (_) {
      // Tetap lanjutkan logout lokal walau API gagal
    }
    await LocalStorage.clearAuth();
  }
}
