import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../data/api/api_service.dart';
import '../data/local/local_storage.dart';

/// Provider Jadwal Sepekan Guru — guru melihat jadwal sendiri (utama + piket/badal),
/// admin dapat memilih guru tertentu untuk melihat jadwal sepekan miliknya.
class JadwalMingguanProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoading = true;
  bool _isAdmin = false;
  List<dynamic> _schedules = [];
  List<dynamic> _teachers = [];
  int? _selectedTeacherId;
  String? _error;

  bool get isLoading => _isLoading;
  bool get isAdmin => _isAdmin;
  List<dynamic> get schedules => _schedules;
  List<dynamic> get teachers => _teachers;
  int? get selectedTeacherId => _selectedTeacherId;
  String? get error => _error;

  static const List<String> dayOrder = [
    'SENIN', 'SELASA', 'RABU', 'KAMIS', 'JUMAT', 'SABTU', 'AHAD',
  ];

  Map<String, List<dynamic>> get groupedByDay {
    final map = <String, List<dynamic>>{};
    for (final s in _schedules) {
      final day = (s['day_of_week'] ?? '').toString().toUpperCase();
      map.putIfAbsent(day, () => []).add(s);
    }
    return map;
  }

  /// Label guru terpilih (untuk subtitle saat admin).
  String get selectedTeacherName {
    if (!_isAdmin) return '';
    final id = _selectedTeacherId;
    for (final t in _teachers) {
      if (int.tryParse('${t['id']}') == id) return (t['name'] ?? '').toString();
    }
    return '';
  }

  Future<void> load({int? teacherId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await LocalStorage.getUser();
      _isAdmin = (user?['role'] ?? '') == 'admin';

      if (_isAdmin) {
        if (_teachers.isEmpty) {
          final tRes = await _api.dio.get('/teachers');
          if (tRes.data?['success'] == true) {
            _teachers = tRes.data?['data'] ?? [];
          }
        }
        _selectedTeacherId = teacherId ?? _selectedTeacherId;
        if (_selectedTeacherId == null && _teachers.isNotEmpty) {
          _selectedTeacherId = int.tryParse('${_teachers.first['id']}');
        }

        final params = <String, dynamic>{};
        if (_selectedTeacherId != null) params['teacher_id'] = _selectedTeacherId;
        final res = await _api.dio.get('/schedules/week-all', queryParameters: params);
        if (res.data?['success'] == true) {
          _schedules = res.data?['data'] ?? [];
        }
      } else {
        final res = await _api.dio.get('/my-week');
        if (res.data?['success'] == true) {
          _schedules = res.data?['data'] ?? [];
        }
      }
    } on DioException catch (e) {
      _error = e.response?.data?['message']?.toString() ??
          'Gagal memuat jadwal sepekan: ${e.message}';
    } catch (e) {
      _error = 'Gagal memuat jadwal sepekan: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectTeacher(int? teacherId) async {
    if (teacherId == null || teacherId == _selectedTeacherId) return;
    _selectedTeacherId = teacherId;
    await load(teacherId: teacherId);
  }
}
