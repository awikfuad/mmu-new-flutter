import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../data/api/api_service.dart';

class IzinSakitAdminProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  List<dynamic> _list = [];
  List<dynamic> _students = [];
  String? _selectedStatus;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;
  List<dynamic> get list => _list;
  List<dynamic> get students => _students;
  String? get selectedStatus => _selectedStatus;

  static const List<String> jenisOptions = ['IZIN', 'SAKIT'];
  static const List<String> statusOptions = ['MENUNGGU', 'DISETUJUI', 'DITOLAK'];

  Future<void> fetchList({String? status}) async {
    _isLoading = true;
    _error = null;
    _selectedStatus = status;
    notifyListeners();

    try {
      final params = <String, dynamic>{};
      if (status != null && status.isNotEmpty) params['status'] = status;
      final res = await _api.dio.get('/izin-sakit', queryParameters: params);
      _list = (res.data?['data'] ?? []) as List;
    } catch (e) {
      _error = _extractMessage(e, 'Gagal memuat izin/sakit murid:');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchStudents() async {
    try {
      final res = await _api.dio.get('/students');
      _students = (res.data?['data'] ?? []) as List;
    } catch (e) {
      _error = _extractMessage(e, 'Gagal memuat daftar murid:');
    }
    notifyListeners();
  }

  Future<String?> create({
    required int studentId,
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
      await _api.dio.post('/izin-sakit', data: {
        'student_id': studentId,
        'jenis': jenis,
        'alasan': alasan,
        'tanggal_mulai': tanggalMulai,
        'tanggal_selesai': tanggalSelesai,
        'keterangan': keterangan.trim().isEmpty ? null : keterangan.trim(),
      });
      return null;
    } catch (e) {
      return _extractMessage(e, 'Gagal menyimpan izin/sakit.');
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<String?> setStatus(int id, String status) async {
    _isSaving = true;
    notifyListeners();
    try {
      await _api.dio.put('/izin-sakit/$id', data: {'status': status});
      return null;
    } catch (e) {
      return _extractMessage(e, 'Gagal mengubah status.');
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<String?> delete(int id) async {
    _isSaving = true;
    notifyListeners();
    try {
      await _api.dio.delete('/izin-sakit/$id');
      return null;
    } catch (e) {
      return _extractMessage(e, 'Gagal menghapus catatan.');
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