import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../data/api/api_service.dart';

class AbsensiKbmMuridProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoading = true;
  List<dynamic> _records = [];
  String? _error;

  bool get isLoading => _isLoading;
  List<dynamic> get records => _records;
  String? get error => _error;
  int get hadirCount => _records.where((r) => (r['status'] ?? '').toString().toUpperCase() == 'HADIR').length;
  int get totalCount => _records.length;

  Future<void> load({int? academicYearId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final params = <String, dynamic>{};
      if (academicYearId != null) params['academic_year_id'] = academicYearId;
      final response = await _api.dio.get('/students/me/kbm', queryParameters: params);
      
      final data = response.data;
      if (data is Map && data['data'] is List) {
        _records = data['data'] as List;
      } else {
        _records = [];
      }
    } catch (e) {
      _error = _extractError(e, 'Gagal memuat absensi KBM');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _extractError(Object e, String fallback) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
      return e.message ?? fallback;
    }
    return '$fallback: $e';
  }
}

class AbsensiKegiatanMuridProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoading = true;
  List<dynamic> _records = [];
  String? _error;

  bool get isLoading => _isLoading;
  List<dynamic> get records => _records;
  String? get error => _error;
  int get hadirCount => _records.where((r) => (r['status'] ?? '').toString().toUpperCase() == 'HADIR').length;
  int get totalCount => _records.length;

  Future<void> load({int? academicYearId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final params = <String, dynamic>{};
      if (academicYearId != null) params['academic_year_id'] = academicYearId;
      final response = await _api.dio.get('/students/me/kegiatan', queryParameters: params);
      
      final data = response.data;
      if (data is Map && data['data'] is List) {
        _records = data['data'] as List;
      } else {
        _records = [];
      }
    } catch (e) {
      _error = _extractError(e, 'Gagal memuat kegiatan');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _extractError(Object e, String fallback) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
      return e.message ?? fallback;
    }
    return '$fallback: $e';
  }
}