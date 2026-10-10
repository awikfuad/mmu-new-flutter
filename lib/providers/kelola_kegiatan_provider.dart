import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../data/api/api_service.dart';

class KelolaKegiatanProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  List<dynamic> _list = [];

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;
  List<dynamic> get list => _list;

  static const List<String> targetOptions = ['SEMUA', 'MURID', 'GURU'];

  Future<void> fetchList() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.dio.get('/kegiatan');
      _list = (res.data?['data'] ?? []) as List;
    } catch (e) {
      _error = _extractMessage(e, 'Gagal memuat kegiatan:');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> create({
    required String activityName,
    required String activityDate,
    String description = '',
    String target = 'SEMUA',
  }) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      await _api.dio.post('/kegiatan', data: {
        'activity_name': activityName,
        'activity_date': activityDate,
        'description': description.trim().isEmpty ? null : description.trim(),
        'target': target,
      });
      return null;
    } catch (e) {
      return _extractMessage(e, 'Gagal menyimpan kegiatan.');
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<String?> update(
    int id, {
    required String activityName,
    required String activityDate,
    String description = '',
    String target = 'SEMUA',
  }) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      await _api.dio.put('/kegiatan/$id', data: {
        'activity_name': activityName,
        'activity_date': activityDate,
        'description': description.trim().isEmpty ? null : description.trim(),
        'target': target,
      });
      return null;
    } catch (e) {
      return _extractMessage(e, 'Gagal memperbarui kegiatan.');
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<String?> delete(int id) async {
    _isSaving = true;
    notifyListeners();
    try {
      await _api.dio.delete('/kegiatan/$id');
      return null;
    } catch (e) {
      return _extractMessage(e, 'Gagal menghapus kegiatan.');
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