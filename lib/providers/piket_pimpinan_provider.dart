import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../data/api/api_service.dart';

class PiketPimpinanProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoading = true;
  String? _error;

  Map<String, dynamic> _roster = {};
  Map<String, dynamic> _presensi = {};

  final List<String> _hariList = const [
    'SENIN', 'SELASA', 'RABU', 'KAMIS', 'JUMAT', 'SABTU', 'AHAD',
  ];
  String _selectedTanggal = _todayISO();

  bool get isLoading => _isLoading;
  String? get error => _error;

  Map<String, dynamic> get roster => _roster;
  Map<String, List<dynamic>> get dataByDay {
    final raw = _roster['data'];
    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value is List ? value : []));
    }
    return {};
  }

  int get total => _toInt(_roster['total']) ?? 0;
  int get totalTerisi => _toInt(_roster['total_terisi']) ?? 0;
  List<String> get hariList => _hariList;

  Map<String, dynamic> get presensi => _presensi;
  List<dynamic> get presensiData =>
      _presensi['data'] is List ? (_presensi['data'] as List) : [];
  String get presensiHari => _presensi['hari']?.toString() ?? '';
  int get presensiTotal => _toInt(_presensi['total']) ?? 0;
  String get selectedTanggal => _selectedTanggal;

  static const List<String> _dayNames = [
    '', 'SENIN', 'SELASA', 'RABU', 'KAMIS', 'JUMAT', 'SABTU', 'AHAD',
  ];

  int? _toInt(dynamic value) => int.tryParse('${value ?? ''}');

  static String _todayISO() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  String get todayDayName => _dayNames[DateTime.now().weekday];

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final rosterRes = await _api.dio.get('/piket-pimpinan');
      if (rosterRes.data is Map && rosterRes.data['success'] == true) {
        final data = rosterRes.data['data'];
        if (data is Map) _roster = Map<String, dynamic>.from(data);
      }
      await loadPresensi(_selectedTanggal, quiet: true);
    } on DioException catch (e) {
      _error = e.response?.data?['message']?.toString() ??
          'Gagal memuat piket pimpinan: ${e.message}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> loadPresensi(String tanggal, {bool quiet = false}) async {
    _selectedTanggal = tanggal;
    if (!quiet) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }
    try {
      final res = await _api.dio.get('/piket-pimpinan/presensi', queryParameters: {'tanggal': tanggal});
      if (res.data is Map && res.data['success'] == true) {
        final data = res.data['data'];
        _presensi = data is Map ? Map<String, dynamic>.from(data) : {};
        return null;
      }
      final msg = res.data is Map
          ? res.data['message']?.toString()
          : 'Gagal memuat presensi pimpinan';
      _error = msg ?? 'Gagal memuat presensi pimpinan';
      return _error;
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString() ??
          'Gagal memuat presensi pimpinan: ${e.message}';
      _error = msg;
      return msg;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}