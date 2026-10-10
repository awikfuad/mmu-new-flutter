import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../data/api/api_service.dart';

class PrestasiPelanggaranProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  List<dynamic> _list = [];
  List<dynamic> _murids = [];
  String? _selectedTipe;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;
  List<dynamic> get list => _list;
  List<dynamic> get murids => _murids;
  String? get selectedTipe => _selectedTipe;

  static const List<String> tipeOptions = ['PRESTASI', 'PELANGGARAN'];
  static const List<String> kategoriPrestasi = [
    'AKADEMIK', 'AKHLAK', 'KEHADIRAN', 'KEAGAMAAN', 'OLAHRAGA', 'LAINNYA',
  ];
  static const List<String> kategoriPelanggaran = [
    'KEDISIPLINAN', 'KETERTIBAN', 'KETIDAKHADIRAN', 'AKHLAK', 'LAINNYA',
  ];

  List<String> get kategoriOptions =>
      _selectedTipe == 'PELANGGARAN' ? kategoriPelanggaran : kategoriPrestasi;

  Future<void> fetchList({String? tipe}) async {
    _isLoading = true;
    _error = null;
    _selectedTipe = tipe;
    notifyListeners();

    try {
      final params = <String, dynamic>{};
      if (tipe != null && tipe.isNotEmpty) params['tipe'] = tipe;
      final res = await _api.dio.get('/prestasi-pelanggaran', queryParameters: params);
      _list = (res.data?['data'] ?? []) as List;
    } catch (e) {
      _error = _extractMessage(e, 'Gagal memuat prestasi & pelanggaran:');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMurids() async {
    try {
      final res = await _api.dio.get('/muridKelas');
      _murids = (res.data?['data'] ?? []) as List;
    } catch (e) {
      _error = _extractMessage(e, 'Gagal memuat daftar murid:');
    }
    notifyListeners();
  }

  Future<String?> create({
    required dynamic muridId,
    required String nim,
    required String sumber,
    required String tipe,
    required String kategori,
    required String deskripsi,
    required String tanggal,
    int? poin,
    String catatan = '',
  }) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      await _api.dio.post('/prestasi-pelanggaran', data: {
        'murid_id': muridId,
        'nim': nim,
        'sumber': sumber,
        'tipe': tipe,
        'kategori': kategori,
        'deskripsi': deskripsi.trim(),
        'tanggal': tanggal,
        'poin': poin,
        'catatan': catatan.trim().isEmpty ? null : catatan.trim(),
      });
      return null;
    } catch (e) {
      return _extractMessage(e, 'Gagal menyimpan catatan.');
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<String?> update(
    int id, {
    String? tipe,
    String? kategori,
    String? deskripsi,
    int? poin,
    String? catatan,
    String? tanggal,
  }) async {
    _isSaving = true;
    notifyListeners();
    try {
      final data = <String, dynamic>{};
      if (tipe != null) data['tipe'] = tipe;
      if (kategori != null) data['kategori'] = kategori;
      if (deskripsi != null) data['deskripsi'] = deskripsi.trim();
      if (poin != null) data['poin'] = poin;
      if (catatan != null) data['catatan'] = catatan.trim().isEmpty ? null : catatan.trim();
      if (tanggal != null) data['tanggal'] = tanggal;
      await _api.dio.put('/prestasi-pelanggaran/$id', data: data);
      return null;
    } catch (e) {
      return _extractMessage(e, 'Gagal mengubah catatan.');
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<String?> delete(int id) async {
    _isSaving = true;
    notifyListeners();
    try {
      await _api.dio.delete('/prestasi-pelanggaran/$id');
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