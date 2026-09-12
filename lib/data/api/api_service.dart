import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../local/local_storage.dart';

class ApiService {
  // Singleton — semua provider berbagi 1 Dio + 1 mutex refresh.
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal() {
    _initDio();
  }

  final Dio dio = Dio();

  static Completer<void>? _refreshCompleter;

  /// Handler dipanggil saat sesi tidak bisa dipulihkan (refresh gagal / token habis).
  /// Dipakai AuthProvider utk logout otomatis sehingga UI kembali ke halaman login.
  static void Function()? onSessionExpired;

  /// Bersihkan storage auth lalu beri tahu app bahwa sesi berakhir.
  static Future<void> _clearAuthAndNotify() async {
    await LocalStorage.clearAuth();
    final cb = onSessionExpired;
    if (cb != null) cb();
  }

  // OVERRIDE_API_URL: set via --dart-define=OVERRIDE_API_URL=... saat build CI/release.
  // Kosong = gunakan DEFAULT_API_URL.
  static const String _overrideBaseUrl = String.fromEnvironment(
    'OVERRIDE_API_URL',
    defaultValue: 'https://mmu-new-backend.vercel.app/api',
  );
  // DEFAULT_API_URL: fallback untuk local development.
  static const String _defaultBaseUrl = String.fromEnvironment(
    'DEFAULT_API_URL',
    defaultValue: 'http://localhost:5000/api',
  );

  static String get _rawBaseUrl =>
      _overrideBaseUrl.isNotEmpty ? _overrideBaseUrl : _defaultBaseUrl;

  /// Normalisasi baseUrl: trim, hapus trailing slash, fallback emulator.
  static String get baseUrl {
    var url = _rawBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    // Di Android emulator localhost tidak reachable — fallback ke 10.0.2.2 otomatis.
    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        url.contains('localhost')) {
      url = url.replaceAll('localhost', '10.0.2.2');
    }
    return url;
  }

  // Runtime override via SharedPreferences
  static String? _runtimeOverride;
  static Future<void> setRuntimeBaseUrl(String url) async {
    _runtimeOverride = url.trim().replaceAll(RegExp(r'/+$'), '');
  }

  static String get effectiveBaseUrl => _runtimeOverride ?? baseUrl;

  void _initDio() {
    dio.options.baseUrl = effectiveBaseUrl;
    dio.options.connectTimeout = const Duration(seconds: 10);
    dio.options.receiveTimeout = const Duration(seconds: 10);
    dio.options.headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Sync baseUrl terbaru jika runtime override berubah
          options.baseUrl = effectiveBaseUrl;

          if (_isPublicAuthEndpoint(options.path)) {
            return handler.next(options);
          }

          final token = await LocalStorage.getAccessToken();

          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          return handler.next(options);
        },
        onError: (e, handler) async {
          await _handleUnauthorized(e, handler);
        },
      ),
    );
  }

  /// Hanya endpoint auth yang BENAR-BENAR publik (tanpa Bearer token):
  /// login*, google (login), refresh-token, logout.
  /// Endpoint auth lain (google/status, link-google, change-password) TETAP
  /// butuh token — jangan lumpuhkan header di sini agar `GET /auth/google/status`
  /// & `POST /auth/link-google` tidak gagal 401 tanpa header.
  bool _isPublicAuthEndpoint(String path) {
    final p = path.toLowerCase();
    if (p.contains('/auth/login')) return true; // login-admin/teacher/student/parent + login unified
    if (p == '/auth/google') return true;
    if (p == '/auth/refresh-token') return true;
    if (p == '/auth/logout') return true;
    return false;
  }

  bool _shouldAttemptRefresh(DioException e) {
    final code = e.response?.statusCode;
    if (code != 401 && code != 403) return false;
    if (_isPublicAuthEndpoint(e.requestOptions.path)) return false;

    if (code == 403) {
      final msg = e.response?.data is Map
          ? (e.response?.data['message']?.toString().toLowerCase() ?? '')
          : '';
      if (msg.isNotEmpty &&
          !msg.contains('token') &&
          !msg.contains('kedaluwarsa') &&
          !msg.contains('valid') &&
          !msg.contains('login ulang')) {
        return false;
      }
    }
    return true;
  }

  Future<void> _handleUnauthorized(
      DioException e, ErrorInterceptorHandler handler) async {
    if (!_shouldAttemptRefresh(e)) {
      return handler.next(e);
    }

    // Instance Dio terpisah tanpa interceptor untuk menghindari infinite loop pada refresh/retry
    final refreshDio = Dio(BaseOptions(
      baseUrl: effectiveBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ));

    // Jika refresh sedang berjalan di request lain, tunggu hingga selesai
    if (_refreshCompleter != null && !_refreshCompleter!.isCompleted) {
      await _refreshCompleter!.future;
        final freshToken = await LocalStorage.getAccessToken();
      if (freshToken != null) {
        try {
          final retryOptions = e.requestOptions.copyWith();
          retryOptions.headers['Authorization'] = 'Bearer $freshToken';
          final retryResponse = await refreshDio.fetch(retryOptions);
          return handler.resolve(retryResponse);
        } on DioException catch (retryErr) {
          return handler.next(retryErr);
        }
      }
      return handler.next(e);
    }

    // Mulai proses refresh (mutex)
    _refreshCompleter = Completer<void>();
    try {
      final refreshToken = await LocalStorage.getRefreshToken();
      if (refreshToken == null) {
        _completeRefresh();
        await _clearAuthAndNotify();
        return handler.next(e);
      }

      final refreshResponse = await refreshDio.post(
        '/auth/refresh-token',
        data: {'refreshToken': refreshToken},
      );

      final newAccessToken = refreshResponse.data['accessToken'] as String?;
      final newRefreshToken = refreshResponse.data['refreshToken'] as String?;

      if (newAccessToken == null) {
        _completeRefresh();
        await _clearAuthAndNotify();
        return handler.next(e);
      }

      // Simpan token baru
      await LocalStorage.saveAccessToken(newAccessToken);
      if (newRefreshToken != null) {
        await LocalStorage.saveRefreshToken(newRefreshToken);
      }

      _completeRefresh();

      // Retry request awal dengan token baru
      final retryOptions = e.requestOptions.copyWith();
      retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';
      final retryResponse = await refreshDio.fetch(retryOptions);
      return handler.resolve(retryResponse);
    } on DioException catch (refreshError) {
      _completeRefresh();
      // Hanya beri tahu sesi berakhir bila SERVER menolak (401/403).
      // Error koneksi/timeout → pertahankan sesi (jaringan bisa pulih).
      final code = refreshError.response?.statusCode;
      if (code == 401 || code == 403) {
        await _clearAuthAndNotify();
      }
      return handler.next(refreshError);
    } catch (_) {
      _completeRefresh();
      // Non-Dio exception (e.g. TypeError, FormatException) — jangan force logout,
      // biarkan request gagal natural. Sesi bisa pulih di request berikutnya.
      return handler.next(e);
    }
  }

  static void _completeRefresh() {
    if (_refreshCompleter != null && !_refreshCompleter!.isCompleted) {
      _refreshCompleter!.complete();
    }
    _refreshCompleter = null;
  }
}