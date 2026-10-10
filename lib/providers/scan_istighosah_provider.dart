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
    } catch (_) {
      // Fallback dinamis jika kalender hijriah gagal dimuat
      final now = DateTime.now();
      final estimatedHijriYear = now.year - 579;
      return {'bulan_hijriah': 'Muharram', 'tahun_hijriah': estimatedHijriYear};
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
      // Ambil lokasi GPS secara aman (non-blocking)
      GeoPosition? geo;
      try {
        geo = await GeofenceHelper.getCurrentLocation();
      } catch (_) {}

      final now = DateTime.now();
      final dateStr =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final payload = <String, dynamic>{
        'activity_id': activityId,
        'nim': nim,
        'status': 'HADIR',
        'notes': 'Scan QR via aplikasi guru',
        'bulan_hijriah': waktuHijriah['bulan_hijriah'],
        'tahun_hijriah': waktuHijriah['tahun_hijriah'],
        'tanggal_absensi': dateStr,
      };
      if (geo != null) {
        payload.addAll(geo.toMap());
      }

      final response = await _api.dio.post(
        '/kegiatan/attendance',
        data: payload,
      );

      if (response.statusCode == 200 && response.data?['success'] == true) {
        final responseData = response.data?['data'];
        
        // Prioritaskan mengambil detail murid dari respons POST agar scan cepat
        if (responseData is Map) {
          studentName = responseData['student_name'] ?? responseData['name'] ?? nim;
          className = responseData['class_name'] ?? responseData['classroom'] ?? '-';
        } else {
          // Fallback fetch jika backend tidak mengembalikan detail murid
          try {
            final detail = await _api.dio.get('/muridKelas/$nim');
            if (detail.data?['success'] == true && detail.data?['data'] != null) {
              studentName = detail.data['data']['name'] ?? nim;
              className = detail.data['data']['class_name'] ?? '-';
            }
          } catch (_) {}
        }

        _lastStudentName = studentName;
        _lastClassName = className;
        _lastSuccess = true;
        _isProcessing = false;
        notifyListeners();
        return true;
      } else {
        _error = response.data?['message'] ?? 'Gagal memproses absensi.';
        _lastSuccess = false;
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