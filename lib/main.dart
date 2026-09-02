import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/absensi_murid_provider.dart';
import 'providers/dashboard_guru_provider.dart';
import 'providers/gaji_guru_provider.dart';
import 'providers/guru_piket_provider.dart';
import 'providers/kegiatan_list_provider.dart';
import 'providers/parent_provider.dart';
import 'providers/pembayaran_provider.dart';
import 'providers/presensi_kegiatan_guru_provider.dart';
import 'providers/presensi_kegiatan_provider.dart';
import 'providers/presensi_kelas_provider.dart';
import 'providers/riwayat_guru_provider.dart';
import 'providers/riwayat_murid_provider.dart';
import 'providers/scan_istighosah_provider.dart';
import 'providers/student_dashboard_provider.dart';
import 'providers/student_jadwal_provider.dart';
import 'providers/student_kalender_provider.dart';
import 'providers/student_perilaku_provider.dart';
import 'providers/student_prestasi_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'views/auth/login_page.dart';
import 'views/common/main_navigation_wrapper.dart';
import 'views/santri/student_dashboard_page.dart';
import 'views/parent/parent_dashboard_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AbsensiKbmMuridProvider()),
        ChangeNotifierProvider(create: (_) => DashboardGuruProvider()),
        ChangeNotifierProvider(create: (_) => GajiGuruProvider()),
        ChangeNotifierProvider(create: (_) => GuruPiketProvider()),
        ChangeNotifierProvider(create: (_) => KegiatanListProvider()),
        ChangeNotifierProvider(create: (_) => ParentProvider()),
        ChangeNotifierProvider(create: (_) => PresensiKegiatanGuruProvider()),
        ChangeNotifierProvider(create: (_) => PresensiKegiatanProvider()),
        ChangeNotifierProvider(create: (_) => PresensiKelasProvider()),
        ChangeNotifierProvider(create: (_) => RiwayatGuruProvider()),
        ChangeNotifierProvider(create: (_) => RiwayatMuridProvider()),
        ChangeNotifierProvider(create: (_) => ScanIstighosahProvider()),
        ChangeNotifierProvider(create: (_) => StudentJadwalProvider()),
        ChangeNotifierProvider(create: (_) => StudentKalenderProvider()),
        ChangeNotifierProvider(create: (_) => StudentPerilakuProvider()),
        ChangeNotifierProvider(create: (_) => StudentPrestasiProvider()),
        ChangeNotifierProvider(create: (_) => PembayaranMuridProvider()),
        ChangeNotifierProvider(create: (_) => TabunganAdminProvider()),
        ChangeNotifierProvider(create: (_) => PembayaranAdminProvider()),
        ChangeNotifierProvider(create: (_) => StudentDashboardProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Presensi Pesantren',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const AuthGate(),
          );
        },
      ),
    );
  }
}

/// Gerbang auth anti-flicker: tunggu init() selesai sebelum tentukan halaman.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (!auth.isInitialized) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.school_rounded, size: 56, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 16),
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2.8),
                  ),
                  const SizedBox(height: 12),
                  Text('Memuat...', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
                ],
              ),
            ),
          );
        }
        if (!auth.isLoggedIn) return const LoginPage();
        if (auth.isStudent) return const StudentDashboardPage();
        if (auth.isParent) return const ParentDashboardPage();
        return const MainNavigationWrapper();
      },
    );
  }
}
