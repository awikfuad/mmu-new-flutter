import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../data/api/api_service.dart';
import '../utils/geofence_helper.dart';

class PresensiKegiatanProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoading = true;
  bool _isSaving = false;
  List<dynamic> _students = [];
  List<dynamic> _filteredStudents = [];
  final Map<String, String> _attendanceStatus = {};
  String _searchQuery = '';
  String? _error;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  List<dynamic> get filteredStudents => _filteredStudents;
  String? get error => _error;

  final String _todayDate = DateTime.now().toIso8601String().substring(0, 10);
  String get todayDate => _todayDate;

  Future<void> fetchStudentsAndAttendance(int activityId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.dio.get('/kegiatan/report/export/$activityId');

      if (response.statusCode == 200 && response.data['success'] == true) {
        List<dynamic> rawData = (response.data['raw_data'] ?? []) as List;
        if (rawData.isEmpty) {
          final grouped = response.data['data'];
          if (grouped is Map) {
            for (final value in grouped.values) {
              if (value is List) rawData.addAll(value);
            }
          }
        }

        _students = rawData;
        _filteredStudents = _students;
        _attendanceStatus.clear();
        for (var student in _students) {
          final status = (student['status'] ?? 'ALPA').toString().toLowerCase();
          _attendanceStatus[student['nim']?.toString() ?? ''] = status;
        }
      }
    } on DioException catch (e) {
      _error = 'Gagal mengambil data santri: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void filterSearch(String query) {
    _searchQuery = query;
    _filteredStudents = _students
        .where((student) =>
            student['student_name'].toString().toLowerCase().contains(query.toLowerCase()) ||
            student['class_name'].toString().toLowerCase().contains(query.toLowerCase()))
        .toList();
    notifyListeners();
  }

  void setStatus(String nim, String status) {
    _attendanceStatus[nim] = status;
    notifyListeners();
  }

  String getStatus(String nim) => _attendanceStatus[nim] ?? 'hadir';

  Future<void> submitAttendance(int activityId) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    // Capture GPS location once
    final GeoPosition? geo = await GeofenceHelper.getCurrentLocation();

    try {
      for (final student in _students) {
        final nim = student['nim']?.toString() ?? '';
        if (nim.isEmpty) continue;

        final payload = <String, dynamic>{
          'activity_id': activityId,
          'nim': nim,
          'status': (_attendanceStatus[nim] ?? 'hadir').toUpperCase(),
          'notes': 'Presensi via aplikasi guru',
        };
        if (geo != null) {
          payload.addAll(geo.toMap());
        }

        await _api.dio.post('/kegiatan/attendance', data: payload);
      }
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? e.message ?? e.toString();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
