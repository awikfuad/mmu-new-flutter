import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hijri/hijri_calendar.dart';
import '../data/api/api_service.dart';
import '../utils/geofence_helper.dart';

class ScanIstighosahProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isProcessing = false;
  String? _lastStudentName;
  String? _lastClassName;
  String? _error;
  bool? _lastSuccess;

  bool get isProcessing => _isProcessing;
  String? get lastStudentName => _lastStudentName;
  String? get lastClassName => _lastClassName;
  String? get error => _error;
  bool? get lastSuccess => _lastSuccess;

  static const List<String> _daftarBulanHijriah = [
    'Muharram', 'Shafar', 'Rb. Ula', 'Rb. Tsani',
    'Jmd. Ula', 'Jmd. Tsani', 'Rajab', "Sya'ban",
    'Ramadan', 'Syawal', "Dz. Qo'dah", 'Dz. Hijjah'
  ];

  Map<String, dynamic> _getWaktuHijriah() {
    try {
      final today = HijriCalendar.now();
      final int indexBulan = today.hMonth - 1;
      String namaBulan = (indexBulan >= 0 && indexBulan < _daftarBulanHijriah.length)
          ? _daftarBulanHijriah[indexBulan]
          : 'Muharram';
      return {'bulan_hijriah': namaBulan, 'tahun_hijriah': today.hYear};
    } catch (e) {
      return {'bulan_hijriah': 'Muharram', 'tahun_hijriah': 1447};
    }
  }

  Future<bool> processQrData(String nimRaw, int activityId) async {
    if (_isProcessing) return false;

    final String nim = nimRaw.trim();
    if (nim.isEmpty) {
      _error = 'Kode QR kosong. Silakan scan ulang.';
      _lastSuccess = false;
      notifyListeners();
      return false;
    }

    _isProcessing = true;
    _error = null;
    _lastSuccess = null;
    notifyListeners();
    String studentName = nim;
    String className = '-';
    final waktuHijriah = _getWaktuHijriah();

    try {
      // Capture GPS location
      final GeoPosition? geo = await GeofenceHelper.getCurrentLocation();

      final payload = <String, dynamic>{
        'activity_id': activityId,
        'nim': nim,
        'status': 'HADIR',
        'notes': 'Scan QR via aplikasi guru',
        'bulan_hijriah': waktuHijriah['bulan_hijriah'],
        'tahun_hijriah': waktuHijriah['tahun_hijriah'],
        'tanggal_absensi': DateTime.now().toIso8601String().split('T')[0],
      };
      if (geo != null) {
        payload.addAll(geo.toMap());
      }

      final response = await _api.dio.post(
        '/kegiatan/attendance',
        data: payload,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        try {
          final detail = await _api.dio.get('/muridKelas/$nim');
          if (detail.data?['success'] == true && detail.data['data'] != null) {
            studentName = detail.data['data']['name'] ?? nim;
            className = detail.data['data']['class_name'] ?? '-';
          }
        } catch (_) {}

        _lastStudentName = studentName;
        _lastClassName = className;
        _lastSuccess = true;
        _isProcessing = false;
        notifyListeners();
        return true;
      }
    } on DioException catch (e) {
      _error = e.response?.data?['message'] ??
          'Kode QR tidak dikenali atau santri tidak terdaftar.';
      _lastSuccess = false;
    } catch (e) {
      _error = 'Kode QR tidak dikenali atau santri tidak terdaftar.';
      _lastSuccess = false;
    }

    _isProcessing = false;
    notifyListeners();
    return false;
  }

  void resetResult() {
    _lastSuccess = null;
    _lastStudentName = null;
    _lastClassName = null;
    _error = null;
    notifyListeners();
  }
}
