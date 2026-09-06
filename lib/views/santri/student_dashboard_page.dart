import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/auth_provider.dart';
import '../../providers/student_dashboard_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/theme_selector_dialog.dart';
import '../../utils/format.dart';
import '../../utils/foto_helper.dart';
import '../../widgets/bayar_dari_tabungan_sheet.dart';
import 'absensi_kbm_murid_page.dart';
import 'absensi_kegiatan_murid_page.dart';
import 'pembayaran_murid_page.dart';
import 'student_perilaku_page.dart';
import 'student_prestasi_page.dart';
import 'student_jadwal_page.dart';
import 'student_kalender_page.dart';
import 'tabungan_murid_page.dart';

class StudentDashboardPage extends StatefulWidget {
  const StudentDashboardPage({super.key});

  @override
  State<StudentDashboardPage> createState() => _StudentDashboardPageState();
}

class _StudentDashboardPageState extends State<StudentDashboardPage> {
  DateTime? _lastBackPressed;

  void _processLogout() async {
    final colorScheme = Theme.of(context).colorScheme;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Logout', style: TextStyle(color: colorScheme.onError)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      await context.read<AuthProvider>().logout();
    }
  }

  void _openThemeSelector() {
    final themeProvider = context.read<ThemeProvider>();
    showDialog(
      context: context,
      builder: (_) => ThemeSelectorDialog(themeProvider: themeProvider),
    );
  }

  Future<void> _openBayar(StudentDashboardProvider dash) async {
    final colorScheme = Theme.of(context).colorScheme;
    final done = await showBayarDariTabunganSheet(context);
    if (done == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Pembayaran berhasil!'),
          backgroundColor: colorScheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      dash.fetchDashboardData();
    }
  }

  void _openPage(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ChangeNotifierProvider(
      create: (_) => StudentDashboardProvider()..fetchDashboardData(),
      child: Consumer<StudentDashboardProvider>(
        builder: (context, dash, _) {
          final lembaga = dash.lembaga;
          final className = dash.className;

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
              appBar: AppBar(
              elevation: 0,
              title: const Text(
                'E-Presensi Santri',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              backgroundColor: colorScheme.surface,
              foregroundColor: colorScheme.onSurface,
              actions: [
                IconButton(
                  icon: const Icon(Icons.palette_outlined),
                  onPressed: _openThemeSelector,
                  tooltip: 'Pengaturan Tema',
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded),
                  onPressed: _processLogout,
                  tooltip: 'Logout',
                ),
              ],
            ),
            body: dash.isLoading
                ? _buildShimmerLoading(context)
                : RefreshIndicator(
                    onRefresh: dash.fetchDashboardData,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildProfileCard(dash, lembaga, className),
                        const SizedBox(height: 16),
                        _buildGridMenu(dash),
                        const SizedBox(height: 20),
                        Center(
                          child: Text(
                            'MMU A-44 \u2022 E-Presensi Santri',
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileCard(
      StudentDashboardProvider dash, String lembaga, String className) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Builder(builder: (_) {
                final fotoUrl = resolveFotoUrl(dash.foto);
                return CircleAvatar(
                  radius: 24,
                  backgroundColor: colorScheme.onPrimary.withValues(alpha: 0.2),
                  backgroundImage: cachedFotoProvider(fotoUrl),
                  onBackgroundImageError: (_, __) {},
                  child: fotoUrl == null ? Icon(Icons.person, color: colorScheme.onPrimary, size: 28) : null,
                );
              }),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dash.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      'NIM: ${dash.nim}',
                      style: TextStyle(
                        color: colorScheme.onPrimary.withValues(alpha: 0.85),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.onPrimary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  lembaga,
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildProfileStat('Kelas', className)),
              Expanded(
                child: _buildProfileStat(
                  'Saldo Tabungan',
                  formatRp(dash.balance),
                ),
              ),
              if (dash.namaRombel.isNotEmpty && dash.namaRombel != '-')
                Expanded(child: _buildProfileStat('Rombel', dash.namaRombel)),
              if (dash.tanggalLahir != null && dash.tanggalLahir!.isNotEmpty)
                Expanded(
                  child: _buildProfileStat('Tgl Lahir', dash.tanggalLahir!),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStat(String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colorScheme.onPrimary.withValues(alpha: 0.8),
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildGridMenu(StudentDashboardProvider dash) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color getVibrantColor(Color lightColor, Color darkColor) {
      return isDark ? darkColor : lightColor;
    }

    final items = [
      _MenuItem(
        icon: Icons.receipt_long_outlined,
        title: 'Pembayaran',
        subtitle: 'Iuran & DU',
        color: getVibrantColor(const Color(0xFF007722), const Color(0xFF22C55E)),
        onTap: () => _openPage(const PembayaranMuridPage()),
      ),
      _MenuItem(
        icon: Icons.wallet_outlined,
        title: 'Tabungan',
        subtitle: 'Saldo Mutasi',
        color: getVibrantColor(const Color(0xFF1D4ED8), const Color(0xFF3B82F6)),
        onTap: () => _openPage(const TabunganMuridPage()),
      ),
      _MenuItem(
        icon: Icons.school_outlined,
        title: 'Absensi KBM',
        subtitle: 'Kehadiran',
        color: getVibrantColor(const Color(0xFF4338CA), const Color(0xFF6366F1)),
        onTap: () => _openPage(const AbsensiKbmMuridPage()),
      ),
      _MenuItem(
        icon: Icons.event_available,
        title: 'Kegiatan',
        subtitle: 'Istighosah dll',
        color: getVibrantColor(const Color(0xFFD97706), const Color(0xFFF59E0B)),
        onTap: () => _openPage(const AbsensiKegiatanMuridPage()),
      ),
      _MenuItem(
        icon: Icons.psychology_outlined,
        title: 'Perilaku',
        subtitle: 'Penilaian',
        color: getVibrantColor(const Color(0xFFC026D3), const Color(0xFFE086D3)),
        onTap: () => _openPage(const StudentPerilakuPage()),
      ),
      _MenuItem(
        icon: Icons.emoji_events_outlined,
        title: 'Prestasi',
        subtitle: 'Catatan Poin',
        color: getVibrantColor(const Color(0xFFE11D48), const Color(0xFFFB7185)),
        onTap: () => _openPage(const StudentPrestasiPage()),
      ),
      _MenuItem(
        icon: Icons.schedule_outlined,
        title: 'Jadwal',
        subtitle: 'Mata Pelajaran',
        color: getVibrantColor(const Color(0xFFEA580C), const Color(0xFFF97316)),
        onTap: () => _openPage(const StudentJadwalPage()),
      ),
      _MenuItem(
        icon: Icons.calendar_month_outlined,
        title: 'Kalender',
        subtitle: 'Kaldik Hijriah',
        color: getVibrantColor(const Color(0xFF7E22CE), const Color(0xFFA855F7)),
        onTap: () => _openPage(const StudentKalenderPage()),
      ),
    ];

    return GridView.count(
      crossAxisCount: 4, // Diubah menjadi 4 kolom
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 8,
      childAspectRatio: 0.76,
      children: items
          .map(
            (item) => _buildActionCard(
              icon: item.icon,
              title: item.title,
              subtitle: item.subtitle,
              color: item.color,
              onTap: item.onTap,
            ),
          )
          .toList(),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: theme.cardTheme.color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 8.5,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerLoading(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final highlightColor = isDark ? Colors.grey.shade700 : Colors.grey.shade100;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 8,
                childAspectRatio: 0.76,
                children: List.generate(
                  8,
                  (index) => Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
}