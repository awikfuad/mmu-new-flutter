import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../data/api/api_service.dart';

class StudentDashboardProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoading = true;
  Map<String, dynamic>? _profile;
  num _balance = 0;
  String? _error;

  bool get isLoading => _isLoading;
  Map<String, dynamic>? get profile => _profile;
  num get balance => _balance;
  String? get error => _error;
  String get lembaga => _profile?['account']?['lembaga'] ?? 'ALL';
  String get className => _profile?['account']?['class_name'] ?? '-';
  String get namaRombel => _profile?['account']?['nama_rombel'] ?? '-';
  String get name => _profile?['name'] ?? 'Santri';
  String get nim => _profile?['nim'] ?? '-';
  String? get tanggalLahir => _profile?['tanggal_lahir'];
  String? get foto => _profile?['foto']?.toString() ?? _profile?['account']?['foto']?.toString();

  Future<void> fetchDashboardData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _api.dio.get('/students/me'),
        _api.dio.get('/students/me/savings'),
      ]);

      final profile = results[0].data['data'];
      final savings = results[1].data['data'];

      _profile = profile is Map ? Map<String, dynamic>.from(profile) : null;
      _balance = savings is Map ? (savings['balance'] as num? ?? 0) : 0;
    } on DioException catch (e) {
      final dynamic body = e.response?.data;
      _error = (body is Map && body['message'] != null)
          ? body['message'].toString()
          : (e.message ?? 'Koneksi gagal');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
