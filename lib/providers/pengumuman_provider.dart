import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../data/api/api_service.dart';

class PengumumanProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  List<dynamic> _list = [];
  String? _selectedKategori;
  String? _selectedStatus;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;
  List<dynamic> get list => _list;
  String? get selectedKategori => _selectedKategori;
  String? get selectedStatus => _selectedStatus;

  static const List<String> kategoriOptions = ['UMUM', 'AKADEMIK', 'KEUANGAN', 'KEGIATAN'];

  int get draftCount => _list.where((p) => (p['is_published'] ?? 0) == 0).length;
  int get publishedCount => _list.where((p) => (p['is_published'] ?? 0) == 1).length;

  Future<void> fetchList({String? kategori, String? status}) async {
    _isLoading = true;
    _error = null;
    _selectedKategori = kategori;
    _selectedStatus = status;
    notifyListeners();

    try {
      final params = <String, dynamic>{};
      if (kategori != null && kategori.isNotEmpty) params['kategori'] = kategori;
      if (status != null && status.isNotEmpty) params['status'] = status;
      final res = await _api.dio.get('/pengumuman', queryParameters: params);
      _list = (res.data?['data'] ?? []) as List;
    } catch (e) {
      _error = _extractMessage(e, 'Gagal memuat pengumuman:');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> create({
    required String judul,
    required String isi,
    String kategori = 'UMUM',
    String tanggalMulai = '',
    String tanggalSelesai = '',
    bool isPublished = false,
  }) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final mulai = tanggalMulai.isEmpty ? null : tanggalMulai;
      final selesai = tanggalSelesai.isEmpty ? null : tanggalSelesai;
      await _api.dio.post('/pengumuman', data: {
        'judul': judul,
        'isi': isi,
        'kategori': kategori,
        'tanggal_mulai': mulai,
        'tanggal_selesai': selesai,
        'is_published': isPublished ? 1 : 0,
      });
      return null;
    } catch (e) {
      final msg = _extractMessage(e, 'Gagal menyimpan pengumuman.');
      return msg;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<String?> update(
    int id, {
    String? judul,
    String? isi,
    String? kategori,
    String? tanggalMulai,
    String? tanggalSelesai,
  }) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final data = <String, dynamic>{};
      if (judul != null) data['judul'] = judul;
      if (isi != null) data['isi'] = isi;
      if (kategori != null) data['kategori'] = kategori;
      if (tanggalMulai != null) data['tanggal_mulai'] = tanggalMulai.isEmpty ? null : tanggalMulai;
      if (tanggalSelesai != null) data['tanggal_selesai'] = tanggalSelesai.isEmpty ? null : tanggalSelesai;
      await _api.dio.put('/pengumuman/$id', data: data);
      return null;
    } catch (e) {
      return _extractMessage(e, 'Gagal memperbarui pengumuman.');
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<String?> togglePublish(int id, bool isPublished) async {
    _isSaving = true;
    notifyListeners();
    try {
      await _api.dio.put('/pengumuman/$id/publish', data: {'is_published': isPublished ? 1 : 0});
      return null;
    } catch (e) {
      return _extractMessage(e, 'Gagal mengubah status publikasi.');
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<String?> delete(int id) async {
    _isSaving = true;
    notifyListeners();
    try {
      await _api.dio.delete('/pengumuman/$id');
      return null;
    } catch (e) {
      return _extractMessage(e, 'Gagal menghapus pengumuman.');
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