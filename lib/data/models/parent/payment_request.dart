class PaymentRequest {
  final int id;
  final int parentId;
  final String nim;
  final String sumber;
  final String paymentType; // YAUMIYAH | DAFTAR_ULANG
  final String? month;
  final double amount;
  final String status; // MENUNGGU | DISETUJUI | DITOLAK
  final String? disetujuiOleh;
  final String? adminNotes;
  final String? createdAt;

  const PaymentRequest({
    required this.id,
    required this.parentId,
    required this.nim,
    this.sumber = 'madrasah',
    required this.paymentType,
    this.month,
    required this.amount,
    this.status = 'MENUNGGU',
    this.disetujuiOleh,
    this.adminNotes,
    this.createdAt,
  });

  factory PaymentRequest.fromJson(Map<String, dynamic> j) => PaymentRequest(
        id: int.tryParse('${j['id'] ?? 0}') ?? 0,
        parentId: int.tryParse('${j['parent_id'] ?? 0}') ?? 0,
        nim: (j['nim'] ?? '').toString(),
        sumber: (j['sumber'] ?? 'madrasah').toString(),
        paymentType: (j['payment_type'] ?? '').toString(),
        month: j['month']?.toString(),
        amount: double.tryParse('${j['amount'] ?? 0}') ?? 0,
        status: (j['status'] ?? 'MENUNGGU').toString(),
        disetujuiOleh: j['disetujui_oleh']?.toString(),
        adminNotes: j['admin_notes']?.toString(),
        createdAt: j['created_at']?.toString(),
      );
}

class IzinSakit {
  final int id;
  final String? nim;
  final int? studentId;
  final String jenis; // IZIN | SAKIT
  final String alasan;
  final String tanggalMulai;
  final String tanggalSelesai;
  final String? keterangan;
  final String status; // MENUNGGU | DISETUJUI | DITOLAK | AKTIF | SELESAI (guru)
  final String? disetujuiOleh;
  final String? lembaga;
  final String? createdAt;

  const IzinSakit({
    required this.id,
    this.nim,
    this.studentId,
    required this.jenis,
    required this.alasan,
    required this.tanggalMulai,
    required this.tanggalSelesai,
    this.keterangan,
    this.status = 'MENUNGGU',
    this.disetujuiOleh,
    this.lembaga,
    this.createdAt,
  });

  factory IzinSakit.fromJson(Map<String, dynamic> j) => IzinSakit(
        id: int.tryParse('${j['id'] ?? 0}') ?? 0,
        nim: j['nim']?.toString(),
        studentId: j['student_id'] != null ? int.tryParse('${j['student_id']}') : null,
        jenis: (j['jenis'] ?? '').toString(),
        alasan: (j['alasan'] ?? '').toString(),
        tanggalMulai: (j['tanggal_mulai'] ?? '').toString(),
        tanggalSelesai: (j['tanggal_selesai'] ?? '').toString(),
        keterangan: j['keterangan']?.toString(),
        status: (j['status'] ?? 'MENUNGGU').toString(),
        disetujuiOleh: j['disetujui_oleh']?.toString(),
        lembaga: j['lembaga']?.toString(),
        createdAt: j['created_at']?.toString(),
      );
}
