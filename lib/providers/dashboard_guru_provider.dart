import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../data/api/api_service.dart';
import '../data/local/local_storage.dart';

class DashboardGuruProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoading = true;
  bool _isAdmin = false;
  String _teacherName = '';
  String _academicYearInfo = '';
  List<dynamic> _schedules = [];
  String _currentDay = '';
  String? _error;

  bool get isLoading => _isLoading;
  bool get isAdmin => _isAdmin;
  String get teacherName => _teacherName;
  String get academicYearInfo => _academicYearInfo;
  List<dynamic> get schedules => _schedules;
  String get currentDay => _currentDay;
  String? get error => _error;
  final Map<int, Map<String, dynamic>> _summaries = {};
  Map<int, Map<String, dynamic>> get summaries => _summaries;

  static const List<String> _dayNames = [
    '', 'SENIN', 'SELASA', 'RABU', 'KAMIS', 'JUMAT', 'SABTU', 'AHAD',
  ];

  Future<void> fetchDashboardData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.dio.get('/today');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final user = await LocalStorage.getUser();
        _teacherName = user?['name'] ?? 'Guru';
        _isAdmin = user?['role'] == 'admin';
        _academicYearInfo = response.data['date'] ?? '-';
        _currentDay = response.data['message'] ?? 'Hari Ini';
        _schedules = response.data['data'] ?? [];
        _fetchSummaries();
      }
    } on DioException catch (e) {
      _error = e.response?.data?['message'] ?? 'Gagal memuat jadwal: ${e.message}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchSummaries() async {
    final today = DateTime.now();
    final todayStr =
        '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    for (final s in _schedules) {
      final cid = s['classroom_id'];
      final sess = (s['session_name'] ?? 'PAGI').toString();
      final sid = s['schedule_id'] ?? s['id'];
      if (cid == null || sid == null) continue;
      try {
        final res = await _api.dio.get('/attendances/class/$cid', queryParameters: {'session_name': sess, 'date': todayStr});
        final sum = res.data?['summary'];
        if (sum is Map) _summaries[int.tryParse(sid.toString()) ?? sid.hashCode] = Map<String, dynamic>.from(sum);
      } catch (_) {}
    }
    notifyListeners();
  }
}
