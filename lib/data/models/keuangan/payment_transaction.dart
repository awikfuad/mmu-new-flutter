class PaymentTransaction {
  final int? id; // transaction_id
  final int? studentId;
  final String? studentName;
  final String? nim;
  final String paymentType; // YAUMIYAH | DAFTAR_ULANG
  final String? month;
  final double amount;
  final String paymentMethod; // CASH | TRANSFER | SALDO_TABUNGAN
  final String? transferNote;
  final String? transferProof;
  final String? createdAt;
  final String? paymentDate;

  const PaymentTransaction({
    this.id,
    this.studentId,
    this.studentName,
    this.nim,
    required this.paymentType,
    this.month,
    required this.amount,
    this.paymentMethod = 'CASH',
    this.transferNote,
    this.transferProof,
    this.createdAt,
    this.paymentDate,
  });

  factory PaymentTransaction.fromJson(Map<String, dynamic> j) => PaymentTransaction(
        id: j['id'] != null ? int.tryParse('${j['id']}') : (j['transaction_id'] != null ? int.tryParse('${j['transaction_id']}') : null),
        studentId: j['student_id'] != null ? int.tryParse('${j['student_id']}') : null,
        studentName: j['student_name']?.toString(),
        nim: j['nim']?.toString(),
        paymentType: (j['payment_type'] ?? '').toString(),
        month: j['month']?.toString(),
        amount: double.tryParse('${j['amount'] ?? 0}') ?? 0,
        paymentMethod: (j['payment_method'] ?? 'CASH').toString(),
        transferNote: j['transfer_note']?.toString(),
        transferProof: j['transfer_proof']?.toString(),
        createdAt: j['created_at']?.toString(),
        paymentDate: j['payment_date']?.toString() ?? j['created_at']?.toString(),
      );

  // For admin list where LEFT JOIN gives many null rows, filter by id != null in provider
}

class PaymentSetting {
  final int id;
  final int academicYearId;
  final String paymentType;
  final String lembaga;
  final double nominal;
  final String? yearName;
  const PaymentSetting({required this.id, required this.academicYearId, required this.paymentType, required this.lembaga, required this.nominal, this.yearName});
  factory PaymentSetting.fromJson(Map<String, dynamic> j) => PaymentSetting(
        id: int.tryParse('${j['id'] ?? 0}') ?? 0,
        academicYearId: int.tryParse('${j['academic_year_id'] ?? 0}') ?? 0,
        paymentType: (j['payment_type'] ?? '').toString(),
        lembaga: (j['lembaga'] ?? 'ALL').toString(),
        nominal: double.tryParse('${j['nominal'] ?? 0}') ?? 0,
        yearName: j['year_name']?.toString(),
      );
}
