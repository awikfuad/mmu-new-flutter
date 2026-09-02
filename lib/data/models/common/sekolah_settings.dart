class SekolahSettings {
  final int id;
  final String namaSekolah;
  final String? alamat;
  final String? telepon;
  final String? email;
  final String? website;
  final String? logoPath;
  final String? footerText;
  final double? latitude;
  final double? longitude;
  final int geofenceRadius;
  final int geofenceEnabled;

  const SekolahSettings({
    this.id = 1,
    this.namaSekolah = 'MMU A-44',
    this.alamat,
    this.telepon,
    this.email,
    this.website,
    this.logoPath,
    this.footerText,
    this.latitude,
    this.longitude,
    this.geofenceRadius = 100,
    this.geofenceEnabled = 0,
  });

  factory SekolahSettings.fromJson(Map<String, dynamic> j) => SekolahSettings(
        id: int.tryParse('${j['id'] ?? 1}') ?? 1,
        namaSekolah: (j['nama_sekolah'] ?? 'MMU A-44').toString(),
        alamat: j['alamat']?.toString(),
        telepon: j['telepon']?.toString(),
        email: j['email']?.toString(),
        website: j['website']?.toString(),
        logoPath: j['logo_path']?.toString(),
        footerText: j['footer_text']?.toString(),
        latitude: j['latitude'] != null ? double.tryParse('${j['latitude']}') : null,
        longitude: j['longitude'] != null ? double.tryParse('${j['longitude']}') : null,
        geofenceRadius: int.tryParse('${j['geofence_radius'] ?? 100}') ?? 100,
        geofenceEnabled: int.tryParse('${j['geofence_enabled'] ?? 0}') ?? 0,
      );

  bool get geofenceActive => geofenceEnabled == 1 && latitude != null && longitude != null;
}

class Teacher {
  final int id;
  final String username;
  final String name;
  final String lembaga;
  final String? foto;
  const Teacher({required this.id, required this.username, required this.name, this.lembaga = 'ALL', this.foto});
  factory Teacher.fromJson(Map<String, dynamic> j) => Teacher(
        id: int.tryParse('${j['id'] ?? 0}') ?? 0,
        username: (j['username'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        lembaga: (j['lembaga'] ?? 'ALL').toString(),
        foto: j['foto']?.toString(),
      );
}

class InventarisAset {
  final int id;
  final String? kode;
  final String nama;
  final String? kategori;
  final int jumlah;
  final String? kondisi;
  final String? lokasi;
  final double? nilai;
  final String? tahunPengadaan;
  final String? keterangan;
  final String lembaga;
  const InventarisAset({
    required this.id,
    this.kode,
    required this.nama,
    this.kategori,
    this.jumlah = 0,
    this.kondisi,
    this.lokasi,
    this.nilai,
    this.tahunPengadaan,
    this.keterangan,
    this.lembaga = 'ALL',
  });
  factory InventarisAset.fromJson(Map<String, dynamic> j) => InventarisAset(
        id: int.tryParse('${j['id'] ?? 0}') ?? 0,
        kode: j['kode']?.toString(),
        nama: (j['nama'] ?? '').toString(),
        kategori: j['kategori']?.toString(),
        jumlah: int.tryParse('${j['jumlah'] ?? 0}') ?? 0,
        kondisi: j['kondisi']?.toString(),
        lokasi: j['lokasi']?.toString(),
        nilai: j['nilai'] != null ? double.tryParse('${j['nilai']}') : null,
        tahunPengadaan: j['tahun_pengadaan']?.toString(),
        keterangan: j['keterangan']?.toString(),
        lembaga: (j['lembaga'] ?? 'ALL').toString(),
      );
}

class WaliMurid {
  final int id;
  final int muridId;
  final String sumber;
  final String? nim;
  final String? namaAyah;
  final String? pekerjaanAyah;
  final String? namaIbu;
  final String? pekerjaanIbu;
  final String? namaWali;
  final String? hubunganWali;
  final String? teleponWali;
  final String? alamat;
  const WaliMurid({
    required this.id,
    required this.muridId,
    this.sumber = 'madrasah',
    this.nim,
    this.namaAyah,
    this.pekerjaanAyah,
    this.namaIbu,
    this.pekerjaanIbu,
    this.namaWali,
    this.hubunganWali,
    this.teleponWali,
    this.alamat,
  });
  factory WaliMurid.fromJson(Map<String, dynamic> j) => WaliMurid(
        id: int.tryParse('${j['id'] ?? 0}') ?? 0,
        muridId: int.tryParse('${j['murid_id'] ?? 0}') ?? 0,
        sumber: (j['sumber'] ?? 'madrasah').toString(),
        nim: j['nim']?.toString(),
        namaAyah: j['nama_ayah']?.toString(),
        pekerjaanAyah: j['pekerjaan_ayah']?.toString(),
        namaIbu: j['nama_ibu']?.toString(),
        pekerjaanIbu: j['pekerjaan_ibu']?.toString(),
        namaWali: j['nama_wali']?.toString(),
        hubunganWali: j['hubungan_wali']?.toString(),
        teleponWali: j['telepon_wali']?.toString(),
        alamat: j['alamat']?.toString(),
      );
}
