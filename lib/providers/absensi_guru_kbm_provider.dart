import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../data/api/api_service.dart';

class AbsensiGuruKbmProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  String _tanggal = '';
  List<dynamic> _roster = [];
  final Map<int, String> _status = {};
  final Map<int, String> _previousStatus = {};
  final Map<int, String> _keterangan = {};

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;
  String get tanggal => _tanggal;
  List<dynamic> get roster => _roster;
  Map<int, String> get status => _status;
  Map<int, String> get previousStatus => _previousStatus;
  Map<int, String> get keterangan => _keterangan;

  int get hadirCount =>
      _status.values.where((v) => v.toUpperCase() == 'HADIR').length;
  int get sakitCount =>
      _status.values.where((v) => v.toUpperCase() == 'SAKIT').length;
  int get izinCount =>
      _status.values.where((v) => v.toUpperCase() == 'IZIN').length;
  int get alpaCount =>
      _status.values.where((v) => v.toUpperCase() == 'ALPA').length;
  int get totalCount => _roster.length;

  int get changedCount => _roster.where((s) {
    final scheduleId = int.tryParse('${s['schedule_id'] ?? ''}');
    if (scheduleId == null) return false;
    final cur = (_status[scheduleId] ?? 'HADIR').toUpperCase();
    final prev = _previousStatus[scheduleId];
    return prev == null || prev.isEmpty
        ? cur != 'HADIR'
        : cur != prev.toUpperCase();
  }).length;

  Map<String, int> get summary => {
    'hadir': hadirCount,
    'sakit': sakitCount,
    'izin': izinCount,
    'alpa': alpaCount,
    'total': totalCount,
  };

  static String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String defaultDate() {
    final now = DateTime.now();
    return _fmt(now);
  }

  Future<void> fetchRoster(String tanggal) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.dio.get(
        '/teacher-kbm-attendance',
        queryParameters: {'tanggal': tanggal},
      );
      final data = (res.data?['data'] ?? []) as List;
      _roster = data;
      _tanggal = tanggal;
      _status.clear();
      _previousStatus.clear();
      _keterangan.clear();
      for (final s in data) {
        final scheduleId = int.tryParse('${s['schedule_id'] ?? ''}');
        if (scheduleId == null) continue;
        final st = (s['status'] ?? '').toString().toUpperCase();
        _status[scheduleId] = st.isEmpty ? 'HADIR' : st;
        _previousStatus[scheduleId] = st.isEmpty ? 'HADIR' : st;
        _keterangan[scheduleId] = (s['keterangan'] ?? '').toString().isEmpty
            ? ''
            : (s['keterangan'] ?? '').toString();
      }
    } catch (e) {
      _error = _extractMessage(e, 'Gagal mengambil roster mengajar:');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setStatus(int scheduleId, String statusValue) {
    final norm = statusValue.toUpperCase();
    _status[scheduleId] = norm == 'ALFA' ? 'ALPA' : norm;
    notifyListeners();
  }

  void setKeterangan(int scheduleId, String value) {
    _keterangan[scheduleId] = value;
    notifyListeners();
  }

  Future<bool> save() async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    final List<Map<String, dynamic>> items = [];
    for (final s in _roster) {
      final scheduleId = int.tryParse('${s['schedule_id'] ?? ''}');
      if (scheduleId == null) continue;
      _previousStatus[scheduleId] = (_status[scheduleId] ?? 'HADIR')
          .toUpperCase();
      s['keterangan'] =
          _keterangan[scheduleId]?.trim() ??
          ''; // Tambahkan baris ini[cite: 12]
    }

    var success = false;
    try {
      if (items.isEmpty) {
        _error = null;
        success = true;
      } else {
        final res = await _api.dio.post(
          '/teacher-kbm-attendance',
          data: {'tanggal': _tanggal, 'items': items},
        );
        success = res.statusCode == 200;
        _error = null;
        // Sinkronkan status terkini
        for (final s in _roster) {
          final scheduleId = int.tryParse('${s['schedule_id'] ?? ''}');
          if (scheduleId == null) continue;
          _previousStatus[scheduleId] = (_status[scheduleId] ?? 'HADIR')
              .toUpperCase();
        }
      }
    } catch (e) {
      _error = _extractMessage(e, 'Gagal menyimpan absensi:');
      success = false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }

    return success;
  }

  String _extractMessage(Object e, String prefix) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        return '${data['message']}';
      }
      return e.message ?? '$prefix $e';
    }
    return '$prefix $e';
  }
}
