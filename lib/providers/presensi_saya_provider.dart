import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../data/api/api_service.dart';
import '../data/local/local_storage.dart';

class PresensiSayaProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoading = true;
  bool _isAdmin = false;
  List<dynamic> _schedules = [];
  String _currentDay = '';
  String? _error;
  int _summaryGeneration = 0;

  bool get isLoading => _isLoading;
  bool get isAdmin => _isAdmin;
  List<dynamic> get schedules => _schedules;
  String get currentDay => _currentDay;
  String? get error => _error;
  final Map<int, Map<String, dynamic>> _summaries = {};
  Map<int, Map<String, dynamic>> get summaries => _summaries;

  static const List<String> _dayNames = [
    'AHAD', 'SENIN', 'SELASA', 'RABU', 'KAMIS', 'JUMAT', 'SABTU',
  ];

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    _currentDay = _dayNames[DateTime.now().weekday % 7];
    notifyListeners();

    try {
      final user = await LocalStorage.getUser();
      _isAdmin = (user?['role'] ?? '') == 'admin';

      // v3.9: admin → semua jadwal hari ini; guru → jadwal sendiri (utama + piket)
      final response = await _api.dio.get(
        _isAdmin ? '/schedules/today-all' : '/today',
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        _schedules = response.data['data'] ?? [];
        _fetchSummaries(++_summaryGeneration);
      }
    } on DioException catch (e) {
      _error =
          e.response?.data?['message']?.toString() ?? 'Gagal memuat jadwal: ${e.message}';
    } catch (e) {
      _error = 'Gagal memuat jadwal: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchSummaries(int gen) async {
    final today = DateTime.now();
    final todayStr =
        '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    for (final s in _schedules) {
      if (gen != _summaryGeneration) return;
      final cid = s['classroom_id'];
      final sess = (s['session_name'] ?? 'PAGI').toString();
      final sid = s['schedule_id'] ?? s['id'];
      if (cid == null || sid == null) continue;
      try {
        final res = await _api.dio.get('/attendances/class/$cid', queryParameters: {
          'session_name': sess,
          'date': todayStr,
        });
        if (gen != _summaryGeneration) return;
        final sum = res.data?['summary'];
        if (sum is Map) {
          _summaries[int.tryParse(sid.toString()) ?? sid.hashCode] = Map<String, dynamic>.from(sum);
        }
      } catch (_) {}
    }
    if (gen == _summaryGeneration) notifyListeners();
  }
}
