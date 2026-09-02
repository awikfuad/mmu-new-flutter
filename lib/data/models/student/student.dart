import '../common/enums.dart';

/// `students` table — akun login santri (role=user)
class Student {
  final int id;
  final String nim;
  final String name;
  final Role role;
  final Lembaga lembaga;
  final int? academicYearId;
  final int? jenjangId;
  final String? tanggalLahir;
  final int? status;

  const Student({
    required this.id,
    required this.nim,
    required this.name,
    this.role = Role.user,
    this.lembaga = Lembaga.ALL,
    this.academicYearId,
    this.jenjangId,
    this.tanggalLahir,
    this.status,
  });

  factory Student.fromJson(Map<String, dynamic> j) => Student(
        id: int.tryParse('${j['id'] ?? 0}') ?? 0,
        nim: (j['nim'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        role: RoleX.from(j['role']?.toString()),
        lembaga: LembagaX.from(j['lembaga']?.toString()),
        academicYearId: j['academic_year_id'] != null ? int.tryParse('${j['academic_year_id']}') : null,
        jenjangId: j['jenjang_id'] != null ? int.tryParse('${j['jenjang_id']}') : null,
        tanggalLahir: j['tanggal_lahir']?.toString(),
        status: j['status'] != null ? int.tryParse('${j['status']}') : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nim': nim,
        'name': name,
        'role': role.apiValue,
        'lembaga': lembaga.apiValue,
        if (academicYearId != null) 'academic_year_id': academicYearId,
        if (jenjangId != null) 'jenjang_id': jenjangId,
        if (tanggalLahir != null) 'tanggal_lahir': tanggalLahir,
        if (status != null) 'status': status,
      };
}
