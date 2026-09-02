import '../common/enums.dart';

class Attendance {
  final int? id;
  final int studentId;
  final String sessionName;
  final AttendanceStatus status;
  final String? notes;
  final String date; // YYYY-MM-DD
  final int? teacherId;
  final String? teacherName;
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final String? createdAt;

  const Attendance({
    this.id,
    required this.studentId,
    required this.sessionName,
    required this.status,
    this.notes,
    required this.date,
    this.teacherId,
    this.teacherName,
    this.latitude,
    this.longitude,
    this.accuracy,
    this.createdAt,
  });

  factory Attendance.fromJson(Map<String, dynamic> j) => Attendance(
        id: j['id'] != null ? int.tryParse('${j['id']}') : null,
        studentId: int.tryParse('${j['student_id'] ?? 0}') ?? 0,
        sessionName: (j['session_name'] ?? 'PAGI').toString(),
        status: AttendanceStatusX.from(j['status']?.toString()),
        notes: j['notes']?.toString(),
        date: (j['date'] ?? '').toString(),
        teacherId: j['teacher_id'] != null ? int.tryParse('${j['teacher_id']}') : null,
        teacherName: j['teacher_name']?.toString(),
        latitude: j['latitude'] != null ? double.tryParse('${j['latitude']}') : null,
        longitude: j['longitude'] != null ? double.tryParse('${j['longitude']}') : null,
        accuracy: j['accuracy'] != null ? double.tryParse('${j['accuracy']}') : null,
        createdAt: j['created_at']?.toString(),
      );

  Map<String, dynamic> toPostJson({required int scheduleId}) => {
        'student_id': studentId,
        'session_name': sessionName,
        'status': status.apiValue,
        'notes': notes,
        'schedule_id': scheduleId,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (accuracy != null) 'accuracy': accuracy,
      };
}

/// Roster presensi per kelas per sesi per tanggal
class ClassAttendanceRow {
  final int? placementId;
  final String nim;
  final String studentName;
  final int? studentId;
  final String? className;
  final String sessionName;
  final AttendanceStatus? status; // null = BELUM
  final String? notes;
  final String? date;
  final int? teacherId;
  final bool alreadyAbsen;

  const ClassAttendanceRow({
    this.placementId,
    required this.nim,
    required this.studentName,
    this.studentId,
    this.className,
    required this.sessionName,
    this.status,
    this.notes,
    this.date,
    this.teacherId,
    this.alreadyAbsen = false,
  });

  factory ClassAttendanceRow.fromJson(Map<String, dynamic> j) => ClassAttendanceRow(
        placementId: j['placement_id'] != null ? int.tryParse('${j['placement_id']}') : null,
        nim: (j['nim'] ?? '').toString(),
        studentName: (j['student_name'] ?? j['name'] ?? '').toString(),
        studentId: j['student_id'] != null ? int.tryParse('${j['student_id']}') : null,
        className: j['class_name']?.toString(),
        sessionName: (j['session_name'] ?? 'PAGI').toString(),
        status: j['status'] != null ? AttendanceStatusX.from(j['status'].toString()) : null,
        notes: j['notes']?.toString(),
        date: j['date']?.toString(),
        teacherId: j['teacher_id'] != null ? int.tryParse('${j['teacher_id']}') : null,
        alreadyAbsen: (j['already_absen'] == 1 || j['already_absen'] == true),
      );

  bool get belum => status == null;
}
