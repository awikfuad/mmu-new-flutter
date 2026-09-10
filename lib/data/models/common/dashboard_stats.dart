class DashboardStats {
  final int totalSantri;
  final double kasTabungan;
  final double iuranTerkumpul;
  final double iuranBulanLalu;
  final double rataPresensi;
  final int kehadiranHariIni;
  final int kbmHariIni;
  final int istighosahHariIni;
  final double pemasukanKasBulanIni;
  final int totalGuru;
  final int totalKelas;
  final int totalRombel;
  final List<Map<String, dynamic>> pendapatan; // [{month, tahun, total}]
  final Map<String, int> kehadiran; // {HADIR, IZIN, SAKIT, ALPA}
  final List<Map<String, dynamic>> recentTransactions;
  final List<Map<String, dynamic>> recentTeacherAttendance;
  final List<Map<String, dynamic>> recentKbmAttendance;

  const DashboardStats({
    this.totalSantri = 0,
    this.kasTabungan = 0,
    this.iuranTerkumpul = 0,
    this.iuranBulanLalu = 0,
    this.rataPresensi = 0,
    this.kehadiranHariIni = 0,
    this.kbmHariIni = 0,
    this.istighosahHariIni = 0,
    this.pemasukanKasBulanIni = 0,
    this.totalGuru = 0,
    this.totalKelas = 0,
    this.totalRombel = 0,
    this.pendapatan = const [],
    this.kehadiran = const {},
    this.recentTransactions = const [],
    this.recentTeacherAttendance = const [],
    this.recentKbmAttendance = const [],
  });

  factory DashboardStats.fromJson(Map<String, dynamic> j) {
    final s = j['summary'] is Map ? Map<String, dynamic>.from(j['summary'] as Map) : j;
    return DashboardStats(
      totalSantri: int.tryParse('${s['totalSantri'] ?? s['total_santri'] ?? 0}') ?? 0,
      kasTabungan: double.tryParse('${s['kasTabungan'] ?? 0}') ?? 0,
      iuranTerkumpul: double.tryParse('${s['iuranTerkumpul'] ?? 0}') ?? 0,
      iuranBulanLalu: double.tryParse('${s['iuranBulanLalu'] ?? 0}') ?? 0,
      rataPresensi: double.tryParse('${s['rataPresensi'] ?? 0}') ?? 0,
      kehadiranHariIni: int.tryParse('${s['kehadiranHariIni'] ?? 0}') ?? 0,
      kbmHariIni: int.tryParse('${s['kbmHariIni'] ?? 0}') ?? 0,
      istighosahHariIni: int.tryParse('${s['istighosahHariIni'] ?? 0}') ?? 0,
      pemasukanKasBulanIni: double.tryParse('${s['pemasukanKasBulanIni'] ?? 0}') ?? 0,
      totalGuru: int.tryParse('${s['totalGuru'] ?? 0}') ?? 0,
      totalKelas: int.tryParse('${s['totalKelas'] ?? 0}') ?? 0,
      totalRombel: int.tryParse('${s['totalRombel'] ?? 0}') ?? 0,
      pendapatan: (j['pendapatan'] as List? ?? []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList(),
      kehadiran: (j['kehadiran'] as Map? ?? {}).map((k, v) => MapEntry(k.toString(), int.tryParse('$v') ?? 0)),
      recentTransactions: (j['recentTransactions'] as List? ?? []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList(),
      recentTeacherAttendance: (j['recentTeacherAttendance'] as List? ?? []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList(),
      recentKbmAttendance: (j['recentKbmAttendance'] as List? ?? []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList(),
    );
  }
}
