import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../data/api/api_service.dart';
import '../data/local/local_storage.dart';

class GuruPiketProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoading = true;
  int? _myTeacherId;
  List<dynamic> _todaySchedules = [];
  String _currentDay = '';
  int? _claimingId;
  String? _error;

  bool get isLoading => _isLoading;
  int? get myTeacherId => _myTeacherId;
  List<dynamic> get todaySchedules => _todaySchedules;
  String get currentDay => _currentDay;
  int? get claimingId => _claimingId;
  String? get error => _error;

  static const List<String> _dayNames = [
    '', 'SENIN', 'SELASA', 'RABU', 'KAMIS', 'JUMAT', 'SABTU', 'AHAD',
  ];

  int? _toInt(dynamic value) => int.tryParse('${value ?? ''}');

  Future<void> fetchAllSchedules() async {
    _isLoading = true;
    _error = null;
    _currentDay = _dayNames[DateTime.now().weekday];
    notifyListeners();

    try {
      final user = await LocalStorage.getUser();
      _myTeacherId = _toInt(user?['id']);

      final tahunResponse = await _api.dio.get('/academic-years/active');
      final int tahunId = _toInt(tahunResponse.data?['data']?['id']) ?? 1;

      final response = await _api.dio.get('/schedulesAll/$tahunId');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final allSchedules = response.data['data'] ?? [];
        _todaySchedules = allSchedules.where((s) {
          final day = (s['day_of_week'] ?? '').toString().toUpperCase();
          if (day != _currentDay) return false;
          final mainTeacherId = _toInt(s['teacher_id']);
          return mainTeacherId != _myTeacherId;
        }).toList();
      }
    } on DioException catch (e) {
      _error = 'Gagal memuat jadwal piket: ${e.message}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> claimPiket(dynamic schedule) async {
    final scheduleId = _toInt(schedule['schedule_id']) ?? _toInt(schedule['id']);
    if (scheduleId == null) return false;

    _claimingId = scheduleId;
    _error = null;
    notifyListeners();

    try {
      await _api.dio.post('/schedules/$scheduleId/claim-piket');
      _claimingId = null;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _error = e.response?.data?['message']?.toString() ??
          'Gagal mengambil alih piket: ${e.message}';
      _claimingId = null;
      notifyListeners();
      return false;
    }
  }

  int? toInt(dynamic value) => _toInt(value);
}
