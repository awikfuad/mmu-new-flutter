import 'package:flutter/foundation.dart';
import '../data/api/api_service.dart';

class StudentPrestasiProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoading = true;
  List<dynamic> _records = [];
  String? _error;

  bool get isLoading => _isLoading;
  List<dynamic> get records => _records;
  String? get error => _error;

  int get prestasiCount =>
      _records.where((r) => (r['tipe'] ?? '').toString().toUpperCase() == 'PRESTASI').length;
  int get pelanggaranCount =>
      _records.where((r) => (r['tipe'] ?? '').toString().toUpperCase() == 'PELANGGARAN').length;
  int get totalPoin =>
      _records.fold<int>(0, (sum, r) => sum + (int.tryParse('${r['poin'] ?? 0}') ?? 0));

  Future<void> load({int? academicYearId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final params = <String, dynamic>{};
      if (academicYearId != null) params['academic_year_id'] = academicYearId;
      final response = await _api.dio.get('/students/me/prestasi-pelanggaran', queryParameters: params);
      _records = response.data['data'] as List? ?? [];
    } catch (e) {
      _error = 'Gagal memuat prestasi: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
