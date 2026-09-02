import 'package:flutter/foundation.dart';
import '../data/api/api_service.dart';

class StudentKalenderProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoading = true;
  List<dynamic> _records = [];
  String? _error;

  bool get isLoading => _isLoading;
  List<dynamic> get records => _records;
  String? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.dio.get('/students/me/kalender');
      _records = response.data['data'] as List? ?? [];
    } catch (e) {
      _error = 'Gagal memuat kalender: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
