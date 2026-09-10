import 'package:flutter/foundation.dart';
import '../data/api/api_service.dart';

class InputNilaiProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoading = true;
  bool _isSaving = false;
  List<dynamic> _students = [];
  final Map<String, int> _studentIdByNim = {};
  final Map<String, double> _nilai = {};
  final Map<String, String> _keterangan = {};
  final Map<String, double> _previousNilai = {};
  String? _error;
  String? _successMessage;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  List<dynamic> get students => _students;
  Map<String, double> get nilai => _nilai;
  Map<String, String> get keterangan => _keterangan;
  Map<String, double> get previousNilai => _previousNilai;
  String? get error => _error;
  String? get successMessage => _successMessage;

  int get totalCount => _students.length;
  int get sudahCount =>
      _students.where((s) {
        final nim = s['nim']?.toString() ?? '';
        return _previousNilai.containsKey(nim);
      }).length;

  /// Fetch roster + prefill existing nilai for a classroom + subject on a date
  Future<void> fetchStudents({
    required int classroomId,
    required int subjectId,
    required String tanggal,
    int? rombelId,
    int? academicYearId,
  }) async {
    _isLoading = true;
    _error = null;
    _successMessage = null;
    notifyListeners();

    try {
      // 1. Fetch roster
      final rosterRes = await _api.dio.get('/muridKelas');
      final allRoster = (rosterRes.data?['data'] ?? []) as List;

      // 2. Fetch students (NIM → student_id map)
      final studentsRes = await _api.dio.get('/students');
      final allStudents = (studentsRes.data?['data'] ?? []) as List;
      final Map<String, int> nimToStudentId = {};
      for (final s in allStudents) {
        if (s != null && s['nim'] != null) {
          nimToStudentId[s['nim'].toString()] = s['id'];
        }
      }

      // 3. Filter by classroom_id + rombel_id + status
      final roster = allRoster
          .where((m) =>
              m != null &&
              m['classroom_id'] != null &&
              int.tryParse(m['classroom_id'].toString()) == classroomId &&
              (rombelId == null ||
                  (m['rombel_id'] != null &&
                      int.tryParse(m['rombel_id'].toString()) == rombelId)) &&
              (m['status'] ?? 1) == 1)
          .toList();

      _students = roster;
      _studentIdByNim.clear();
      _nilai.clear();
      _keterangan.clear();
      _previousNilai.clear();

      for (final m in roster) {
        final nim = m['nim']?.toString() ?? '';
        if (nim.isEmpty) continue;
        if (nimToStudentId.containsKey(nim)) {
          _studentIdByNim[nim] = nimToStudentId[nim]!;
        }
        _nilai[nim] = 0;
        _keterangan[nim] = '';

        // JANGAN masukkan ke _previousNilai di sini — gunakan containsKey
        // untuk menandai murid yang BELUM punya nilai record. Simpan hanya
        // saat prefill menemukan existing nilai (di bawah).
      }

      // 4. Prefill existing nilai from GET /nilai-harian?subject_id=&tanggal=&classroom_id=
      try {
        final nilaiRes = await _api.dio.get('/nilai-harian', queryParameters: {
          'subject_id': subjectId,
          'tanggal': tanggal,
          'classroom_id': classroomId,
        });
        final existing = (nilaiRes.data?['data'] ?? []) as List;
        for (final r in existing) {
          final nim = r['nim']?.toString() ?? '';
          final val = r['nilai'];
          if (nim.isNotEmpty && val != null) {
            final numVal = (val is num) ? val.toDouble() : double.tryParse(val.toString());
            if (numVal != null) {
              _nilai[nim] = numVal;
              _previousNilai[nim] = numVal;
              if (r['keterangan'] != null) {
                _keterangan[nim] = r['keterangan'].toString();
              }
            }
          }
        }
      } catch (_) {}
    } catch (e) {
      _error = 'Gagal mengambil data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setNilai(String nim, double value) {
    _nilai[nim] = value.clamp(0, 100);
    _successMessage = null;
    notifyListeners();
  }

  void setKeterangan(String nim, String value) {
    _keterangan[nim] = value;
    notifyListeners();
  }

  /// Count how many students have actually changed
  int get changedCount =>
      _students.where((s) {
        final nim = s['nim']?.toString() ?? '';
        final cur = _nilai[nim] ?? 0;
        if (!_previousNilai.containsKey(nim)) return cur > 0;
        return cur != _previousNilai[nim];
      }).length;

  /// Save all changed nilai in bulk
  Future<int> submitNilai({
    required int scheduleId,
    required int subjectId,
    required String tanggal,
    required int classroomId,
    int? jenjangId,
    int? rombelId,
    int? academicYearId,
  }) async {
    _isSaving = true;
    _error = null;
    _successMessage = null;
    notifyListeners();

    int saved = 0;
    try {
      final items = <Map<String, dynamic>>[];
      for (final student in _students) {
        final nim = student['nim']?.toString() ?? '';
        final studentId = _studentIdByNim[nim];
        if (studentId == null) continue;

        final cur = _nilai[nim] ?? 0;
        final isChanged = !_previousNilai.containsKey(nim)
            ? cur > 0
            : cur != _previousNilai[nim];
        if (!isChanged) continue;

        items.add({
          'murid_id': studentId,
          'nim': nim,
          'sumber': student['sumber'] ?? 'madrasah',
          'nilai': cur,
          'keterangan': _keterangan[nim]?.isNotEmpty == true ? _keterangan[nim] : null,
        });
      }

      if (items.isEmpty) {
        _successMessage = 'Tidak ada perubahan nilai.';
      } else {
        await _api.dio.post('/nilai-harian/bulk', data: {
          'subject_id': subjectId,
          'tanggal': tanggal,
          'classroom_id': classroomId,
          'academic_year_id': ?academicYearId,
          'jenjang_id': jenjangId,
          'items': items,
        });
        saved = items.length;
        _successMessage = '$saved nilai berhasil disimpan.';
        // Update previous snapshot
        for (final item in items) {
          final nim = item['nim']?.toString() ?? '';
          _previousNilai[nim] = item['nilai'];
        }
      }
    } catch (e) {
      _error = 'Gagal menyimpan nilai: $e';
    } finally {
      _isSaving = false;
      notifyListeners();
    }
    return saved;
  }
}
