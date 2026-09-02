# Models — `lib/data/models`

Typed Dart models untuk semua endpoint `https://mmu-new-backend.vercel.app/api` (fallback `http://localhost:5000/api`). Menggantikan `Map<String,dynamic>` / `List<dynamic>` di `lib/providers/*.dart`.

## Struktur

```
lib/data/models/
├── common/
│   ├── api_response.dart   # ApiResponse<T> generic wrapper {success,message,data,count}
│   ├── enums.dart          # Lembaga, Role, AttendanceStatus, TransactionType, PaymentType, PaymentMethod
│   ├── dashboard_stats.dart# DashboardStats from GET /dashboard/stats
│   └── sekolah_settings.dart # SekolahSettings, Teacher, InventarisAset, WaliMurid
├── auth/
│   ├── auth_user.dart      # AuthUser (admin/teacher/user/parent) + Role/Lembaga helpers
│   └── login_response.dart # LoginResponse, RefreshResponse
├── student/
│   ├── student.dart        # students (akun login)
│   ├── santri_penempatan.dart # santri_penempatan (placement) + join biodata
│   └── santri_biodata.dart # santri_biodata
├── classroom/
│   └── kelas.dart          # Kelas, Rombel, Jenjang, AcademicYear, Subject
├── schedule/
│   └── schedule.dart       # Schedule (GET /today, /schedules/today-all, /schedulesAll/:tahun)
├── attendance/
│   ├── attendance.dart         # Attendance + ClassAttendanceRow
│   └── attendance_summary.dart # AttendanceSummary + ClassAttendanceResponse
├── kegiatan/
│   └── kegiatan.dart       # Kegiatan + KegiatanAttendanceRow + KegiatanTeacherRow
├── keuangan/
│   ├── payment_transaction.dart # PaymentTransaction + PaymentSetting
│   ├── savings_transaction.dart # SavingsTransaction + SavingsDashboard
│   └── kas_transaction.dart     # KasTransaction + Account
├── parent/
│   ├── parent_user.dart    # ParentUser + ParentChildLink + ChildProfile
│   └── payment_request.dart# PaymentRequest + IzinSakit
├── gaji/
│   └── salary_tariff.dart  # SalaryTariff, TeacherSalary, TunjanganDetail, SalaryBreakdown
├── akademik/
│   └── nilai_harian.dart   # NilaiHarian, PerilakuMurid, PrestasiPelanggaran
├── kalender/
│   └── kalender.dart       # KalenderPendidikan, Pengumuman
└── models.dart             # Barrel export semua
```

## Pemakaian

```dart
import 'package:absesni_digital/data/models/models.dart';

// Sebelum (dynamic):
// final name = user['name'] as String;
// final nim = data['nim'].toString();

// Sesudah (typed):
final user = AuthUser.fromJson(response.data['user']);
final students = (response.data['data'] as List)
    .map((e) => SantriPenempatan.fromJson(Map<String, dynamic>.from(e as Map)))
    .toList();

// Generic wrapper:
final api = ApiResponse<List<SantriPenempatan>>.listFromJson(
  response.data, SantriPenempatan.fromJson,
);
if (api.success) use(api.data!);
```

## Catatan

- Semua `fromJson` toleran terhadap `int`/`String` campur (`int.tryParse('${j['id']}')`) sesuai `libsql` yang kadang kirim angka sebagai string.
- `ALFA` ↔ `ALPA` dinormalisasi di `AttendanceStatusX`.
- `Lembaga` enum `ALL|MADRASAH|TPQ`, default `ALL`.
- `models.dart` adalah barrel — provider baru disarankan import dari sana untuk tree-shaking tetap baik.

## Migrasi Provider (opsional, tidak dipaksa)

Tidak semua `lib/providers/*.dart` sudah di-refactor ke typed model (agar tidak breaking). Saat menambah fitur baru, gunakan model:

```dart
// providers/presensi_kelas_provider.dart contoh:
final rows = ClassAttendanceResponse.fromJson(response.data);
final summary = rows.summary; // AttendanceSummary
final hadir = summary.hadir;
```

Lihat `AGENTS.md` untuk daftar endpoint lengkap.
