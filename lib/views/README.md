# Views — Struktur per Role

Folder `lib/views` dikelompokkan per role agar perawatan mudah (1 role = 1 folder).

```
lib/views/
├── auth/        # Publik — belum login
│   └── login_page.dart          // Segmented Guru/Santri/Wali → AuthProvider
├── common/      # Shell bersama
│   └── main_navigation_wrapper.dart // BottomNavigation guru/admin (Beranda, Riwayat Guru, Siswa)
├── guru/        # Role admin & teacher (E-Presensi Asatidz)
│   ├── dashboard_page.dart
│   ├── presensi_saya_page.dart + presensi_kelas_page.dart
│   ├── guru_piket_page.dart
│   ├── kegiatan_non_akademik_page.dart + presensi_kegiatan_detail_page.dart
│   ├── kegiatan_internal_guru_page.dart + presensi_kegiatan_guru_detail_page.dart
│   ├── riwayat_absensi_guru_page.dart + riwayat_absensi_murid_page.dart
│   ├── scan_istighosah_page.dart
│   ├── gaji_guru_page.dart
│   ├── pembayaran_page.dart       // admin only
│   └── tabungan_page.dart         // admin only
├── santri/      # Role user (Santri)
│   ├── student_dashboard_page.dart
│   ├── absensi_kbm_murid_page.dart
│   ├── absensi_kegiatan_murid_page.dart
│   ├── pembayaran_murid_page.dart
│   ├── tabungan_murid_page.dart
│   ├── student_jadwal_page.dart
│   ├── student_kalender_page.dart
│   ├── student_perilaku_page.dart
│   └── student_prestasi_page.dart
└── parent/      # Role parent (Wali)
    ├── parent_dashboard_page.dart
    └── parent_child_detail_page.dart
```

## Aturan
- **Import antar-role dilarang** kecuali via `main.dart` (AuthGate). Contoh: halaman `santri/` tidak boleh import `guru/`.
- **Import dalam role** pakai nama file langsung (`import 'gaji_guru_page.dart'`).
- **Import ke providers/data/widgets** dari subfolder pakai `../../providers/...` (2 level).
- **Barrel per role** tersedia: `views/auth/auth.dart`, `views/guru/guru.dart`, `views/santri/santri.dart`, `views/parent/parent.dart`, `views/common/common.dart`. Atau `views/views.dart` untuk semua.
- `lib/main.dart` adalah satu-satunya yang routing berdasarkan `AuthProvider.isStudent/isParent/isAdmin`.

## Menambah Halaman Baru
1. Letakkan file di folder sesuai role (`guru| santri | parent`).
2. Tambahkan export di `guru/guru.dart` (atau barrel role terkait).
3. Daftarkan route/navigation di `dashboard_page.dart` (guru) atau `student_dashboard_page.dart` (santri) atau `parent_dashboard_page.dart`.

## Catatan Maintenance
- `lib/controllers/auth_controller.dart` deprecated — pakai `providers/auth_provider.dart`.
- `lib/data/api/api_service.dart` singleton — jangan `ApiService()` per provider tanpa factory.
