class SavingsTransaction {
  final int? id; // transaction_id
  final int? studentId;
  final String? studentName;
  final String? nim;
  final String transactionType; // SETORAN | PENARIKAN
  final double amount;
  final String? notes;
  final String? bulanHijriah;
  final String? tahunHijriah;
  final String? savingDate;
  final String? createdAt;

  const SavingsTransaction({
    this.id,
    this.studentId,
    this.studentName,
    this.nim,
    required this.transactionType,
    required this.amount,
    this.notes,
    this.bulanHijriah,
    this.tahunHijriah,
    this.savingDate,
    this.createdAt,
  });

  factory SavingsTransaction.fromJson(Map<String, dynamic> j) => SavingsTransaction(
        id: j['id'] != null ? int.tryParse('${j['id']}') : (j['transaction_id'] != null ? int.tryParse('${j['transaction_id']}') : null),
        studentId: j['student_id'] != null ? int.tryParse('${j['student_id']}') : null,
        studentName: j['student_name']?.toString(),
        nim: j['nim']?.toString(),
        transactionType: (j['transaction_type'] ?? '').toString(),
        amount: double.tryParse('${j['amount'] ?? 0}') ?? 0,
        notes: j['notes']?.toString(),
        bulanHijriah: j['bulan_hijriah']?.toString(),
        tahunHijriah: j['tahun_hijriah']?.toString(),
        savingDate: j['saving_date']?.toString(),
        createdAt: j['created_at']?.toString(),
      );

  bool get isSetoran => transactionType.toUpperCase() == 'SETORAN';
}

class SavingsDashboard {
  final int? studentId;
  final double balance;
  final List<SavingsTransaction> history;
  const SavingsDashboard({this.studentId, required this.balance, required this.history});

  factory SavingsDashboard.fromJson(Map<String, dynamic> j) {
    // /savings/dashboard/:id returns {total_balance, history:[...]}
    // /students/me/savings returns {balance, history:[...]} or {data:{balance,history}}
    final data = j['data'] is Map ? Map<String, dynamic>.from(j['data'] as Map) : j;
    final bal = data['total_balance'] ?? data['balance'] ?? 0;
    final list = (data['history'] as List? ?? data['data'] as List? ?? []);
    return SavingsDashboard(
      studentId: data['student_id'] != null ? int.tryParse('${data['student_id']}') : null,
      balance: double.tryParse('$bal') ?? 0,
      history: list.whereType<Map>().map((e) => SavingsTransaction.fromJson(Map<String, dynamic>.from(e))).toList(),
    );
  }
}
