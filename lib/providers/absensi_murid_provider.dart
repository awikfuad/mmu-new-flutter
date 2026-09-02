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
      _records = response.data['data'] as List? ?? [];
    } catch (e) {
      _error = 'Gagal memuat absensi: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
      _records = response.data['data'] as List? ?? [];
    } catch (e) {
      _error = 'Gagal memuat kegiatan: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
