class KalenderPendidikan {
  final int id;
  final int? academicYearId;
  final String? yearName;
  final String semester; // GANJIL | GENAP
  final String kategori; // EFEKTIF | LIBUR | UJIAN | KEGIATAN
  final String judul;
  final String tanggalMulai;
  final String tanggalSelesai;
  final String? hijriyahMulai;
  final String? hijriyahSelesai;
  final String? keterangan;
  final String lembaga;
  const KalenderPendidikan({
    required this.id,
    this.academicYearId,
    this.yearName,
    this.semester = 'GANJIL',
    this.kategori = 'KEGIATAN',
    required this.judul,
    required this.tanggalMulai,
    required this.tanggalSelesai,
    this.hijriyahMulai,
    this.hijriyahSelesai,
    this.keterangan,
    this.lembaga = 'ALL',
  });
  factory KalenderPendidikan.fromJson(Map<String, dynamic> j) => KalenderPendidikan(
        id: int.tryParse('${j['id'] ?? 0}') ?? 0,
        academicYearId: j['academic_year_id'] != null ? int.tryParse('${j['academic_year_id']}') : null,
        yearName: j['year_name']?.toString(),
        semester: (j['semester'] ?? 'GANJIL').toString(),
        kategori: (j['kategori'] ?? 'KEGIATAN').toString(),
        judul: (j['judul'] ?? '').toString(),
        tanggalMulai: (j['tanggal_mulai'] ?? '').toString(),
        tanggalSelesai: (j['tanggal_selesai'] ?? '').toString(),
        hijriyahMulai: j['hijriyah_mulai']?.toString(),
        hijriyahSelesai: j['hijriyah_selesai']?.toString(),
        keterangan: j['keterangan']?.toString(),
        lembaga: (j['lembaga'] ?? 'ALL').toString(),
      );
}

class Pengumuman {
  final int id;
  final String judul;
  final String isi;
  final String kategori; // UMUM | AKADEMIK | KEUANGAN | KEGIATAN
  final String tanggalMulai;
  final String? tanggalSelesai;
  final int isPublished;
  final String? tanggalPublish;
  final String lembaga;
  final String? dibuatOleh;
  const Pengumuman({
    required this.id,
    required this.judul,
    required this.isi,
    this.kategori = 'UMUM',
    required this.tanggalMulai,
    this.tanggalSelesai,
    this.isPublished = 0,
    this.tanggalPublish,
    this.lembaga = 'ALL',
    this.dibuatOleh,
  });
  factory Pengumuman.fromJson(Map<String, dynamic> j) => Pengumuman(
        id: int.tryParse('${j['id'] ?? 0}') ?? 0,
        judul: (j['judul'] ?? '').toString(),
        isi: (j['isi'] ?? '').toString(),
        kategori: (j['kategori'] ?? 'UMUM').toString(),
        tanggalMulai: (j['tanggal_mulai'] ?? '').toString(),
        tanggalSelesai: j['tanggal_selesai']?.toString(),
        isPublished: int.tryParse('${j['is_published'] ?? 0}') ?? 0,
        tanggalPublish: j['tanggal_publish']?.toString(),
        lembaga: (j['lembaga'] ?? 'ALL').toString(),
        dibuatOleh: j['dibuat_oleh']?.toString(),
      );
  bool get published => isPublished == 1;
}
