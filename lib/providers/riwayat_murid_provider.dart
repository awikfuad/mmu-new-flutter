import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../data/api/api_service.dart';

class RiwayatMuridProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoadingList = true;
  bool _isLoadingDetail = false;
  List<dynamic> _allMurid = [];
  List<dynamic> _filtered = [];
  Map<String, dynamic>? _selected;
  List<dynamic> _kegiatanRecords = [];
  List<dynamic> _kbmRecords = [];
  String? _error;

  bool get isLoadingList => _isLoadingList;
  bool get isLoadingDetail => _isLoadingDetail;
  List<dynamic> get filtered => _filtered;
  Map<String, dynamic>? get selected => _selected;
  List<dynamic> get kegiatanRecords => _kegiatanRecords;
  List<dynamic> get kbmRecords => _kbmRecords;
  String? get error => _error;

  int get hadirKegiatan => _kegiatanRecords.where((r) => r['status'] == 'HADIR').length;
  int get sakitKegiatan => _kegiatanRecords.where((r) => r['status'] == 'SAKIT').length;
  int get izinKegiatan => _kegiatanRecords.where((r) => r['status'] == 'IZIN').length;
  int get alpaKegiatan => _kegiatanRecords.where((r) => r['status'] != 'HADIR' && r['status'] != 'SAKIT' && r['status'] != 'IZIN').length;

  int get hadirKbm => _kbmRecords.where((r) => r['status'] == 'HADIR').length;
  int get sakitKbm => _kbmRecords.where((r) => r['status'] == 'SAKIT').length;
  int get izinKbm => _kbmRecords.where((r) => r['status'] == 'IZIN').length;
  int get alpaKbm => _kbmRecords.where((r) => r['status'] != 'HADIR' && r['status'] != 'SAKIT' && r['status'] != 'IZIN').length;

  Future<void> fetchMuridList() async {
    _isLoadingList = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.dio.get('/muridKelas');
      if (response.statusCode == 200 && response.data['success'] == true) {
        _allMurid = response.data['data'] ?? [];
        _filtered = _allMurid;
      }
    } catch (e) {
      _error = 'Gagal memuat daftar murid: $e';
    } finally {
      _isLoadingList = false;
      notifyListeners();
    }
  }

  void filterSearch(String query) {
    final q = query.trim().toLowerCase();
    _filtered = q.isEmpty
        ? _allMurid
        : _allMurid
            .where((m) =>
                (m['name'] ?? '').toString().toLowerCase().contains(q) ||
                (m['nim'] ?? '').toString().toLowerCase().contains(q))
            .toList();
    notifyListeners();
  }

  Future<void> selectMurid(Map<String, dynamic> murid) async {
    _selected = murid;
    _isLoadingDetail = true;
    _error = null;
    notifyListeners();

    try {
      final nim = murid['nim']?.toString();
      final id = murid['id']?.toString();
      if (nim == null || nim.isEmpty || id == null || id.isEmpty) {
        _error = 'Data murid tidak lengkap (NIM/ID kosong)';
        return;
      }

      // Fetch independently agar satu gagal tidak membatalkan yang lain
      final list = await Future.wait<Response<dynamic>?>([
        _safeGet('/kegiatan/student-attendance/history/$nim'),
        _safeGet('/attendances/student-history/$id'),
      ], eagerError: false);

      _kegiatanRecords = list[0]?.data?['data'] ?? [];
      _kbmRecords = list[1]?.data?['data'] ?? [];
    } catch (e) {
      _error = 'Gagal memuat riwayat murid: $e';
    } finally {
      _isLoadingDetail = false;
      notifyListeners();
    }
  }

  Future<Response<dynamic>?> _safeGet(String path) async {
    try {
      return await _api.dio.get(path);
    } catch (_) {
      return null;
    }
  }

  void resetSelection() {
    _selected = null;
    _filtered = _allMurid;
    notifyListeners();
  }
}
