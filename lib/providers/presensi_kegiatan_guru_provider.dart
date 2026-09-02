import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../data/api/api_service.dart';
import '../data/local/local_storage.dart';
import '../utils/geofence_helper.dart';

class PresensiKegiatanGuruProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoading = true;
  bool _isSaving = false;
  List<dynamic> _teachers = [];
  int? _currentTeacherId;
  bool _isTeacher = true;
  final Map<int, String> _attendanceStatus = {};
  String? _error;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  List<dynamic> get teachers => _teachers;
  int? get currentTeacherId => _currentTeacherId;
  bool get isTeacher => _isTeacher;
  String? get error => _error;

  Future<void> init() async {
    final user = await LocalStorage.getUser();
    _currentTeacherId = user?['id'];
    _isTeacher = (user?['role'] ?? 'teacher') == 'teacher';
    notifyListeners();
  }

  Future<void> fetchTeachersAndAttendance(int activityId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.dio.get('/kegiatan/report/teacher/$activityId');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as List? ?? [];
        _teachers = data;
        _attendanceStatus.clear();
        for (final teacher in data) {
          if (teacher != null && teacher['teacher_id'] != null) {
            final status = (teacher['status'] ?? 'ALPA').toString().toLowerCase();
            _attendanceStatus[teacher['teacher_id']] = status;
          }
        }
      }
    } on DioException catch (e) {
      _error = e.response?.data?['message'] ?? e.message ?? e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setStatus(int teacherId, String status) {
    _attendanceStatus[teacherId] = status;
    notifyListeners();
  }

  String getStatus(int teacherId) => _attendanceStatus[teacherId] ?? 'hadir';

  Future<void> submitAttendance(int activityId) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final int teacherId = _currentTeacherId ?? 0;

      // Capture GPS location
      final GeoPosition? geo = await GeofenceHelper.getCurrentLocation();

      final payload = <String, dynamic>{
        'kegiatan_id': activityId,
        'teacher_id': teacherId,
        'status': (_attendanceStatus[teacherId] ?? 'hadir').toUpperCase(),
        'notes': 'Absen Mandiri Guru',
      };
      if (geo != null) {
        payload.addAll(geo.toMap());
      }

      await _api.dio.post('/kegiatan/teacher-attendance', data: payload);
    } on DioException catch (e) {
      _error = e.response?.data?['message'] ?? e.message ?? e.toString();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
