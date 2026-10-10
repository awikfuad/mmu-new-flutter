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
          if (teacher != null) {
            final tid = int.tryParse('${teacher['teacher_id']}');
            if (tid == null) continue;
            final status = (teacher['status'] ?? 'HADIR').toString().toLowerCase();
            _attendanceStatus[tid] = status;
          }
        }
      }
    } on DioException catch (e) {
      _error = e.response?.data?['message'] ?? e.message ?? e.toString();
    } catch (e) {
      _error = e.toString();
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

 // Pada presensi_kegiatan_guru_provider.dart

Future<void> submitAttendance(int activityId) async {
  _isSaving = true;
  _error = null;
  notifyListeners(); // Memunculkan loading indicator di UI

  try {
    // 2. Kirim request ke Backend dihitung status dulu
    final teacherId = currentTeacherId;
    if (teacherId == null) {
      throw 'Data guru tidak ditemukan. Silakan login ulang.';
    }
    final status = getStatus(teacherId).toUpperCase();

    // 1. Lokasi GPS hanya wajib utk status HADIR (geofence). IZIN/SAKIT/ALPA
    //    menandakan guru tidak berada di lokasi → tidak perlu meminta GPS.
    GeoPosition? geo;
    if (status == 'HADIR') {
      try {
        geo = await GeofenceHelper.getCurrentLocation()
            .timeout(const Duration(seconds: 12));
      } catch (locErr) {
        debugPrint('Gagal mengambil lokasi GPS: $locErr');
      }
    }

    final Map<String, dynamic> requestData = {
  'kegiatan_id': activityId,
  'teacher_id': teacherId,
  'status': status,
  'latitude': geo?.latitude,
  'longitude': geo?.longitude,
  'accuracy': geo?.accuracy,
};

// Log payload yang dikirim ke console
debugPrint('=== [POST /kegiatan/teacher-attendance] Payload ===');
debugPrint(requestData.toString());

final response = await _api.dio.post(
  '/kegiatan/teacher-attendance',
  data: requestData,
);

    final code = response.statusCode ?? 0;
    final bool ok = code >= 200 &&
        code < 300 &&
        (response.data is Map ? response.data['success'] != false : true);
    if (!ok) {
      _error = (response.data is Map ? response.data['message'] : null) ??
          'Gagal menyimpan presensi.';
    }
  } on DioException catch (e) {
    _error = e.response?.data is Map
        ? (e.response?.data['message'] ?? e.message ?? 'Terjadi kesalahan pada server.')
        : (e.message ?? 'Terjadi kesalahan pada server.');
  } catch (e) {
    _error = e.toString();
  } finally {
    _isSaving = false;
    notifyListeners();
  }
}
}