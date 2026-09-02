import 'auth_user.dart';

class LoginResponse {
  final bool success;
  final String? message;
  final String? accessToken;
  final String? refreshToken;
  final AuthUser? user;

  const LoginResponse({
    required this.success,
    this.message,
    this.accessToken,
    this.refreshToken,
    this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> j) => LoginResponse(
        success: j['success'] == true,
        message: j['message']?.toString(),
        accessToken: j['accessToken']?.toString() ?? j['access_token']?.toString(),
        refreshToken: j['refreshToken']?.toString() ?? j['refresh_token']?.toString(),
        user: j['user'] is Map ? AuthUser.fromJson(Map<String, dynamic>.from(j['user'] as Map)) : null,
      );
}

class RefreshResponse {
  final bool success;
  final String? accessToken;
  final String? refreshToken;
  final String? message;
  const RefreshResponse({required this.success, this.accessToken, this.refreshToken, this.message});

  factory RefreshResponse.fromJson(Map<String, dynamic> j) => RefreshResponse(
        success: j['success'] == true,
        accessToken: j['accessToken']?.toString(),
        refreshToken: j['refreshToken']?.toString(),
        message: j['message']?.toString(),
      );
}
