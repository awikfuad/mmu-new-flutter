import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../data/api/api_service.dart';

class IzinGuruAdminProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  List<dynamic> _list = [];
  List<dynamic> _teachers = [];
  String? _selectedStatus;
  Map<String, dynamic>? _detail;
  List<dynamic> _detailSchedules = [];
  int? _detailIzinId;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;
  List<dynamic> get list => _list;
  List<dynamic> get teachers => _teachers;
  String? get selectedStatus => _selectedStatus;
  Map<String, dynamic>? get detail => _detail;
  List<dynamic> get detailSchedules => _detailSchedules;
  int? get detailIzinId => _detailIzinId;

  static const List<String> jenisOptions = ['IZIN', 'SAKIT', 'DINAS'];
  static const List<String> statusOptions = ['AKTIF', 'SELESAI'];

  Future<void> fetchList({String? status}) async {
    _isLoading = true;
    _error = null;
    _selectedStatus = status;
    notifyListeners();

    try {
      final params = <String, dynamic>{};
      if (status != null && status.isNotEmpty) params['status'] = status;
      final res = await _api.dio.get('/izin-guru', queryParameters: params);
      _list = (res.data?['data'] ?? []) as List;
    } catch (e) {
      _error = _extractMessage(e, 'Gagal memuat izin guru:');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchTeachers() async {
    try {
      final res = await _api.dio.get('/teachers');
      _teachers = (res.data?['data'] ?? []) as List;
    } catch (e) {
      _error = _extractMessage(e, 'Gagal memuat daftar guru:');
    }
    notifyListeners();
  }

  Future<void> fetchDetail(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.dio.get('/izin-guru/$id/jadwal-terdampak');
      _detailIzinId = id;
      _detail = Map<String, dynamic>.from((res.data ?? {}) as Map);
      _detailSchedules = ((res.data?['schedules']) ?? []) as List;
    } catch (e) {
      _error = _extractMessage(e, 'Gagal memuat detail izin:');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> createIzin({
    required int teacherId,
    required String jenis,
    required String alasan,
    required String tanggalMulai,
    required String tanggalSelesai,
    String keterangan = '',
  }) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      await _api.dio.post('/izin-guru', data: {
        'teacher_id': teacherId,
        'jenis': jenis,
        'alasan': alasan,
        'tanggal_mulai': tanggalMulai,
        'tanggal_selesai': tanggalSelesai,
        'keterangan': keterangan.trim().isEmpty ? null : keterangan.trim(),
      });
      return null;
    } catch (e) {
      return _extractMessage(e, 'Gagal menyimpan izin guru.');
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<String?> assignBadal(int izinId, int scheduleId, String tanggal, int? substituteId) async {
    _isSaving = true;
    notifyListeners();
    try {
      final res = await _api.dio.post('/izin-guru/$izinId/pengganti', data: {
        'schedule_id': scheduleId,
        'tanggal': tanggal,
        'substitute_teacher_id': substituteId,
      });
      final msg = res.data?['message']?.toString();
      return msg ?? (substituteId == null ? 'Penunjukan badal dihapus.' : 'Badal berhasil ditetapkan.');
    } catch (e) {
      return _extractMessage(e, 'Gagal menetapkan badal.');
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<String?> finishIzin(int izinId) async {
    _isSaving = true;
    notifyListeners();
    try {
      final res = await _api.dio.put('/izin-guru/$izinId/selesai');
      final msg = res.data?['message']?.toString();
      return msg ?? 'Izin ditandai selesai.';
    } catch (e) {
      return _extractMessage(e, 'Gagal menandai izin selesai.');
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<String?> deleteIzin(int izinId) async {
    _isSaving = true;
    notifyListeners();
    try {
      await _api.dio.delete('/izin-guru/$izinId');
      return null;
    } catch (e) {
      return _extractMessage(e, 'Gagal menghapus catatan izin.');
    } finally {
      _isSaving = false;
      notifyListeners();
    }
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