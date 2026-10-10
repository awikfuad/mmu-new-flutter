import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../data/api/api_service.dart';
import '../data/models/ujian_models.dart';

class StudentUjianProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;
  List<UjianCard> _list = [];
  SesiUjian? _sesi;
  HasilUjian? _hasil;

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;
  List<UjianCard> get list => _list;
  SesiUjian? get sesi => _sesi;
  HasilUjian? get hasil => _hasil;

  /// Ambil daftar ujian online milik santri (GET /students/me/ujian).
  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.dio.get('/students/me/ujian');
      final data = res.data;
      final listData = (data is Map ? data['data'] : null) is Map
          ? ((data['data'] as Map)['data'] as List?)
          : null;
      _list = ((listData ?? []))
          .whereType<Map>()
          .map((e) => UjianCard.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      _error = _extractMessage(e, 'Gagal memuat ujian:');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Mulai / lanjutkan sesi ujian (POST /public/ujian/start).
  Future<bool> start({
    required int ujianId,
    required String kode,
    required String nim,
    required String name,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.dio.post('/public/ujian/start', data: {
        'ujian_id': ujianId,
        'kode': kode,
        'nim': nim,
        'name': name,
      });
      final data = res.data;
      final sesiData = data is Map ? data['data'] : null;
      if (sesiData is! Map) {
        _error = 'Respons tidak valid saat memulai ujian.';
        return false;
      }
      _sesi = SesiUjian.fromJson(Map<String, dynamic>.from(sesiData));
      _hasil = null;
      return true;
    } catch (e) {
      _error = _extractMessage(e, 'Gagal memulai ujian:');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Kumpulkan jawaban (POST /public/ujian/submit).
  Future<bool> submit({
    required int ujianId,
    required String kode,
    required String nim,
    required Map<String, dynamic> jawaban,
  }) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.dio.post('/public/ujian/submit', data: {
        'ujian_id': ujianId,
        'kode': kode,
        'nim': nim,
        'jawaban': jawaban,
      });
      final data = res.data;
      final hasilData = data is Map ? data['data'] : null;
      if (hasilData is! Map) {
        _error = 'Respons tidak valid saat mengumpulkan jawaban.';
        return false;
      }
      _hasil = HasilUjian.fromJson(Map<String, dynamic>.from(hasilData));
      _sesi = null;
      return true;
    } catch (e) {
      _error = _extractMessage(e, 'Gagal mengumpulkan jawaban:');
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Simpan progres jawaban (POST /public/ujian/save) — belum finalisasi,
  /// dipakai autosave wizard: jawaban bisa dimuat ulang via jawaban_sebelum saat resume.
  Future<bool> save({
    required int ujianId,
    required String kode,
    required String nim,
    required Map<String, dynamic> jawaban,
  }) async {
    try {
      await _api.dio.post('/public/ujian/save', data: {
        'ujian_id': ujianId,
        'kode': kode,
        'nim': nim,
        'jawaban': jawaban,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  void reset() {
    _error = null;
    _sesi = null;
    _hasil = null;
    notifyListeners();
  }

  String _extractMessage(Object e, String prefix) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
      return e.message ?? '$prefix $e';
    }
    return '$prefix $e';
  }
}