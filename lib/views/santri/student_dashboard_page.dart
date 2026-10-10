import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/auth_provider.dart';
import '../../providers/student_dashboard_provider.dart';
import '../../utils/foto_helper.dart';
import '../../utils/snackbar_helper.dart';

import '../info/menu_info.dart';
import 'absensi_kbm_murid_page.dart';
import 'absensi_kegiatan_murid_page.dart';
import 'pembayaran_murid_page.dart';
import 'student_change_password_dialog.dart';
import 'student_jadwal_page.dart';
import 'student_kalender_page.dart';
import 'student_perilaku_page.dart';
import 'student_prestasi_page.dart';
import 'student_ujian_page.dart';
import 'tabungan_murid_page.dart';

class StudentDashboardPage extends StatefulWidget {
  const StudentDashboardPage({super.key});

  @override
  State<StudentDashboardPage> createState() => _StudentDashboardPageState();
}

class _StudentDashboardPageState extends State<StudentDashboardPage> {
  DateTime? _lastBackPressed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkDefaultPassword());
  }

  /// Login santri memakai password awal (tanggal lahir / default) yang tidak
  /// memenuhi kriteria → paksa ganti password sebelum memakai aplikasi.
  Future<void> _checkDefaultPassword() async {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    if (!auth.isStudent || !auth.mustChangePassword) return;

    final changed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const StudentChangePasswordDialog(),
    );

    if (changed == true && mounted) {
      showSuccessSnackBar(
        context,
        'Password berhasil diubah.',
        duration: const Duration(seconds: 2),
      );
    }
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      showErrorSnackBar(context, 'Gagal membuka link: $urlString');
    }
  }

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

    if (confirm == true && mounted) {
      await context.read<AuthProvider>().logout();
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
              showInfoSnackBar(
                context,
                'Tekan kembali sekali lagi untuk keluar',
                duration: const Duration(seconds: 2),
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
                    icon: const Icon(Icons.info_outline),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AboutAppPage(),
                        ),
                      );
                    },
                    tooltip: 'Tentang Aplikasi',
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
                                color: colorScheme.onSurfaceVariant.withAlpha(180),
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
            color: colorScheme.primary.withAlpha(51),
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
                final bool hasFoto = fotoUrl != null && fotoUrl.trim().isNotEmpty;

                return CircleAvatar(
                  radius: 24,
                  backgroundColor: colorScheme.onPrimary.withAlpha(51),
                  backgroundImage: hasFoto ? cachedFotoProvider(fotoUrl) : null,
                  onBackgroundImageError: hasFoto ? (_, _) {} : null,
                  child: !hasFoto
                      ? Icon(Icons.person, color: colorScheme.onPrimary, size: 28)
                      : null,
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
                        color: colorScheme.onPrimary.withAlpha(217),
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      'Kelas: $className \u2022 ${dash.namaRombel}',
                      style: TextStyle(
                        color: colorScheme.onPrimary.withAlpha(217),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.onPrimary.withAlpha(51),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  lembaga,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          // const SizedBox(height: 16),
          // Scroll horizontal untuk statistik profil agar tidak terpotong di layar kecil
          // SingleChildScrollView(
          //   scrollDirection: Axis.horizontal,
          //   child: Row(
          //     children: [
          //       _buildProfileStat('Kelas', className),
          //       const SizedBox(width: 16),
          //       _buildProfileStat(
          //         'Saldo Tabungan',
          //         formatRp(dash.balance),
          //       ),
                
                
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }

  // Widget _buildProfileStat(String label, String value) {
  //   final colorScheme = Theme.of(context).colorScheme;
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(
  //         label,
  //         style: TextStyle(
  //           color: colorScheme.onPrimary.withAlpha(204),
  //           fontSize: 10,
  //         ),
  //       ),
  //       const SizedBox(height: 2),
  //       Text(
  //         value,
  //         maxLines: 1,
  //         overflow: TextOverflow.ellipsis,
  //         style: TextStyle(
  //           color: colorScheme.onPrimary,
  //           fontWeight: FontWeight.bold,
  //           fontSize: 13,
  //         ),
  //       ),
  //     ],
  //   );
  // }

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
      _MenuItem(
        icon: Icons.assignment_outlined,
        title: 'Ujian',
        subtitle: 'CBT Kode Akses',
        color: getVibrantColor(const Color(0xFF0F766E), const Color(0xFF14B8A6)),
        onTap: () => _openPage(const StudentUjianPage()),
      ),
      _MenuItem(
        icon: Icons.chat_bubble_outline_rounded,
        title: 'SALURAN WA MMU A44',
        subtitle: 'Info Pesantren',
        color: getVibrantColor(const Color(0xFF128C7E), const Color(0xFF25D366)),
        onTap: () => _launchURL('https://whatsapp.com/channel/0029VbCQjOtCXC3H0T0s7o2a'),
      ),
      _MenuItem(
        icon: Icons.camera_alt_outlined,
        title: 'Instagram',
        subtitle: '@mmua44warungdowo',
        color: getVibrantColor(const Color(0xFFC13584), const Color(0xFFE1306C)),
        onTap: () => _launchURL('https://www.instagram.com/mmua44warungdowo/'),
      ),
      _MenuItem(
        icon: Icons.play_circle_outline_rounded,
        title: 'MMU A44 TV',
        subtitle: 'Chanel Resmi MMU A44',
        color: getVibrantColor(const Color(0xFFC4302B), const Color(0xFFFF0000)),
        onTap: () => _launchURL('https://youtube.com/@mmua44'),
      ),
    ];

    return GridView.count(
      crossAxisCount: 4,
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
              color: colorScheme.outlineVariant.withAlpha(76),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(38),
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