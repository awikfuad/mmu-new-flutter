class Schedule {
  final int scheduleId;
  final int classroomId;
  final String subjectName;
  final String dayOfWeek; // SENIN..AHAD
  final String startTime; // HH:MM
  final String endTime;
  final String sessionName; // PAGI/SIANG...
  final String? className;
  final int? teacherId;
  final String? mainTeacherName;
  final int? substituteTeacherId;
  final String? substituteTeacherName;
  final String teachingStatus; // UTAMA | PIKET
  final String? lembaga;
  final int? academicYearId;
  final int? jenjangId;
  final int? rombelId;

  const Schedule({
    required this.scheduleId,
    required this.classroomId,
    required this.subjectName,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.sessionName,
    this.className,
    this.teacherId,
    this.mainTeacherName,
    this.substituteTeacherId,
    this.substituteTeacherName,
    this.teachingStatus = 'UTAMA',
    this.lembaga,
    this.academicYearId,
    this.jenjangId,
    this.rombelId,
  });

  bool get isPiket => teachingStatus.toUpperCase() == 'PIKET';

  factory Schedule.fromJson(Map<String, dynamic> j) => Schedule(
        scheduleId: int.tryParse('${j['schedule_id'] ?? j['id'] ?? 0}') ?? 0,
        classroomId: int.tryParse('${j['classroom_id'] ?? 0}') ?? 0,
        subjectName: (j['subject_name'] ?? '').toString(),
        dayOfWeek: (j['day_of_week'] ?? '').toString(),
        startTime: (j['start_time'] ?? '').toString(),
        endTime: (j['end_time'] ?? '').toString(),
        sessionName: (j['session_name'] ?? 'PAGI').toString(),
        className: j['class_name']?.toString(),
        teacherId: j['teacher_id'] != null ? int.tryParse('${j['teacher_id']}') : (j['main_teacher_id'] != null ? int.tryParse('${j['main_teacher_id']}') : null),
        mainTeacherName: j['main_teacher_name']?.toString() ?? j['teacher_name']?.toString(),
        substituteTeacherId: j['substitute_teacher_id'] != null ? int.tryParse('${j['substitute_teacher_id']}') : null,
        substituteTeacherName: j['substitute_teacher_name']?.toString(),
        teachingStatus: (j['teaching_status'] ?? 'UTAMA').toString(),
        lembaga: j['lembaga']?.toString(),
        academicYearId: j['academic_year_id'] != null ? int.tryParse('${j['academic_year_id']}') : null,
        jenjangId: j['jenjang_id'] != null ? int.tryParse('${j['jenjang_id']}') : null,
        rombelId: j['rombel_id'] != null ? int.tryParse('${j['rombel_id']}') : null,
      );

  static List<Schedule> listFromJson(dynamic data) {
    if (data is List) return data.map((e) => Schedule.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    return [];
  }
}
