class NilaiHarian {
  final int id;
  final int? subjectId;
  final String subjectName;
  final String subjectCode;
  final String tanggal; // YYYY-MM-DD
  final double nilai; // 0-100
  final String? keterangan;

  const NilaiHarian({
    required this.id,
    this.subjectId,
    this.subjectName = '',
    this.subjectCode = '',
    required this.tanggal,
    required this.nilai,
    this.keterangan,
  });

  factory NilaiHarian.fromJson(Map<String, dynamic> j) => NilaiHarian(
        id: int.tryParse('${j['id'] ?? 0}') ?? 0,
        subjectId: j['subject_id'] != null ? int.tryParse('${j['subject_id']}') : null,
        subjectName: (j['subject_name'] ?? '').toString(),
        subjectCode: (j['subject_code'] ?? '').toString(),
        tanggal: (j['tanggal'] ?? '').toString(),
        nilai: double.tryParse('${j['nilai'] ?? 0}') ?? 0,
        keterangan: j['keterangan']?.toString(),
      );
}

class PerilakuMurid {
  final int id;
  final String tanggal;
  final String? kerajinan; // SANGAT_BAIK/BAIK/CUKUP/KURANG
  final String? kedisiplinan;
  final String? kebersihan;
  final String? catatan;
  const PerilakuMurid({required this.id, required this.tanggal, this.kerajinan, this.kedisiplinan, this.kebersihan, this.catatan});
  factory PerilakuMurid.fromJson(Map<String, dynamic> j) => PerilakuMurid(
        id: int.tryParse('${j['id'] ?? 0}') ?? 0,
        tanggal: (j['tanggal'] ?? '').toString(),
        kerajinan: j['kerajinan']?.toString(),
        kedisiplinan: j['kedisiplinan']?.toString(),
        kebersihan: j['kebersihan']?.toString(),
        catatan: j['catatan']?.toString(),
      );
}

class PrestasiPelanggaran {
  final int id;
  final String tipe; // PRESTASI | PELANGGARAN
  final String? kategori;
  final String deskripsi;
  final int? poin;
  final String? catatan;
  final String tanggal;
  const PrestasiPelanggaran({required this.id, required this.tipe, this.kategori, required this.deskripsi, this.poin, this.catatan, required this.tanggal});
  factory PrestasiPelanggaran.fromJson(Map<String, dynamic> j) => PrestasiPelanggaran(
        id: int.tryParse('${j['id'] ?? 0}') ?? 0,
        tipe: (j['tipe'] ?? '').toString(),
        kategori: j['kategori']?.toString(),
        deskripsi: (j['deskripsi'] ?? '').toString(),
        poin: j['poin'] != null ? int.tryParse('${j['poin']}') : null,
        catatan: j['catatan']?.toString(),
        tanggal: (j['tanggal'] ?? '').toString(),
      );
  bool get isPrestasi => tipe == 'PRESTASI';
}
