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
  String? _error;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  List<dynamic> get filteredStudents => _filteredStudents;
  String? get error => _error;

  String get todayDate {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> fetchStudentsAndAttendance(int activityId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.dio.get('/kegiatan/report/export/$activityId');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final raw = response.data['raw_data'];
        List<dynamic> rawData = (raw is List) ? raw : [];
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
          final status = (student['status'] ?? 'HADIR').toString().toLowerCase();
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
    _filteredStudents = _students
        .where((student) =>
            (student?['student_name'] ?? '').toString().toLowerCase().contains(query.toLowerCase()) ||
            (student?['class_name'] ?? '').toString().toLowerCase().contains(query.toLowerCase()))
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

    try {
      // Capture GPS location once
      GeoPosition? geo;
      try {
        geo = await GeofenceHelper.getCurrentLocation();
      } catch (_) {
        // GPS gagal tidak fatal — submit tanpa koordinat
      }

      final List<String> failedNims = [];

      // Kumpulkan semua payload
      final List<Map<String, dynamic>> payloads = [];
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
        payloads.add(payload);
      }

      // Submit semua secara paralel, gagal per-murid tidak membatalkan lainnya
      await Future.wait(
        payloads.map((p) => _api.dio.post('/kegiatan/attendance', data: p).catchError((e) {
          failedNims.add(p['nim']?.toString() ?? '?');
          return e;
        })),
        eagerError: false,
      );

      if (failedNims.isNotEmpty) {
        _error = 'Gagal menyimpan: ${failedNims.join(", ")} santri';
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg = (data is Map) ? data['message']?.toString() : null;
      _error = msg ?? e.message ?? 'Gagal menyimpan presensi';
    } catch (e) {
      _error = 'Gagal menyimpan presensi: $e';
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
