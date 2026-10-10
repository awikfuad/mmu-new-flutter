import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../data/api/api_service.dart';

class ArsipSoalanProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  List<dynamic> _list = [];
  String _search = '';
  String _imda = '';

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;
  List<dynamic> get list => _list;
  String get search => _search;
  String get imda => _imda;

  /// Opsi filter IMDA (kosong/null = arsip berlaku untuk semua IMDA).
  static const List<String> imdaOptions = ['IMDA 1', 'IMDA 2', 'IMDA 3'];

  int get totalCount => _list.length;

  Future<void> fetchList({String? search, String? imda}) async {
    _isLoading = true;
    _error = null;
    _search = search ?? _search;
    _imda = imda ?? _imda;
    notifyListeners();

    try {
      final params = <String, dynamic>{};
      if (_search.trim().isNotEmpty) params['search'] = _search.trim();
      if (_imda.trim().isNotEmpty) params['imda'] = _imda.trim();
      final res = await _api.dio.get('/arsip-soalan', queryParameters: params);
      _list = (res.data?['data'] ?? []) as List;
    } catch (e) {
      _error = _extractMessage(e, 'Gagal memuat arsip soal:');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> delete(int id) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      await _api.dio.delete('/arsip-soalan/$id');
      _list = _list.where((a) => (a['id'] ?? 0) != id).toList();
      return null;
    } catch (e) {
      return _extractMessage(e, 'Gagal menghapus arsip soal.');
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
