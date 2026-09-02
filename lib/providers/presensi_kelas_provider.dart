import 'package:flutter/foundation.dart';
import '../data/api/api_service.dart';
import '../utils/geofence_helper.dart';

class PresensiKelasProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoading = true;
  bool _isSaving = false;
  List<dynamic> _students = [];
  final Map<String, int> _studentIdByNim = {};
  final Map<String, String> _attendanceStatus = {};
  String? _error;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  List<dynamic> get students => _students;
  Map<String, String> get attendanceStatus => _attendanceStatus;
  Map<String, String> get previousStatusMap => _previousStatus;
  Map<String, bool> get alreadyAbsenMap => _alreadyAbsen;
  String? get error => _error;

  final Map<String, String> _previousStatus = {};
  final Map<String, bool> _alreadyAbsen = {};

  int get hadirCount => _attendanceStatus.values.where((v) => v.toUpperCase() == 'HADIR').length;
  int get sakitCount => _attendanceStatus.values.where((v) => v.toUpperCase() == 'SAKIT').length;
  int get izinCount => _attendanceStatus.values.where((v) => v.toUpperCase() == 'IZIN').length;
  int get alfaCount => _attendanceStatus.values.where((v) => v.toUpperCase() == 'ALFA' || v.toUpperCase() == 'ALPA').length;
  int get sudahCount => _alreadyAbsen.values.where((v) => v).length;
  int get belumCount => _students.length - sudahCount;
  int get totalCount => _students.length;

  int get submittedCount => _students.where((s) {
    final nim = s['nim']?.toString() ?? '';
    final cur = (_attendanceStatus[nim] ?? 'hadir').toUpperCase();
    final prev = _previousStatus[nim];
    if (prev != null) return cur != prev.toUpperCase();
    return cur != 'HADIR';
  }).length;

  // Summary untuk header
  Map<String, int> get summary => {
        'hadir': hadirCount,
        'sakit': sakitCount,
        'izin': izinCount,
        'alpa': alfaCount,
        'sudah': sudahCount,
        'belum': belumCount,
        'total': totalCount,
      };

  Future<void> fetchStudents(int classroomId, {String sessionName = 'PAGI'}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final rosterResponse = await _api.dio.get('/muridKelas');
      final allRoster = (rosterResponse.data?['data'] ?? []) as List;

      final studentsResponse = await _api.dio.get('/students');
      final allStudents = (studentsResponse.data?['data'] ?? []) as List;
      final Map<String, int> nimToStudentId = {};
      for (final s in allStudents) {
        if (s != null && s['nim'] != null) {
          nimToStudentId[s['nim'].toString()] = s['id'];
        }
      }

      final roster = allRoster
          .where((m) =>
              m != null &&
              m['classroom_id'] != null &&
              int.tryParse(m['classroom_id'].toString()) == classroomId &&
              (m['status'] ?? 1) == 1)
          .toList();

      _students = roster;
      _studentIdByNim.clear();
      _attendanceStatus.clear();
      _previousStatus.clear();
      _alreadyAbsen.clear();
      for (final m in roster) {
        final nim = m['nim']?.toString() ?? '';
        if (nim.isEmpty) continue;
        if (nimToStudentId.containsKey(nim)) {
          _studentIdByNim[nim] = nimToStudentId[nim]!;
        }
        _attendanceStatus[nim] = 'hadir';
        _previousStatus[nim] = '';
        _alreadyAbsen[nim] = false;
      }
      // Prefill sudah diabsen: GET /attendances/class/:classroom_id?session_name=&date=today
      try {
        final today = DateTime.now();
        final todayStr =
            '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
        final res = await _api.dio.get('/attendances/class/$classroomId', queryParameters: {
          'session_name': sessionName,
          'date': todayStr,
        });
        final rows = (res.data?['data'] ?? []) as List;
        final Map<String, String> byStudentId = {};
        final Map<String, String> byNim = {};
        for (final r in rows) {
          final st = (r['status'] ?? '').toString().toUpperCase();
          if (st.isEmpty) continue;
          final norm = st == 'ALPA' ? 'ALFA' : st;
          if (r['student_id'] != null) byStudentId[r['student_id'].toString()] = norm;
          if (r['nim'] != null) byNim[r['nim'].toString()] = norm;
        }
        for (final m in roster) {
          final nim = m['nim']?.toString() ?? '';
          final sid = _studentIdByNim[nim]?.toString();
          String? fetched;
          if (sid != null && byStudentId.containsKey(sid)) fetched = byStudentId[sid];
          else if (byNim.containsKey(nim)) fetched = byNim[nim];
          if (fetched != null) {
            _attendanceStatus[nim] = fetched.toLowerCase();
            _previousStatus[nim] = fetched;
            _alreadyAbsen[nim] = true;
          }
        }
      } catch (_) {
        // prefill gagal tidak fatal — tetap default hadir
      }
    } catch (e) {
      _error = 'Gagal mengambil data murid: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setStatus(String nim, String status) {
    _attendanceStatus[nim] = status;
    notifyListeners();
  }

  Future<List<String>> submitAttendance({
    required int scheduleId,
    required String sessionName,
  }) async {
    _isSaving = true;
    notifyListeners();

    final List<String> skippedNames = [];

    // Capture GPS location once for all submissions
    final GeoPosition? geo = await GeofenceHelper.getCurrentLocation();

    try {
      for (final student in _students) {
        final nim = student['nim']?.toString() ?? '';
        final studentId = _studentIdByNim[nim];

        if (studentId == null) {
          skippedNames.add(student['name'] ?? nim);
          continue;
        }

        // Kirim hanya yang berubah (termasuk HADIR koreksi SAKIT->HADIR)
        final status = (_attendanceStatus[nim] ?? 'hadir').toUpperCase();
        final prev = _previousStatus[nim];
        final isChanged = prev != null && prev.isNotEmpty ? status != prev.toUpperCase() : status != 'HADIR';
        if (!isChanged) continue;

        final payload = <String, dynamic>{
          'student_id': studentId,
          'session_name': sessionName,
          'status': status,
          'notes': null,
          'schedule_id': scheduleId,
        };
        if (geo != null) {
          payload.addAll(geo.toMap());
        }

        await _api.dio.post('/attendances', data: payload);
      }
    } catch (e) {
      _error = 'Gagal menyimpan presensi: $e';
    } finally {
      _isSaving = false;
      notifyListeners();
    }

    return skippedNames;
  }
}
