import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../data/api/api_service.dart';
import '../data/local/local_storage.dart';

class RiwayatGuruProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoading = true;
  bool _isAdmin = false;
  String _teacherName = 'Guru';
  List<dynamic> _teachers = [];
  int? _selectedTeacherId;
  List<dynamic> _kegiatanRecords = [];
  List<dynamic> _mengajarRecords = [];
  String? _error;

  bool get isLoading => _isLoading;
  bool get isAdmin => _isAdmin;
  String get teacherName => _teacherName;
  List<dynamic> get teachers => _teachers;
  int? get selectedTeacherId => _selectedTeacherId;
  List<dynamic> get kegiatanRecords => _kegiatanRecords;
  List<dynamic> get mengajarRecords => _mengajarRecords;
  String? get error => _error;

  int get hadirKegiatan => _kegiatanRecords.where((r) => r['status'] == 'HADIR').length;
  int get sakitKegiatan => _kegiatanRecords.where((r) => r['status'] == 'SAKIT').length;
  int get izinKegiatan => _kegiatanRecords.where((r) => r['status'] == 'IZIN').length;
  int get alpaKegiatan => _kegiatanRecords.where((r) => r['status'] != 'HADIR' && r['status'] != 'SAKIT' && r['status'] != 'IZIN').length;

  Future<void> init() async {
    final user = await LocalStorage.getUser();
    if (user == null) {
      _error = 'Data pengguna tidak ditemukan.';
      _isLoading = false;
      notifyListeners();
      return;
    }

    final String role = user['role'] ?? 'teacher';
    _isAdmin = role == 'admin';

    if (_isAdmin) {
      await _loadTeachers();
    } else {
      _teacherName = user['name'] ?? 'Guru';
      final id = user['id'];
      if (id == null) {
        _error = 'Data guru tidak lengkap (ID kosong)';
        _isLoading = false;
        notifyListeners();
        return;
      }
      await _loadAll(id);
    }
  }

  Future<void> _loadTeachers() async {
    try {
      final response = await _api.dio.get('/teachers');
      if (response.statusCode == 200 && response.data['success'] == true) {
        _teachers = response.data['data'] ?? [];
        if (_teachers.isNotEmpty) {
          _selectedTeacherId = _teachers.first['id'];
          _teacherName = _teachers.first['name'] ?? 'Guru';
          await _loadAll(_selectedTeacherId!);
          return;
        }
      }
    } catch (e) {
      _error = 'Gagal memuat daftar guru.';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> selectTeacher(int teacherId) async {
    _selectedTeacherId = teacherId;
    final found = _teachers.firstWhere((t) => t['id'] == teacherId, orElse: () => null);
    if (found != null) _teacherName = found['name'] ?? 'Guru';
    notifyListeners();
    await _loadAll(teacherId);
  }

  Future<void> _loadAll(int teacherId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Fetch independently agar satu gagal tidak membatalkan yang lain
      final list = await Future.wait<Response<dynamic>?>([
        _safeGet('/kegiatan/teacher-attendance/history/$teacherId'),
        _safeGet('/attendances/teacher-history/$teacherId'),
      ], eagerError: false);
      _kegiatanRecords = list[0]?.data?['data'] ?? [];
      _mengajarRecords = list[1]?.data?['data'] ?? [];
    } catch (e) {
      _error = 'Gagal memuat riwayat absensi: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Response<dynamic>?> _safeGet(String path) async {
    try {
      return await _api.dio.get(path);
    } catch (_) {
      return null;
    }
  }
}
