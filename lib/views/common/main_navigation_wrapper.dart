import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../guru/dashboard_page.dart';
import '../guru/riwayat_absensi_guru_page.dart';
import '../guru/riwayat_absensi_murid_page.dart';
import '../info/menu_info.dart';
import '../../utils/snackbar_helper.dart';
import 'package:flutter/cupertino.dart';


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
                icon: const Icon(CupertinoIcons.square_grid_2x2),
                selectedIcon: Icon(
                  CupertinoIcons.square_grid_2x2,
                  color: theme.colorScheme.primary,
                ),
                label: 'Beranda',
              ),
              NavigationDestination(
                icon: const Icon(CupertinoIcons.clock),
                selectedIcon: Icon(
                  CupertinoIcons.clock,
                  color: theme.colorScheme.primary,
                ),
                label: 'Riwayat Guru',
              ),
              NavigationDestination(
                icon: const Icon(CupertinoIcons.person_badge_plus),
                selectedIcon: Icon(
                  CupertinoIcons.person_badge_plus,
                  color: theme.colorScheme.primary,
                ),
                label: 'Siswa',
              ),
              NavigationDestination(
                icon: const Icon(CupertinoIcons.gear),
                selectedIcon: Icon(
                  CupertinoIcons.gear,
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