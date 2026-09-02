class SantriBiodata {
  final int? id;
  final String sumber;
  final String? nim;
  final String? nama;
  final String? kelas;
  final String? jenisKelamin;
  final String? nik;
  final String? kk;
  final String? tanggalLahir;
  final String? foto;
  final String? tempat;
  final String? wali;
  final String? dusun;
  final String? desa;
  final String? kecamatan;
  final String? kabupaten;
  final String? tahunMasuk;

  const SantriBiodata({
    this.id,
    this.sumber = 'madrasah',
    this.nim,
    this.nama,
    this.kelas,
    this.jenisKelamin,
    this.nik,
    this.kk,
    this.tanggalLahir,
    this.foto,
    this.tempat,
    this.wali,
    this.dusun,
    this.desa,
    this.kecamatan,
    this.kabupaten,
    this.tahunMasuk,
  });

  factory SantriBiodata.fromJson(Map<String, dynamic> j) => SantriBiodata(
        id: j['id'] != null ? int.tryParse('${j['id']}') : null,
        sumber: (j['sumber'] ?? 'madrasah').toString(),
        nim: j['nim']?.toString(),
        nama: j['nama']?.toString(),
        kelas: j['kelas']?.toString(),
        jenisKelamin: j['jenis_kelamin']?.toString(),
        nik: j['nik']?.toString(),
        kk: j['kk']?.toString(),
        tanggalLahir: j['tanggal_lahir']?.toString(),
        foto: j['foto']?.toString(),
        tempat: j['tempat']?.toString(),
        wali: j['wali']?.toString(),
        dusun: j['dusun']?.toString(),
        desa: j['desa']?.toString(),
        kecamatan: j['kecamatan']?.toString(),
        kabupaten: j['kabupaten']?.toString(),
        tahunMasuk: j['tahun_masuk']?.toString(),
      );
}
