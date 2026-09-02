import 'package:flutter/foundation.dart';
import '../data/api/api_service.dart';

class StudentJadwalProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoading = true;
  List<dynamic> _records = [];
  String? _error;

  bool get isLoading => _isLoading;
  List<dynamic> get records => _records;
  String? get error => _error;

  /// Grouped by day_of_week
  Map<String, List<dynamic>> get groupedByDay {
    final map = <String, List<dynamic>>{};
    for (final r in _records) {
      final day = (r['day_of_week'] ?? '').toString();
      map.putIfAbsent(day, () => []).add(r);
    }
    return map;
  }

  List<String> get dayOrder => [
        'SENIN', 'SELASA', 'RABU', 'KAMIS', 'JUMAT', 'SABTU', 'AHAD'
      ];

  Future<void> load({int? academicYearId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final params = <String, dynamic>{};
      if (academicYearId != null) params['academic_year_id'] = academicYearId;
      final response = await _api.dio.get('/students/me/jadwal', queryParameters: params);
      _records = response.data['data'] as List? ?? [];
    } catch (e) {
      _error = 'Gagal memuat jadwal: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
