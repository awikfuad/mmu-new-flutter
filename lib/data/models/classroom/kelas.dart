class Kelas {
  final int id;
  final String sumber; // madrasah | tpq
  final String className;
  final String? description;
  final int? academicYearId;
  final int? jenjangId;
  final String? yearName;
  final String? namaJenjang;

  const Kelas({
    required this.id,
    required this.sumber,
    required this.className,
    this.description,
    this.academicYearId,
    this.jenjangId,
    this.yearName,
    this.namaJenjang,
  });

  factory Kelas.fromJson(Map<String, dynamic> j) => Kelas(
        id: int.tryParse('${j['id'] ?? 0}') ?? 0,
        sumber: (j['sumber'] ?? 'madrasah').toString(),
        className: (j['class_name'] ?? j['className'] ?? '').toString(),
        description: j['description']?.toString(),
        academicYearId: j['academic_year_id'] != null ? int.tryParse('${j['academic_year_id']}') : null,
        jenjangId: j['jenjang_id'] != null ? int.tryParse('${j['jenjang_id']}') : null,
        yearName: j['year_name']?.toString(),
        namaJenjang: j['nama_jenjang']?.toString(),
      );
}

class Rombel {
  final int id;
  final String sumber;
  final int? jenjangId;
  final String namaRombel;
  const Rombel({required this.id, required this.sumber, this.jenjangId, required this.namaRombel});
  factory Rombel.fromJson(Map<String, dynamic> j) => Rombel(
        id: int.tryParse('${j['id'] ?? 0}') ?? 0,
        sumber: (j['sumber'] ?? 'madrasah').toString(),
        jenjangId: j['jenjang_id'] != null ? int.tryParse('${j['jenjang_id']}') : null,
        namaRombel: (j['nama_rombel'] ?? '').toString(),
      );
}

class Jenjang {
  final int id;
  final String namaJenjang;
  const Jenjang({required this.id, required this.namaJenjang});
  factory Jenjang.fromJson(Map<String, dynamic> j) => Jenjang(
        id: int.tryParse('${j['id'] ?? 0}') ?? 0,
        namaJenjang: (j['nama_jenjang'] ?? '').toString(),
      );
}

class AcademicYear {
  final int id;
  final String yearName;
  final String semester;
  final int isActive;
  final int isClosed;
  final String? closedAt;
  final String? closedBy;
  const AcademicYear({
    required this.id,
    required this.yearName,
    required this.semester,
    this.isActive = 0,
    this.isClosed = 0,
    this.closedAt,
    this.closedBy,
  });
  factory AcademicYear.fromJson(Map<String, dynamic> j) => AcademicYear(
        id: int.tryParse('${j['id'] ?? 0}') ?? 0,
        yearName: (j['year_name'] ?? '').toString(),
        semester: (j['semester'] ?? '').toString(),
        isActive: int.tryParse('${j['is_active'] ?? 0}') ?? 0,
        isClosed: int.tryParse('${j['is_closed'] ?? 0}') ?? 0,
        closedAt: j['closed_at']?.toString(),
        closedBy: j['closed_by']?.toString(),
      );
  bool get active => isActive == 1;
}

class Subject {
  final int id;
  final String subjectCode;
  final String subjectName;
  const Subject({required this.id, required this.subjectCode, required this.subjectName});
  factory Subject.fromJson(Map<String, dynamic> j) => Subject(
        id: int.tryParse('${j['id'] ?? 0}') ?? 0,
        subjectCode: (j['subject_code'] ?? '').toString(),
        subjectName: (j['subject_name'] ?? '').toString(),
      );
}
