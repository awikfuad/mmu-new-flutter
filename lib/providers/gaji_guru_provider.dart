import 'package:flutter/foundation.dart';
import '../data/api/api_service.dart';

class GajiGuruProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoading = true;
  List<dynamic> _slips = [];
  String? _error;

  bool get isLoading => _isLoading;
  List<dynamic> get slips => _slips;
  String? get error => _error;

  double get totalGajiDibayar => _slips
      .where((s) => s['status'] == 'DIBAYAR')
      .fold(0.0, (sum, s) => sum + (s['total'] ?? 0).toDouble());

  double get totalGajiDraft => _slips
      .where((s) => s['status'] == 'DRAFT')
      .fold(0.0, (sum, s) => sum + (s['total'] ?? 0).toDouble());

  int get jumlahDibayar => _slips.where((s) => s['status'] == 'DIBAYAR').length;
  int get jumlahDraft => _slips.where((s) => s['status'] == 'DRAFT').length;

  Future<void> init() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.dio.get('/salary/me');
      if (response.statusCode == 200 && response.data['success'] == true) {
        _slips = response.data['data'] ?? [];
      } else {
        _error = response.data['message'] ?? 'Gagal memuat data gaji.';
      }
    } catch (e) {
      _error = 'Gagal memuat riwayat gaji: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
