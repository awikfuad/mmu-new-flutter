import 'attendance.dart';

class AttendanceSummary {
  final int hadir;
  final int sakit;
  final int izin;
  final int alpa;
  final int belum;
  final int sudah;
  final int total;

  const AttendanceSummary({
    this.hadir = 0,
    this.sakit = 0,
    this.izin = 0,
    this.alpa = 0,
    this.belum = 0,
    this.sudah = 0,
    required this.total,
  });

  factory AttendanceSummary.fromJson(Map<String, dynamic> j) => AttendanceSummary(
        hadir: int.tryParse('${j['hadir'] ?? 0}') ?? 0,
        sakit: int.tryParse('${j['sakit'] ?? 0}') ?? 0,
        izin: int.tryParse('${j['izin'] ?? 0}') ?? 0,
        alpa: int.tryParse('${j['alpa'] ?? 0}') ?? 0,
        belum: int.tryParse('${j['belum'] ?? 0}') ?? 0,
        sudah: int.tryParse('${j['sudah'] ?? 0}') ?? 0,
        total: int.tryParse('${j['total'] ?? 0}') ?? 0,
      );
}

class ClassAttendanceResponse {
  final List<ClassAttendanceRow> rows;
  final AttendanceSummary summary;
  final String sessionName;
  final String date;
  const ClassAttendanceResponse({
    required this.rows,
    required this.summary,
    required this.sessionName,
    required this.date,
  });

  factory ClassAttendanceResponse.fromJson(Map<String, dynamic> j) {
    final list = (j['data'] as List? ?? [])
        .map((e) => ClassAttendanceRow.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final sum = j['summary'] is Map ? AttendanceSummary.fromJson(Map<String, dynamic>.from(j['summary'] as Map)) : AttendanceSummary(total: list.length);
    return ClassAttendanceResponse(
      rows: list,
      summary: sum,
      sessionName: (j['session_name'] ?? 'PAGI').toString(),
      date: (j['date'] ?? '').toString(),
    );
  }
}
