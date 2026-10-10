// Model data Ujian / CBT untuk portal santri (role: user).
// Dipakai oleh student_ujian_provider.dart + halaman santri.

/// Satu baris daftar ujian dari GET /students/me/ujian.
class UjianCard {
  final int ujianId;
  final String judul;
  final String jenis;
  final int durasi;
  final String? petunjuk;
  final int? subjectId;
  final String? subjectName;
  final String lembaga;
  final int? pesertaId;
  final String pesertaStatus; // BELUM | MENGERJAKAN | SELESAI
  final String? mulai;
  final String? selesai;
  final num? nilai;
  final bool tampilkanHasil;

  const UjianCard({
    required this.ujianId,
    required this.judul,
    required this.jenis,
    required this.durasi,
    this.petunjuk,
    this.subjectId,
    this.subjectName,
    required this.lembaga,
    this.pesertaId,
    required this.pesertaStatus,
    this.mulai,
    this.selesai,
    this.nilai,
    required this.tampilkanHasil,
  });

  factory UjianCard.fromJson(Map<String, dynamic> json) {
    return UjianCard(
      ujianId: _toInt(json['ujian_id']),
      judul: json['judul']?.toString() ?? 'Ujian',
      jenis: json['jenis']?.toString() ?? 'ULANGAN',
      durasi: _toInt(json['durasi']),
      petunjuk: json['petunjuk']?.toString(),
      subjectId: _toIntNullable(json['subject_id']),
      subjectName: json['subject_name']?.toString(),
      lembaga: json['lembaga']?.toString() ?? 'ALL',
      pesertaId: _toIntNullable(json['peserta_id']),
      pesertaStatus: json['peserta_status']?.toString() ?? 'BELUM',
      mulai: json['mulai']?.toString(),
      selesai: json['selesai']?.toString(),
      nilai: json['nilai'] == null ? null : _toNum(json['nilai']),
      tampilkanHasil: json['tampilkan_hasil']?.toString() == '1' ||
          json['tampilkan_hasil'] == true,
    );
  }

  bool get bisaDikerjakan =>
      pesertaStatus == 'BELUM' || pesertaStatus == 'MENGERJAKAN';
}

/// Sesi ujian yang sedang/akan dikerjakan (hasil POST /public/ujian/start).
class SesiUjian {
  final Map<String, dynamic> ujian;
  final Map<String, dynamic> peserta;
  final List<Map<String, dynamic>> soal;
  final Map<String, dynamic> jawabanSebelum;

  const SesiUjian({
    required this.ujian,
    required this.peserta,
    required this.soal,
    required this.jawabanSebelum,
  });

  factory SesiUjian.fromJson(Map<String, dynamic> json) {
    return SesiUjian(
      ujian: (json['ujian'] as Map?)?.cast<String, dynamic>() ?? const {},
      peserta: (json['peserta'] as Map?)?.cast<String, dynamic>() ?? const {},
      soal: _listMaps(json['soal']),
      jawabanSebelum:
          (json['jawaban_sebelum'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }

  int get ujianId => _toInt(ujian['id']);
  String get judul => ujian['judul']?.toString() ?? 'Ujian';
  String get jenis => ujian['jenis']?.toString() ?? 'ULANGAN';
  int get durasi => _toInt(ujian['durasi']); // menit; 0 = tanpa batas
  String? get petunjuk => ujian['petunjuk']?.toString();
  bool get acakSoal => ujian['acak_soal']?.toString() == '1' || ujian['acak_soal'] == true;
  bool get acakOpsi => ujian['acak_opsi']?.toString() == '1' || ujian['acak_opsi'] == true;
  bool get tampilkanHasil =>
      ujian['tampilkan_hasil']?.toString() == '1' || ujian['tampilkan_hasil'] == true;
  int get jumlahSoal => _toInt(ujian['jumlah_soal']);
  int? get sisaWaktu => ujian['sisa_waktu'] == null
      ? null
      : _toIntNullable(ujian['sisa_waktu']); // detik

  int get pesertaId => _toInt(peserta['id']);
  String get pesertaNim => peserta['nim']?.toString() ?? '';
  String get pesertaName => peserta['name']?.toString() ?? '';

  /// Waktu mulai (string server `YYYY-MM-DD HH:MM:SS`, zona lokal server).
  /// deadline = mulai + durasi menit. null bila tidak diketahui.
  DateTime? get _mulai {
    final raw = peserta['mulai']?.toString();
    return raw == null || raw.isEmpty ? null : DateTime.tryParse(raw);
  }

  DateTime? get deadline {
    final m = _mulai;
    if (m == null || durasi <= 0) return null;
    return m.add(Duration(minutes: durasi));
  }

  Duration? get sisaDurasiNow {
    final d = deadline;
    if (d == null) return null;
    final sisa = d.difference(DateTime.now());
    return sisa.isNegative ? Duration.zero : sisa;
  }
}

/// Hasil submit (POST /public/ujian/submit).
class HasilUjian {
  final int? nilai;
  final bool adaEsai;
  final int totalSoal;
  final int dijawab;
  final int benar;
  final int salah;
  final int kosong;
  final bool tampilkanHasil;
  final List<Map<String, dynamic>> detail;

  const HasilUjian({
    this.nilai,
    required this.adaEsai,
    required this.totalSoal,
    required this.dijawab,
    required this.benar,
    required this.salah,
    required this.kosong,
    required this.tampilkanHasil,
    this.detail = const [],
  });

  factory HasilUjian.fromJson(Map<String, dynamic> json) {
    return HasilUjian(
      nilai: json['nilai'] == null ? null : _toNum(json['nilai']).toInt(),
      adaEsai: json['ada_esai'] == true,
      totalSoal: _toInt(json['total_soal']),
      dijawab: _toInt(json['dijawab']),
      benar: _toInt(json['benar']),
      salah: _toInt(json['salah']),
      kosong: _toInt(json['kosong']),
      tampilkanHasil: json['tampilkan_hasil'] == true,
      detail: _listMaps(json['detail']),
    );
  }
}

int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

int? _toIntNullable(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

num _toNum(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v;
  return num.tryParse(v.toString()) ?? 0;
}

List<Map<String, dynamic>> _listMaps(dynamic v) {
  if (v is! List) return const [];
  return v
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
}