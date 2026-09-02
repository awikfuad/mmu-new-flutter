import 'package:flutter/foundation.dart';
import '../data/api/api_service.dart';

class KegiatanListProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoading = true;
  List<dynamic> _activities = [];
  String? _error;

  bool get isLoading => _isLoading;
  List<dynamic> get activities => _activities;
  String? get error => _error;

  /// [audience] opsional: 'murid' (MURID+SEMUA) atau 'guru' (GURU+SEMUA).
  /// Null/kosong -> semua kegiatan sesuai scope lembaga.
  Future<void> fetchActivities({String? audience}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.dio.get(
        '/kegiatan',
        queryParameters: audience != null && audience.isNotEmpty
            ? {'target': audience}
            : null,
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        _activities = response.data['data'] ?? [];
      }
    } catch (e) {
      _error = 'Gagal memuat kegiatan: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
