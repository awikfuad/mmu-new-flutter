import 'package:flutter/foundation.dart';
import '../data/api/api_service.dart';

class PembayaranAdminProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoading = true;
  List<dynamic> _transactions = [];
  List<dynamic> _recaps = [];
  String? _error;

  bool get isLoading => _isLoading;
  List<dynamic> get transactions => _transactions;
  List<dynamic> get recaps => _recaps;
  String? get error => _error;

  /// Jumlah periode pada rekap pembayaran.
  int get totalPeriode => _recaps.length;

  /// Total seluruh nominal (Yaumiyah + Daftar Ulang).
  int get totalSemua => _transactions.fold(0, (sum, t) {
    final amount = t['amount'];
    return sum + ((amount is num) ? amount.round() : 0);
  });

  int get totalYaumiyah => _transactions.fold(0, (sum, t) {
    final amount = t['amount'];
    final type = (t['payment_type'] ?? '').toString();
    return sum + ((amount is num && type != 'DAFTAR_ULANG') ? amount.round() : 0);
  });

  int get totalDaftarUlang => _transactions.fold(0, (sum, t) {
    final amount = t['amount'];
    final type = (t['payment_type'] ?? '').toString();
    return sum + ((amount is num && type == 'DAFTAR_ULANG') ? amount.round() : 0);
  });

  /// Label periode untuk sebuah transaksi: dikelompokkan **per tanggal
  /// transaksi** (dari `payment_date`), diformat `dd NamaBulan yyyy`.
  static const List<String> _bulanMasehi = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  static String periodLabelOf(dynamic t) {
    final raw = (t['payment_date'] ?? t['created_at'] ?? '').toString();
    final date = raw.length >= 10 ? raw.substring(0, 10) : '';
    if (date.isEmpty) return 'Tanpa Tanggal';
    final dt = DateTime.tryParse(date);
    if (dt == null) return date;
    return '${dt.day} ${_bulanMasehi[dt.month - 1]} ${dt.year}';
  }

  /// Kelompokkan transaksi per periode (bulan hijriah / tanggal bayar).
  void _buildRecaps() {
    final map = <String, dynamic>{};
    for (final t in _transactions) {
      final key = periodLabelOf(t);
      if (!map.containsKey(key)) {
        map[key] = {
          'period': key,
          'yaumiyah': 0,
          'daftarUlang': 0,
          'total': 0,
          'count': 0,
          'items': <dynamic>[],
        };
      }
      final g = map[key];
      final amount = (t['amount'] as num?)?.round() ?? 0;
      final isDaftarUlang =
          (t['payment_type'] ?? '').toString() == 'DAFTAR_ULANG';
      if (isDaftarUlang) {
        g['daftarUlang'] += amount;
      } else {
        g['yaumiyah'] += amount;
      }
      g['total'] += amount;
      g['count'] = (g['count'] as int) + 1;
      (g['items'] as List).add(t);
    }
    _recaps = map.values.toList();
  }

  Future<void> loadTransactions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.dio.get('/payments/transactions');
      final data = (response.data['data'] as List? ?? [])
          .where((r) => r['transaction_id'] != null)
          .toList();
      _transactions = data;
      _buildRecaps();
    } catch (e) {
      _error = 'Gagal memuat riwayat pembayaran: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

class TabunganAdminProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoading = true;
  List<dynamic> _transactions = [];
  List<dynamic> _recaps = [];
  String? _error;

  bool get isLoading => _isLoading;
  List<dynamic> get transactions => _transactions;
  List<dynamic> get recaps => _recaps;
  String? get error => _error;

  /// Jumlah periode pada rekap tabungan.
  int get totalPeriode => _recaps.length;

  /// Saldo bersih seluruh periode (total setoran - total penarikan).
  int get totalBersih => totalSetoran - totalPenarikan;

  int get totalSetoran => _transactions.fold(0, (sum, t) {
    final amount = t['amount'];
    return sum + ((amount is num && (t['transaction_type'] ?? '').toString() != 'PENARIKAN') ? amount.round() : 0);
  });

  int get totalPenarikan => _transactions.fold(0, (sum, t) {
    final amount = t['amount'];
    return sum + ((amount is num && (t['transaction_type'] ?? '').toString() == 'PENARIKAN') ? amount.round() : 0);
  });

  /// Label periode untuk sebuah transaksi: prioritas nama bulan hijriah
  /// (`bulan_hijriah` + `tahun_hijriah`), fallback ke bulan Masehi (`YYYY-MM`).
  static String periodLabelOf(dynamic t) {
    final bh = (t['bulan_hijriah'] ?? '').toString().trim();
    final th = (t['tahun_hijriah'] ?? '').toString().trim();
    if (bh.isNotEmpty) return th.isNotEmpty ? '$bh $th' : bh;
    final sd = (t['saving_date'] ?? t['created_at'] ?? '').toString();
    if (sd.isNotEmpty && sd.length >= 7) return sd.substring(0, 7);
    return 'Tanpa Periode';
  }

  /// Kelompokkan transaksi per periode dan agregatkan setoran/penarikan.
  void _buildRecaps() {
    final map = <String, dynamic>{};
    for (final t in _transactions) {
      final key = periodLabelOf(t);
      if (!map.containsKey(key)) {
        map[key] = {
          'period': key,
          'setoran': 0,
          'penarikan': 0,
          'net': 0,
          'count': 0,
          'items': <dynamic>[],
        };
      }
      final g = map[key];
      final amount = (t['amount'] as num?)?.round() ?? 0;
      final isPenarikan =
          (t['transaction_type'] ?? '').toString().toUpperCase() == 'PENARIKAN';
      if (isPenarikan) {
        g['penarikan'] += amount;
        g['net'] -= amount;
      } else {
        g['setoran'] += amount;
        g['net'] += amount;
      }
      g['count'] = (g['count'] as int) + 1;
      (g['items'] as List).add(t);
    }
    // Urutkan periode berdasarkan aktivitas terbaru (urut kemunculan sudah DESC).
    _recaps = map.values.toList();
  }

  Future<void> loadTransactions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.dio.get('/savings/transactions');
      final data = (response.data['data'] as List? ?? [])
          .where((r) => r['transaction_id'] != null)
          .toList();
      _transactions = data;
      _buildRecaps();
    } catch (e) {
      _error = 'Gagal memuat riwayat tabungan: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

class PembayaranMuridProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoading = true;
  List<dynamic> _payments = [];
  String? _error;

  bool get isLoading => _isLoading;
  List<dynamic> get payments => _payments;
  String? get error => _error;

  Future<void> loadPayments({int? academicYearId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final params = <String, dynamic>{};
      if (academicYearId != null) params['academic_year_id'] = academicYearId;
      final response = await _api.dio.get('/students/me/payments', queryParameters: params);
      _payments = response.data['data']?['data'] as List? ?? [];
    } catch (e) {
      _error = 'Gagal memuat riwayat pembayaran: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

class TabunganMuridProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoading = true;
  num _balance = 0;
  List<dynamic> _history = [];
  String? _error;

  bool get isLoading => _isLoading;
  num get balance => _balance;
  List<dynamic> get history => _history;
  String? get error => _error;

  int get totalSetoran => _history
      .where((t) => (t['transaction_type'] ?? '').toString().toUpperCase() == 'SETORAN')
      .fold(0, (sum, t) => sum + ((t['amount'] as num?)?.round() ?? 0));

  int get totalPenarikan => _history
      .where((t) => (t['transaction_type'] ?? '').toString().toUpperCase() == 'PENARIKAN')
      .fold(0, (sum, t) => sum + ((t['amount'] as num?)?.round() ?? 0));

  Future<void> loadSavings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.dio.get('/students/me/savings');
      _balance = response.data['data']?['balance'] as num? ?? 0;
      _history = response.data['data']?['history'] as List? ?? [];
    } catch (e) {
      _error = 'Gagal memuat tabungan: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
