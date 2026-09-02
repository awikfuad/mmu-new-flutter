import '../common/enums.dart';

/// `santri_penempatan` — gabungan murid_kelas + santri_kelas, sumber = madrasah|tpq
class SantriPenempatan {
  final int id;
  final String sumber; // 'madrasah' | 'tpq'
  final String nim;
  final String name;
  final int? studentId; // students.id link
  final int? academicYearId;
  final int? jenjangId;
  final int? classroomId;
  final int? rombelId;
  final String? jenisKelamin;
  final int status; // 1 aktif
  final String? yearName;
  final String? namaJenjang;
  final String? namaRombel;
  final String? className;
  // biodata join
  final String? nik;
  final String? kk;
  final String? foto;
  final String? tanggalLahir;

  const SantriPenempatan({
    required this.id,
    required this.sumber,
    required this.nim,
    required this.name,
    this.studentId,
    this.academicYearId,
    this.jenjangId,
    this.classroomId,
    this.rombelId,
    this.jenisKelamin,
    this.status = 1,
    this.yearName,
    this.namaJenjang,
    this.namaRombel,
    this.className,
    this.nik,
    this.kk,
    this.foto,
    this.tanggalLahir,
  });

  Lembaga get lembaga => sumber == 'tpq' ? Lembaga.TPQ : Lembaga.MADRASAH;

  factory SantriPenempatan.fromJson(Map<String, dynamic> j) => SantriPenempatan(
        id: int.tryParse('${j['id'] ?? 0}') ?? 0,
        sumber: (j['sumber'] ?? 'madrasah').toString(),
        nim: (j['nim'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        studentId: j['student_id'] != null ? int.tryParse('${j['student_id']}') : null,
        academicYearId: j['academic_year_id'] != null ? int.tryParse('${j['academic_year_id']}') : null,
        jenjangId: j['jenjang_id'] != null ? int.tryParse('${j['jenjang_id']}') : null,
        classroomId: j['classroom_id'] != null ? int.tryParse('${j['classroom_id']}') : null,
        rombelId: j['rombel_id'] != null ? int.tryParse('${j['rombel_id']}') : null,
        jenisKelamin: j['jenis_kelamin']?.toString(),
        status: int.tryParse('${j['status'] ?? 1}') ?? 1,
        yearName: j['year_name']?.toString(),
        namaJenjang: j['nama_jenjang']?.toString(),
        namaRombel: j['nama_rombel']?.toString(),
        className: j['class_name']?.toString(),
        nik: j['nik']?.toString(),
        kk: j['kk']?.toString(),
        foto: j['foto']?.toString(),
        tanggalLahir: j['tanggal_lahir']?.toString(),
      );
}
