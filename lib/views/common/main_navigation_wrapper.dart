import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../guru/dashboard_page.dart';
import '../guru/riwayat_absensi_guru_page.dart';
import '../guru/riwayat_absensi_murid_page.dart';
import '../info/menu_info.dart';
import '../../utils/snackbar_helper.dart';


class MainNavigationWrapper extends StatefulWidget {
  const MainNavigationWrapper({super.key});

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  int _currentIndex = 0;
  DateTime? _lastBackPressed;

  final List<Widget> _pages = const [
    DashboardPage(),
    RiwayatAbsensiGuruPage(),
    RiwayatAbsensiMuridPage(),
    AboutAppPage(), // Perbaikan: Menambahkan halaman ke-4
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final now = DateTime.now();
        if (_lastBackPressed != null &&
            now.difference(_lastBackPressed!) < const Duration(seconds: 2)) {
          await SystemNavigator.pop();
          return;
        }

        _lastBackPressed = now;
        if (context.mounted) {
          showInfoSnackBar(
            context,
            'Tekan kembali sekali lagi untuk keluar',
            duration: const Duration(seconds: 2),
          );
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
          ),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            elevation: 0,
            height: 65,
            indicatorColor: theme.colorScheme.primaryContainer,
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.grid_view_outlined),
                selectedIcon: Icon(
                  Icons.grid_view_rounded,
                  color: theme.colorScheme.primary,
                ),
                label: 'Beranda',
              ),
              NavigationDestination(
                icon: const Icon(Icons.history_outlined),
                selectedIcon: Icon(
                  Icons.history_rounded,
                  color: theme.colorScheme.primary,
                ),
                label: 'Riwayat Guru',
              ),
              NavigationDestination(
                icon: const Icon(Icons.person_search_outlined),
                selectedIcon: Icon(
                  Icons.person_search_rounded,
                  color: theme.colorScheme.primary,
                ),
                label: 'Siswa',
              ),
              NavigationDestination(
                icon: const Icon(Icons.settings_outlined),
                selectedIcon: Icon(
                  Icons.settings_rounded,
                  color: theme.colorScheme.primary,
                ),
                label: 'Pengaturan',
              ),
            ],
          ),
        ),
      ),
    );
  }
}