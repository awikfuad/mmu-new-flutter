import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../data/api/api_service.dart';

class ParentProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoading = false;
  Map<String, dynamic>? _parentProfile;
  List<dynamic> _children = [];
  Map<String, dynamic>? _childProfile;
  List<dynamic> _childKbm = [];
  List<dynamic> _childKegiatan = [];
  List<dynamic> _childNilai = [];
  List<dynamic> _childPerilaku = [];
  List<dynamic> _childPrestasi = [];
  List<dynamic> _childJadwal = [];
  List<dynamic> _childPembayaran = [];
  Map<String, dynamic>? _childTabungan;
  List<dynamic> _childIzinSakit = [];
  List<dynamic> _childPaymentRequests = [];
  String? _error;

  bool get isLoading => _isLoading;
  Map<String, dynamic>? get parentProfile => _parentProfile;
  List<dynamic> get children => _children;
  Map<String, dynamic>? get childProfile => _childProfile;
  List<dynamic> get childKbm => _childKbm;
  List<dynamic> get childKegiatan => _childKegiatan;
  List<dynamic> get childNilai => _childNilai;
  List<dynamic> get childPerilaku => _childPerilaku;
  List<dynamic> get childPrestasi => _childPrestasi;
  List<dynamic> get childJadwal => _childJadwal;
  List<dynamic> get childPembayaran => _childPembayaran;
  Map<String, dynamic>? get childTabungan => _childTabungan;
  List<dynamic> get childIzinSakit => _childIzinSakit;
  List<dynamic> get childPaymentRequests => _childPaymentRequests;
  String? get error => _error;

  Future<void> fetchParentProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.dio.get('/parents/me');
      if (res.data['success'] == true) {
        _parentProfile = res.data['data'];
      }
    } on DioException catch (e) {
      _error = e.response?.data?['message'] ?? e.message;
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchChildren() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.dio.get('/parents/me/children');
      if (res.data['success'] == true) {
        _children = List<dynamic>.from(res.data['data'] ?? []);
      }
    } on DioException catch (e) {
      _error = e.response?.data?['message'] ?? e.message;
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchChildProfile(String nim) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.dio.get('/parents/me/children/$nim/profile');
      if (res.data['success'] == true) {
        _childProfile = res.data['data'];
      }
    } on DioException catch (e) {
      _error = e.response?.data?['message'] ?? e.message;
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchChildKbm(String nim, {int? academicYearId}) async {
    try {
      final params = <String, dynamic>{};
      if (academicYearId != null) params['academic_year_id'] = academicYearId;
      final res = await _api.dio.get('/parents/me/children/$nim/kbm', queryParameters: params);
      if (res.data['success'] == true) {
        _childKbm = List<dynamic>.from(res.data['data'] ?? []);
      }
    } on DioException catch (e) {
      _error = e.response?.data?['message'] ?? e.message;
    } catch (_) {}
    notifyListeners();
  }

  Future<void> fetchChildKegiatan(String nim, {int? academicYearId}) async {
    try {
      final params = <String, dynamic>{};
      if (academicYearId != null) params['academic_year_id'] = academicYearId;
      final res = await _api.dio.get('/parents/me/children/$nim/kegiatan', queryParameters: params);
      if (res.data['success'] == true) {
        _childKegiatan = List<dynamic>.from(res.data['data'] ?? []);
      }
    } on DioException catch (e) {
      _error = e.response?.data?['message'] ?? e.message;
    } catch (_) {}
    notifyListeners();
  }

  Future<void> fetchChildNilai(String nim, {int? academicYearId}) async {
    try {
      final params = <String, dynamic>{};
      if (academicYearId != null) params['academic_year_id'] = academicYearId;
      final res = await _api.dio.get('/parents/me/children/$nim/nilai', queryParameters: params);
      if (res.data['success'] == true) {
        _childNilai = List<dynamic>.from(res.data['data'] ?? []);
      }
    } on DioException catch (e) {
      _error = e.response?.data?['message'] ?? e.message;
    } catch (_) {}
    notifyListeners();
  }

  Future<void> fetchChildPerilaku(String nim, {int? academicYearId}) async {
    try {
      final params = <String, dynamic>{};
      if (academicYearId != null) params['academic_year_id'] = academicYearId;
      final res = await _api.dio.get('/parents/me/children/$nim/perilaku', queryParameters: params);
      if (res.data['success'] == true) {
        _childPerilaku = List<dynamic>.from(res.data['data'] ?? []);
      }
    } on DioException catch (e) {
      _error = e.response?.data?['message'] ?? e.message;
    } catch (_) {}
    notifyListeners();
  }

  Future<void> fetchChildPrestasi(String nim, {int? academicYearId}) async {
    try {
      final params = <String, dynamic>{};
      if (academicYearId != null) params['academic_year_id'] = academicYearId;
      final res = await _api.dio.get('/parents/me/children/$nim/prestasi', queryParameters: params);
      if (res.data['success'] == true) {
        _childPrestasi = List<dynamic>.from(res.data['data'] ?? []);
      }
    } on DioException catch (e) {
      _error = e.response?.data?['message'] ?? e.message;
    } catch (_) {}
    notifyListeners();
  }

  Future<void> fetchChildJadwal(String nim, {int? academicYearId}) async {
    try {
      final params = <String, dynamic>{};
      if (academicYearId != null) params['academic_year_id'] = academicYearId;
      final res = await _api.dio.get('/parents/me/children/$nim/jadwal', queryParameters: params);
      if (res.data['success'] == true) {
        _childJadwal = List<dynamic>.from(res.data['data'] ?? []);
      }
    } on DioException catch (e) {
      _error = e.response?.data?['message'] ?? e.message;
    } catch (_) {}
    notifyListeners();
  }

  Future<void> fetchChildPembayaran(String nim, {int? academicYearId}) async {
    try {
      final params = <String, dynamic>{};
      if (academicYearId != null) params['academic_year_id'] = academicYearId;
      final res = await _api.dio.get('/parents/me/children/$nim/pembayaran', queryParameters: params);
      if (res.data['success'] == true) {
        _childPembayaran = List<dynamic>.from(res.data['data'] ?? []);
      }
    } on DioException catch (e) {
      _error = e.response?.data?['message'] ?? e.message;
    } catch (_) {}
    notifyListeners();
  }

  Future<void> fetchChildTabungan(String nim) async {
    try {
      final res = await _api.dio.get('/parents/me/children/$nim/tabungan');
      if (res.data['success'] == true) {
        _childTabungan = Map<String, dynamic>.from(res.data['data'] ?? {});
      }
    } on DioException catch (e) {
      _error = e.response?.data?['message'] ?? e.message;
    } catch (_) {}
    notifyListeners();
  }

  Future<void> fetchChildIzinSakit(String nim) async {
    try {
      final res = await _api.dio.get('/parents/me/children/$nim/izin-sakit');
      if (res.data['success'] == true) {
        _childIzinSakit = List<dynamic>.from(res.data['data'] ?? []);
      }
    } on DioException catch (e) {
      _error = e.response?.data?['message'] ?? e.message;
    } catch (_) {}
    notifyListeners();
  }

  Future<bool> submitChildIzinSakit(String nim, {required String jenis, required String alasan, required String tanggalMulai, required String tanggalSelesai, String? keterangan}) async {
    try {
      final res = await _api.dio.post(
        '/parents/me/children/$nim/izin-sakit',
        data: {
          'jenis': jenis,
          'alasan': alasan,
          'tanggal_mulai': tanggalMulai,
          'tanggal_selesai': tanggalSelesai,
          if (keterangan != null && keterangan.isNotEmpty) 'keterangan': keterangan,
        },
      );
      if (res.data['success'] == true) {
        await fetchChildIzinSakit(nim);
        return true;
      }
      return false;
    } on DioException catch (e) {
      _error = e.response?.data?['message'] ?? e.message;
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> fetchChildPaymentRequests(String nim) async {
    try {
      final res = await _api.dio.get('/parents/me/children/$nim/payment-requests');
      if (res.data['success'] == true) {
        _childPaymentRequests = List<dynamic>.from(res.data['data'] ?? []);
      }
    } on DioException catch (e) {
      _error = e.response?.data?['message'] ?? e.message;
    } catch (_) {}
    notifyListeners();
  }

  Future<bool> submitPaymentRequest(String nim, {required String paymentType, String? month, required num amount}) async {
    try {
      final res = await _api.dio.post(
        '/parents/me/children/$nim/payment-requests',
        data: {
          'payment_type': paymentType,
          'month': month,
          'amount': amount,
        },
      );
      if (res.data['success'] == true) {
        await fetchChildPaymentRequests(nim);
        return true;
      }
      return false;
    } on DioException catch (e) {
      _error = e.response?.data?['message'] ?? e.message;
      return false;
    } catch (_) {
      return false;
    }
  }

  void clearChildData() {
    _childProfile = null;
    _childKbm = [];
    _childKegiatan = [];
    _childNilai = [];
    _childPerilaku = [];
    _childPrestasi = [];
    _childJadwal = [];
    _childPembayaran = [];
    _childTabungan = null;
    _childIzinSakit = [];
    _childPaymentRequests = [];
    notifyListeners();
  }
}
