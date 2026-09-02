class KasTransaction {
  final int? id;
  final int? academicYearId;
  final String? date; // YYYY-MM-DD
  final String? accountCode;
  final String? accountName;
  final String? description;
  final String type; // MASUK | KELUAR
  final double amount;
  final String? notes;
  final String? lembaga;
  final String? postedBy;
  final String? createdAt;
  const KasTransaction({
    this.id,
    this.academicYearId,
    this.date,
    this.accountCode,
    this.accountName,
    this.description,
    required this.type,
    required this.amount,
    this.notes,
    this.lembaga,
    this.postedBy,
    this.createdAt,
  });
  factory KasTransaction.fromJson(Map<String, dynamic> j) => KasTransaction(
        id: j['id'] != null ? int.tryParse('${j['id']}') : null,
        academicYearId: j['academic_year_id'] != null ? int.tryParse('${j['academic_year_id']}') : null,
        date: j['date']?.toString(),
        accountCode: j['account_code']?.toString(),
        accountName: j['account_name']?.toString(),
        description: j['description']?.toString(),
        type: (j['type'] ?? '').toString(),
        amount: double.tryParse('${j['amount'] ?? 0}') ?? 0,
        notes: j['notes']?.toString(),
        lembaga: j['lembaga']?.toString(),
        postedBy: j['posted_by']?.toString(),
        createdAt: j['created_at']?.toString(),
      );
}

class Account {
  final int id;
  final String accountCode;
  final String accountName;
  final String accountType; // KAS | BANK | PIUTANG | PENDAPATAN | BEBAN
  final String lembaga;
  final int isSystem;
  const Account({required this.id, required this.accountCode, required this.accountName, required this.accountType, this.lembaga = 'ALL', this.isSystem = 0});
  factory Account.fromJson(Map<String, dynamic> j) => Account(
        id: int.tryParse('${j['id'] ?? 0}') ?? 0,
        accountCode: (j['account_code'] ?? '').toString(),
        accountName: (j['account_name'] ?? '').toString(),
        accountType: (j['account_type'] ?? '').toString(),
        lembaga: (j['lembaga'] ?? 'ALL').toString(),
        isSystem: int.tryParse('${j['is_system'] ?? 0}') ?? 0,
      );
}
