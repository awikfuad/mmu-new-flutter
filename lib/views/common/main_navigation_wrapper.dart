import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/theme_selector_dialog.dart';
import '../guru/dashboard_page.dart';
import '../guru/riwayat_absensi_guru_page.dart';
import '../guru/riwayat_absensi_murid_page.dart';

class MainNavigationWrapper extends StatefulWidget {
  const MainNavigationWrapper({super.key});

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  int _currentIndex = 0;
  DateTime? _lastBackPressed;

  final List<Widget> _pages = [
    const DashboardPage(),
    const RiwayatAbsensiGuruPage(),
    const RiwayatAbsensiMuridPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = context.read<ThemeProvider>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final now = DateTime.now();
        if (_lastBackPressed != null &&
            now.difference(_lastBackPressed!) < const Duration(seconds: 2)) {
          return;
        }
        _lastBackPressed = now;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tekan kembali sekali lagi untuk keluar'),
            duration: Duration(seconds: 2),
          ),
        );
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
              color: theme.colorScheme.outlineVariant.withValues(alpha:0.4),
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
              selectedIcon: Icon(Icons.grid_view_rounded, color: theme.colorScheme.primary),
              label: 'Beranda',
            ),
            NavigationDestination(
              icon: const Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history_rounded, color: theme.colorScheme.primary),
              label: 'Riwayat Guru',
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_search_outlined),
              selectedIcon: Icon(Icons.person_search_rounded, color: theme.colorScheme.primary),
              label: 'Siswa',
            ),
          ],
        ),
      ),
      // Tombol Mengambang untuk Membuka Dialog Pemilih Warna/Tema
        floatingActionButton: FloatingActionButton.small(
          elevation: 2,
          backgroundColor: theme.colorScheme.secondaryContainer,
          foregroundColor: theme.colorScheme.onSecondaryContainer,
          child: const Icon(Icons.palette_outlined),
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => ThemeSelectorDialog(themeProvider: themeProvider),
            );
          },
        ),
      ),
    );
  }
}