// ignore_for_file: constant_identifier_names

enum Lembaga { ALL, MADRASAH, TPQ }

extension LembagaX on Lembaga {
  String get apiValue => switch (this) {
        Lembaga.ALL => 'ALL',
        Lembaga.MADRASAH => 'MADRASAH',
        Lembaga.TPQ => 'TPQ',
      };

  static Lembaga from(String? raw) {
    final v = (raw ?? 'ALL').toUpperCase();
    if (v == 'MADRASAH') return Lembaga.MADRASAH;
    if (v == 'TPQ') return Lembaga.TPQ;
    return Lembaga.ALL;
  }
}

enum Role { admin, teacher, user, parent, unknown }

extension RoleX on Role {
  String get apiValue => switch (this) {
        Role.admin => 'admin',
        Role.teacher => 'teacher',
        Role.user => 'user',
        Role.parent => 'parent',
        Role.unknown => 'unknown',
      };

  static Role from(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'admin':
        return Role.admin;
      case 'teacher':
        return Role.teacher;
      case 'user':
        return Role.user;
      case 'parent':
        return Role.parent;
      default:
        return Role.unknown;
    }
  }
}

enum TransactionType { SETORAN, PENARIKAN }
enum PaymentType { YAUMIYAH, DAFTAR_ULANG }
enum PaymentMethod { CASH, TRANSFER, SALDO_TABUNGAN }
enum AttendanceStatus { HADIR, SAKIT, IZIN, ALPA, BELUM }

extension AttendanceStatusX on AttendanceStatus {
  String get apiValue => switch (this) {
        AttendanceStatus.HADIR => 'HADIR',
        AttendanceStatus.SAKIT => 'SAKIT',
        AttendanceStatus.IZIN => 'IZIN',
        AttendanceStatus.ALPA => 'ALPA',
        AttendanceStatus.BELUM => 'BELUM',
      };

  static AttendanceStatus from(String? raw) {
    final v = (raw ?? '').toUpperCase().replaceAll('ALFA', 'ALPA');
    if (v == 'HADIR') return AttendanceStatus.HADIR;
    if (v == 'SAKIT') return AttendanceStatus.SAKIT;
    if (v == 'IZIN') return AttendanceStatus.IZIN;
    if (v == 'ALPA') return AttendanceStatus.ALPA;
    return AttendanceStatus.BELUM;
  }
}
