import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../data/api/api_service.dart';

/// Provider untuk halaman "Piket Hari Ini": menampilkan SELURUH jadwal kelas
/// hari ini (semua jenjang — Sifir, Ibtidaiyah, Tsanawiyah, TPQ). Kelas yang
/// tumpang waktu dengan jam piket guru ditandai agar mudah dipilih, namun
/// semua kelas tetap ditampilkan.
class PiketHariIniProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoading = true;
  String? _error;
  List<dynamic> _schedules = [];
  String? _piketStart;
  String? _piketEnd;
  final Map<int, String> _jenjangNames = {};

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<dynamic> get schedules => _schedules;
  String? get piketStart => _piketStart;
  String? get piketEnd => _piketEnd;

  // Nama hari Indonesia (index = DateTime.weekday % 7; 0 = Ahad/Minggu).
  static const List<String> _dayNames = [
    'AHAD', 'SENIN', 'SELASA', 'RABU', 'KAMIS', 'JUMAT', 'SABTU',
  ];

  // Cadangan bila daftar jenjang tidak dapat dimuat.
  static const Map<int, String> _fallbackJenjang = {
    1: 'Sifir',
    2: 'Ibtidaiyah',
    3: 'Tsanawiyah',
    100: 'TPQ',
  };

  /// Set jam piket guru (dari roster /piket-guru). Dipakai untuk **menandai**
  /// kelas yang beririsan dengan jam piket — bukan untuk menyembunyikan kelas.
  void configure({String? piketStart, String? piketEnd}) {
    _piketStart = (piketStart ?? '').toString().trim().isEmpty
        ? null
        : piketStart;
    _piketEnd =
        (piketEnd ?? '').toString().trim().isEmpty ? null : piketEnd;
  }

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final rows = await _fetchTodaySchedules();
      final list = rows.whereType<Map>().toList()
        ..sort(
          (a, b) => (a['start_time'] ?? '')
              .toString()
              .compareTo((b['start_time'] ?? '').toString()),
        );
      _schedules = list;
      // Muat nama jenjang (best-effort) agar kartu dapat menampilkan jenjang.
      await _fetchJenjangNames();
    } on DioException catch (e) {
      _error = _messageFrom(e, 'Gagal memuat jadwal hari ini');
    } catch (e) {
      _error = 'Gagal memuat jadwal: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Nama jenjang utk sebuah baris jadwal.
  String jenjangName(dynamic s) {
    final id = int.tryParse('${s['jenjang_id'] ?? ''}');
    if (id == null) return '';
    return _jenjangNames[id] ?? _fallbackJenjang[id] ?? 'Jenjang $id';
  }

  /// Kelas sudah selesai (jam berakhir sudah lewat) — tetap ditampilkan namun
  /// bisa dibedakan secara visual.
  bool isFinished(dynamic s) {
    final end = (s['end_time'] ?? '').toString();
    if (end.isEmpty) return false;
    return end.compareTo(_nowHHMM()) <= 0;
  }

  /// Kelas tumpang waktu dengan jam piket guru.
  bool withinPiket(dynamic s) {
    if (_piketStart == null || _piketEnd == null) return false;
    final start = (s['start_time'] ?? '').toString();
    final end = (s['end_time'] ?? '').toString();
    if (start.isEmpty || end.isEmpty) return false;
    return start.compareTo(_piketEnd!) < 0 && end.compareTo(_piketStart!) > 0;
  }

  /// Ambil jadwal semua kelas hari ini. Sumber utama `/schedules/today-all`
  /// (admin+guru). Bila backend belum diperbarui (403/404 utk guru), fallback
  /// ke `/schedulesAll/:tahun` yang sudah lama dapat diakses guru.
  Future<List<dynamic>> _fetchTodaySchedules() async {
    try {
      final res = await _api.dio.get('/schedules/today-all');
      if (res.statusCode == 200 &&
          res.data is Map &&
          res.data['success'] == true) {
        return List<dynamic>.from(res.data['data'] ?? []);
      }
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code != 403 && code != 404) rethrow;
    }
    return _fetchTodayFromYear();
  }

  Future<List<dynamic>> _fetchTodayFromYear() async {
    final yearId = await _fetchActiveYearId();
    final res = await _api.dio.get('/schedulesAll/$yearId');
    final rows = List<dynamic>.from(res.data?['data'] ?? []);
    final day = _dayNames[DateTime.now().weekday % 7];
    return rows
        .whereType<Map>()
        .where((r) =>
            (r['day_of_week'] ?? '').toString().toUpperCase() == day)
        .toList();
  }

  Future<int> _fetchActiveYearId() async {
    try {
      final res = await _api.dio.get('/academic-years/active');
      final id = res.data?['data']?['id'];
      if (id != null) return int.parse(id.toString());
    } catch (_) {
      // lanjut ke fallback di bawah
    }
    final res = await _api.dio.get('/students/filter-options');
    final id = res.data?['tahun']?['id'];
    if (id == null) throw Exception('Tahun ajaran aktif tidak ditemukan');
    return int.parse(id.toString());
  }

  Future<void> _fetchJenjangNames() async {
    if (_jenjangNames.isNotEmpty) return;
    try {
      final res = await _api.dio.get('/students/filter-options');
      final list = res.data?['jenjang'];
      if (list is List) {
        for (final it in list) {
          if (it is Map && it['id'] != null) {
            _jenjangNames[int.parse(it['id'].toString())] =
                (it['nama_jenjang'] ?? '').toString();
          }
        }
      }
    } catch (_) {
      // abaikan — pakai nama cadangan
    }
  }

  /// Ambil alih piket kelas (POST /schedules/:scheduleId/claim-piket) agar guru
  /// piket berhak mengisi presensi kelas tsb. Mengembalikan pesan error bila
  /// gagal (mis. sudah menjadi guru utama) atau null bila berhasil.
  Future<String?> claimPiket(int scheduleId) async {
    try {
      final res = await _api.dio.post('/schedules/$scheduleId/claim-piket');
      if (res.statusCode == 200 &&
          res.data is Map &&
          res.data['success'] == true) {
        return null;
      }
      return (res.data is Map ? res.data['message'] : null)?.toString() ??
          'Gagal mengambil alih kelas.';
    } on DioException catch (e) {
      return _messageFrom(e, 'Gagal mengambil alih kelas');
    } catch (e) {
      return 'Gagal mengambil alih kelas: $e';
    }
  }

  static String _messageFrom(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    return '$fallback: ${e.message}';
  }

  static String _nowHHMM() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }
}
