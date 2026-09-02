import 'dart:convert';

class SalaryTariff {
  final int id;
  final int jenjangId;
  final String lembaga;
  final double nominal;

  const SalaryTariff({
    required this.id,
    required this.jenjangId,
    required this.lembaga,
    required this.nominal,
  });

  factory SalaryTariff.fromJson(Map<String, dynamic> j) => SalaryTariff(
        id: int.tryParse('${j['id'] ?? 0}') ?? 0,
        jenjangId: int.tryParse('${j['jenjang_id'] ?? 0}') ?? 0,
        lembaga: (j['lembaga'] ?? 'ALL').toString(),
        nominal: double.tryParse('${j['nominal'] ?? 0}') ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'jenjang_id': jenjangId,
        'lembaga': lembaga,
        'nominal': nominal,
      };
}

class TunjanganDetail {
  final String nama;
  final double nominal;

  const TunjanganDetail({
    required this.nama,
    required this.nominal,
  });

  factory TunjanganDetail.fromJson(Map<String, dynamic> j) => TunjanganDetail(
        nama: (j['nama'] ?? '').toString(),
        nominal: double.tryParse('${j['nominal'] ?? 0}') ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'nama': nama,
        'nominal': nominal,
      };
}

class SalaryBreakdown {
  final int? jenjangId;
  final String? namaJenjang;
  final double jam;
  final double tarif;
  final double subtotal;

  const SalaryBreakdown({
    this.jenjangId,
    this.namaJenjang,
    required this.jam,
    required this.tarif,
    required this.subtotal,
  });

  factory SalaryBreakdown.fromJson(Map<String, dynamic> j) => SalaryBreakdown(
        jenjangId: j['jenjang_id'] != null ? int.tryParse('${j['jenjang_id']}') : null,
        namaJenjang: j['nama_jenjang']?.toString(),
        jam: double.tryParse('${j['jam'] ?? 0}') ?? 0,
        tarif: double.tryParse('${j['tarif'] ?? 0}') ?? 0,
        subtotal: double.tryParse('${j['subtotal'] ?? 0}') ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'jenjang_id': jenjangId,
        'nama_jenjang': namaJenjang,
        'jam': jam,
        'tarif': tarif,
        'subtotal': subtotal,
      };
}

class TeacherSalary {
  final int id;
  final int teacherId;
  final String period; // YYYY-MM
  final double jamMengajar;
  final double subtotalMengajar;
  final double tunjangan;
  final List<TunjanganDetail> tunjanganDetail;
  final double total;
  final String status; // DRAFT | DIBAYAR
  final String? paidAt;
  final List<SalaryBreakdown> breakdown;
  final String? notes;
  final String? lembaga;

  const TeacherSalary({
    required this.id,
    required this.teacherId,
    required this.period,
    this.jamMengajar = 0,
    this.subtotalMengajar = 0,
    this.tunjangan = 0,
    this.tunjanganDetail = const [],
    this.total = 0,
    this.status = 'DRAFT',
    this.paidAt,
    this.breakdown = const [],
    this.notes,
    this.lembaga,
  });

  factory TeacherSalary.fromJson(Map<String, dynamic> j) {
    // 1. Parsing Detail Tunjangan
    List<TunjanganDetail> tunj = [];
    final rawTunj = j['tunjangan_detail'];

    if (rawTunj is List) {
      tunj = rawTunj
          .map((e) => TunjanganDetail.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } else if (rawTunj is String && rawTunj.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawTunj);
        if (decoded is List) {
          tunj = decoded
              .map((e) => TunjanganDetail.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
        }
      } catch (_) {
        // Fallback jika format string JSON tidak valid
      }
    }

    // 2. Parsing Detail Breakdown
    List<SalaryBreakdown> bd = [];
    final rawDetail = j['detail'];

    if (rawDetail is Map && rawDetail['breakdown'] is List) {
      bd = (rawDetail['breakdown'] as List)
          .map((e) => SalaryBreakdown.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } else if (rawDetail is List) {
      bd = rawDetail
          .map((e) => SalaryBreakdown.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }

    return TeacherSalary(
      id: int.tryParse('${j['id'] ?? 0}') ?? 0,
      teacherId: int.tryParse('${j['teacher_id'] ?? 0}') ?? 0,
      period: (j['period'] ?? '').toString(),
      jamMengajar: double.tryParse('${j['jam_mengajar'] ?? 0}') ?? 0,
      subtotalMengajar: double.tryParse('${j['subtotal_mengajar'] ?? 0}') ?? 0,
      tunjangan: double.tryParse('${j['tunjangan'] ?? 0}') ?? 0,
      tunjanganDetail: tunj,
      total: double.tryParse('${j['total'] ?? 0}') ?? 0,
      status: (j['status'] ?? 'DRAFT').toString(),
      paidAt: j['paid_at']?.toString(),
      breakdown: bd,
      notes: j['notes']?.toString(),
      lembaga: j['lembaga']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'teacher_id': teacherId,
        'period': period,
        'jam_mengajar': jamMengajar,
        'subtotal_mengajar': subtotalMengajar,
        'tunjangan': tunjangan,
        'tunjangan_detail': tunjanganDetail.map((e) => e.toJson()).toList(),
        'total': total,
        'status': status,
        'paid_at': paidAt,
        'detail': {
          'breakdown': breakdown.map((e) => e.toJson()).toList(),
        },
        'notes': notes,
        'lembaga': lembaga,
      };

  bool get isDraft => status == 'DRAFT';
  bool get isDibayar => status == 'DIBAYAR';
}