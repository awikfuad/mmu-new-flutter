import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/notification_center.dart';
import 'services/notification_service.dart';
import 'providers/absensi_murid_provider.dart';
import 'providers/biometric_provider.dart';
import 'providers/dashboard_guru_provider.dart';
import 'providers/gaji_guru_provider.dart';
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
import 'package:flutter/cupertino.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Inisialisasi notifikasi lokal (tanpa memblokir startup UI).
  unawaited(NotificationService.instance.init());
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
        ChangeNotifierProvider(create: (_) => BiometricProvider()),
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
                  Icon(CupertinoIcons.book, size: 56, color: Theme.of(context).colorScheme.primary),
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
        return _NotificationGate(
          child: _loggedInPage(auth),
        );
      },
    );
  }

  Widget _loggedInPage(AuthProvider auth) {
    if (auth.isStudent) return const StudentDashboardPage();
    if (auth.isParent) return const ParentDashboardPage();
    final role = auth.userRole;
    if (role != 'admin' && role != 'teacher') {
      // Role tidak dikenal — jangan beri akses admin, kembali ke login.
      WidgetsBinding.instance.addPostFrameCallback((_) => auth.logout());
      return const LoginPage();
    }
    return const MainNavigationWrapper();
  }
}

/// Mengecek notifikasi lokal (role-aware) setelah halaman login tampil,
/// lalu menyegarkan tiap 30 menit selama app di foreground.
class _NotificationGate extends StatefulWidget {
  const _NotificationGate({required this.child});

  final Widget child;

  @override
  State<_NotificationGate> createState() => _NotificationGateState();
}

class _NotificationGateState extends State<_NotificationGate> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    await LocalNotificationCenter.instance.runChecks();
    _timer ??= Timer.periodic(
      const Duration(minutes: 30),
      (_) => LocalNotificationCenter.instance.runChecks(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
