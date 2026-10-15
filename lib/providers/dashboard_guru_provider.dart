import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../data/api/api_service.dart';
import '../data/local/local_storage.dart';

class DashboardGuruProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoading = true;
  bool _isAdmin = false;
  bool _isPimpinan = false;
  String _teacherName = '';
  String _academicYearInfo = '';
  List<dynamic> _schedules = [];
  String _currentDay = '';
  String? _error;

  bool get isLoading => _isLoading;
  bool get isAdmin => _isAdmin;
  bool get isPimpinan => _isPimpinan;
  String get teacherName => _teacherName;
  String get academicYearInfo => _academicYearInfo;
  List<dynamic> get schedules => _schedules;
  String get currentDay => _currentDay;
  String? get error => _error;
  final Map<int, Map<String, dynamic>> _summaries = {};
  Map<int, Map<String, dynamic>> get summaries => _summaries;

  // Nama hari Indonesia (index = DateTime.weekday % 7; 0 = Ahad/Minggu).
  static const List<String> _dayNames = [
    'AHAD', 'SENIN', 'SELASA', 'RABU', 'KAMIS', 'JUMAT', 'SABTU',
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
        _isPimpinan = user?['is_pimpinan'] == true;
        _academicYearInfo = response.data['date'] ?? '-';
        _currentDay = response.data['message'] ?? 'Hari Ini';
        final kbm = List<dynamic>.from(response.data['data'] ?? []);

        // Guru (bukan admin) juga melihat tugas piket hari ini dari roster
        // piket guru mingguan (tabel piket_guru → GET /piket-guru). Item piket
        // ditandai `_kind = 'PIKET_GURU'` agar tampil berbeda & tap-nya membuka
        // daftar semua kelas hari ini untuk mengambil alih kelas guru berhalangan.
        final piket = await _fetchPiketHariIni(user?['id']);

        final merged = [...kbm, ...piket];
        merged.sort(
          (a, b) => (a['start_time'] ?? '')
              .toString()
              .compareTo((b['start_time'] ?? '').toString()),
        );
        _schedules = merged;
        _fetchSummaries();
      }
    } on DioException catch (e) {
      _error =
          e.response?.data?['message'] ?? 'Gagal memuat jadwal: ${e.message}';
    } catch (e) {
      _error = 'Gagal memuat jadwal: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Ambil tugas piket guru hari ini (roster mingguan) untuk guru ybs.
  /// Admin tidak perlu — kembalikan list kosong bila bukan guru.
  Future<List<dynamic>> _fetchPiketHariIni(dynamic userId) async {
    if (_isAdmin || userId == null) return [];
    final day = _dayNames[DateTime.now().weekday % 7];
    try {
      final res = await _api.dio.get(
        '/piket-guru',
        queryParameters: {'day_of_week': day, 'teacher_id': userId},
      );
      if (res.data is Map && res.data['success'] == true) {
        final rows = res.data['data'] as List? ?? [];
        return rows
            .whereType<Map>()
            .map<Map<String, dynamic>>(
              (r) => {
                ...Map<String, dynamic>.from(r),
                '_kind': 'PIKET_GURU',
              },
            )
            .toList();
      }
    } catch (_) {
      // Tugas piket bersifat pelengkap — gagal memuat tidak menggagalkan dashboard.
    }
    return [];
  }

  Future<void> _fetchSummaries() async {
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final futures = _schedules.map((s) async {
      final cid = s['classroom_id'];
      final sess = (s['session_name'] ?? 'PAGI').toString();
      final sid = s['schedule_id'] ?? s['id'];
      if (cid == null || sid == null) return;

      try {
        final res = await _api.dio.get(
          '/attendances/class/$cid',
          queryParameters: {'session_name': sess, 'date': todayStr},
        );
        final sum = res.data?['summary'];
        if (sum is Map) {
          _summaries[int.tryParse(sid.toString()) ?? sid.hashCode] =
              Map<String, dynamic>.from(sum);
        }
      } catch (_) {}
    });

    await Future.wait(futures);
    notifyListeners();
  }
}
