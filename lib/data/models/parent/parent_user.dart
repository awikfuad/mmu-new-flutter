class ParentUser {
  final int id;
  final String phone;
  final String name;
  final String role; // parent
  final String lembaga;
  final String? createdAt;
  const ParentUser({required this.id, required this.phone, required this.name, this.role = 'parent', this.lembaga = 'ALL', this.createdAt});
  factory ParentUser.fromJson(Map<String, dynamic> j) => ParentUser(
        id: int.tryParse('${j['id'] ?? 0}') ?? 0,
        phone: (j['phone'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        role: (j['role'] ?? 'parent').toString(),
        lembaga: (j['lembaga'] ?? 'ALL').toString(),
        createdAt: j['created_at']?.toString(),
      );
}

class ParentChildLink {
  final int? linkId;
  final String studentNim;
  final String sumber; // madrasah | tpq
  final String? hubungan;
  final int? muridId;
  final String? studentName;
  final int? classroomId;
  final String? className;
  final String? studentLembaga;

  const ParentChildLink({
    this.linkId,
    required this.studentNim,
    this.sumber = 'madrasah',
    this.hubungan,
    this.muridId,
    this.studentName,
    this.classroomId,
    this.className,
    this.studentLembaga,
  });

  factory ParentChildLink.fromJson(Map<String, dynamic> j) => ParentChildLink(
        linkId: j['link_id'] != null ? int.tryParse('${j['link_id']}') : (j['id'] != null ? int.tryParse('${j['id']}') : null),
        studentNim: (j['student_nim'] ?? j['nim'] ?? '').toString(),
        sumber: (j['sumber'] ?? 'madrasah').toString(),
        hubungan: j['hubungan']?.toString(),
        muridId: j['murid_id'] != null ? int.tryParse('${j['murid_id']}') : null,
        studentName: j['student_name']?.toString() ?? j['name']?.toString(),
        classroomId: j['classroom_id'] != null ? int.tryParse('${j['classroom_id']}') : null,
        className: j['class_name']?.toString(),
        studentLembaga: j['student_lembaga']?.toString() ?? j['lembaga']?.toString(),
      );
}

class ChildProfile {
  final String nim;
  final String name;
  final int? classroomId;
  final String? className;
  final int? jenjangId;
  final String? tanggalLahir;
  final String? namaAyah;
  final String? namaIbu;
  final String? namaWali;
  final String? hubunganWali;
  final String? teleponWali;
  final String? alamat;
  // ... other wali fields
  final Map<String, dynamic> raw;
  const ChildProfile({required this.nim, required this.name, this.classroomId, this.className, this.jenjangId, this.tanggalLahir, this.namaAyah, this.namaIbu, this.namaWali, this.hubunganWali, this.teleponWali, this.alamat, required this.raw});
  factory ChildProfile.fromJson(Map<String, dynamic> j) => ChildProfile(
        nim: (j['nim'] ?? j['student_nim'] ?? '').toString(),
        name: (j['name'] ?? j['student_name'] ?? '').toString(),
        classroomId: j['classroom_id'] != null ? int.tryParse('${j['classroom_id']}') : null,
        className: j['class_name']?.toString(),
        jenjangId: j['jenjang_id'] != null ? int.tryParse('${j['jenjang_id']}') : null,
        tanggalLahir: j['tanggal_lahir']?.toString(),
        namaAyah: j['nama_ayah']?.toString(),
        namaIbu: j['nama_ibu']?.toString(),
        namaWali: j['nama_wali']?.toString(),
        hubunganWali: j['hubungan_wali']?.toString(),
        teleponWali: j['telepon_wali']?.toString(),
        alamat: j['alamat']?.toString(),
        raw: j,
      );
}
