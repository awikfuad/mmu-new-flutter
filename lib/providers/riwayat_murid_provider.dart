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
      final results = await Future.wait([
        _api.dio.get('/kegiatan/student-attendance/history/${murid['nim']}'),
        _api.dio.get('/attendances/student-history/${murid['id']}'),
      ]);
      _kegiatanRecords = results[0].data?['data'] ?? [];
      _kbmRecords = results[1].data?['data'] ?? [];
    } catch (e) {
      _error = 'Gagal memuat riwayat murid: $e';
    } finally {
      _isLoadingDetail = false;
      notifyListeners();
    }
  }

  void resetSelection() {
    _selected = null;
    _filtered = _allMurid;
    notifyListeners();
  }
}
