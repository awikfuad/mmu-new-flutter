class Kegiatan {
  final int id;
  final String activityName;
  final String activityDate; // YYYY-MM-DD
  final String? description;
  final String lembaga; // ALL | MADRASAH | TPQ
  final String target; // SEMUA | MURID | GURU
  final List<int> targetJenjang;
  final String? createdAt;

  const Kegiatan({
    required this.id,
    required this.activityName,
    required this.activityDate,
    this.description,
    this.lembaga = 'ALL',
    this.target = 'SEMUA',
    this.targetJenjang = const [],
    this.createdAt,
  });

  factory Kegiatan.fromJson(Map<String, dynamic> j) {
    List<int> jenjang = [];
    final raw = j['target_jenjang'];
    if (raw is List) {
      jenjang = raw.map((e) => int.tryParse('$e') ?? 0).where((e) => e != 0).toList();
    } else if (raw is String && raw.isNotEmpty) {
      try {
        jenjang = RegExp(r'\d+').allMatches(raw).map((m) => int.parse(m.group(0)!)).toList();
      } catch (_) {}
    }
    // also support target_jenjang_list from provider decorator
    if (j['target_jenjang_list'] is List) {
      jenjang = (j['target_jenjang_list'] as List).map((e) => int.tryParse('$e') ?? 0).where((e) => e != 0).toList();
    }
    return Kegiatan(
      id: int.tryParse('${j['id'] ?? 0}') ?? 0,
      activityName: (j['activity_name'] ?? '').toString(),
      activityDate: (j['activity_date'] ?? '').toString(),
      description: j['description']?.toString(),
      lembaga: (j['lembaga'] ?? 'ALL').toString(),
      target: (j['target'] ?? 'SEMUA').toString(),
      targetJenjang: jenjang,
      createdAt: j['created_at']?.toString(),
    );
  }

  bool get isForMurid => target == 'MURID' || target == 'SEMUA';
  bool get isForGuru => target == 'GURU' || target == 'SEMUA';
}

class KegiatanAttendanceRow {
  final String nim;
  final String studentName;
  final String? className;
  final String? namaJenjang;
  final String status; // HADIR/SAKIT/IZIN/ALPA
  final String? notes;
  final String sumber;

  const KegiatanAttendanceRow({
    required this.nim,
    required this.studentName,
    this.className,
    this.namaJenjang,
    required this.status,
    this.notes,
    this.sumber = 'madrasah',
  });

  factory KegiatanAttendanceRow.fromJson(Map<String, dynamic> j) => KegiatanAttendanceRow(
        nim: (j['nim'] ?? '').toString(),
        studentName: (j['student_name'] ?? '').toString(),
        className: j['class_name']?.toString(),
        namaJenjang: j['nama_jenjang']?.toString(),
        status: (j['status'] ?? 'ALPA').toString(),
        notes: j['notes']?.toString(),
        sumber: (j['sumber'] ?? 'madrasah').toString(),
      );
}

class KegiatanTeacherRow {
  final int teacherId;
  final String username;
  final String name;
  final String status;
  final String? notes;
  const KegiatanTeacherRow({required this.teacherId, required this.username, required this.name, required this.status, this.notes});
  factory KegiatanTeacherRow.fromJson(Map<String, dynamic> j) => KegiatanTeacherRow(
        teacherId: int.tryParse('${j['teacher_id'] ?? 0}') ?? 0,
        username: (j['username'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        status: (j['status'] ?? 'ALPA').toString(),
        notes: j['notes']?.toString(),
      );
}
