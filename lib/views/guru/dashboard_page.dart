import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_guru_provider.dart';
import 'akun_google_page.dart';
import 'gaji_guru_page.dart';
import 'guru_piket_page.dart';
import 'input_nilai_harian_page.dart';
import 'jadwal_mingguan_page.dart';
import 'kegiatan_internal_guru_page.dart';
import 'kegiatan_non_akademik_page.dart';
import 'pembayaran_page.dart';
import 'presensi_kelas_page.dart';
import 'presensi_saya_page.dart';
import 'tabungan_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    Color getVibrantColor(Color lightColor, Color darkColor) {
      return isDark ? darkColor : lightColor;
    }

    return ChangeNotifierProvider(
      create: (_) => DashboardGuruProvider()..fetchDashboardData(),
      child: Consumer<DashboardGuruProvider>(
        builder: (context, dash, _) {
          // --- Daftar Menu Akses Layanan (Bebas Duplikat) ---
          final menuItems = [
            _buildActionCard(
              context,
              icon: Icons.menu_book_outlined,
              title: 'Presensi KBM',
              subtitle: 'KBM Kelas',
              color: getVibrantColor(const Color(0xFF007722), const Color(0xFF22C55E)),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PresensiSayaPage())),
            ),
            _buildActionCard(
              context,
              icon: Icons.calendar_view_week_outlined,
              title: 'Jadwal Sepekan',
              subtitle: 'Seminggu',
              color: getVibrantColor(const Color(0xFF7E22CE), const Color(0xFFC084FC)),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const JadwalMingguanPage())),
            ),
            _buildActionCard(
              context,
              icon: Icons.shield_outlined,
              title: 'Mode Piket',
              subtitle: 'Badal Kelas',
              color: getVibrantColor(const Color(0xFF1D4ED8), const Color(0xFF3B82F6)),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GuruPiketPage())),
            ),
            _buildActionCard(
              context,
              icon: Icons.groups_outlined,
              title: 'Non-Akademik',
              subtitle: 'Kegiatan Santri',
              color: getVibrantColor(const Color(0xFF0D9488), const Color(0xFF14B8A6)),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KegiatanNonAkademikPage())),
            ),
            _buildActionCard(
              context,
              icon: Icons.badge_outlined,
              title: 'Kegiatan Guru',
              subtitle: 'Internal Asatidz',
              color: getVibrantColor(const Color(0xFF4338CA), const Color(0xFF6366F1)),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KegiatanInternalGuruPage())),
            ),
            _buildActionCard(
              context,
              icon: Icons.receipt_long_outlined,
              title: 'Riwayat Bisyaroh',
              subtitle: 'Slip Pendapatan',
              color: getVibrantColor(const Color(0xFFB45309), const Color(0xFFF59E0B)),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GajiGuruPage())),
            ),
            _buildActionCard(
              context,
              icon: Icons.g_mobiledata,
              title: 'Akun Google',
              subtitle: 'Tautkan Login',
              color: getVibrantColor(const Color(0xFF7C3AED), const Color(0xFFA78BFA)),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AkunGooglePage())),
            ),
            //  _buildActionCard(
            //   context,
            //   icon: Icons.receipt_long_outlined,
            //   title: 'Riwayat Bisyaroh',
            //   subtitle: 'Slip Pendapatan',
            //   color: getVibrantColor(const Color(0xFFB45309), const Color(0xFFF59E0B)),
            //   onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GajiGuruPage())),
            // ),
            if (dash.isAdmin) ...[
              _buildActionCard(
                context,
                icon: Icons.account_balance_wallet_outlined,
                title: 'Tabungan',
                subtitle: 'Saldo & Mutasi',
                isAdminOnly: true,
                color: getVibrantColor(const Color(0xFF0284C7), const Color(0xFF38BDF8)),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TabunganPage())),
              ),
              _buildActionCard(
                context,
                icon: Icons.payments_outlined,
                title: 'Pembayaran',
                subtitle: 'Yaumiyah & DU',
                isAdminOnly: true,
                color: getVibrantColor(const Color(0xFF16A34A), const Color(0xFF4ADE80)),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PembayaranPage())),
              ),
            ],
          ];

          return Scaffold(
            body: dash.isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: dash.fetchDashboardData,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverPersistentHeader(
                          pinned: true,
                          delegate: DynamicCurvedHeaderDelegate(
                            maxExtentHeight: 200.0,
                            minExtentHeight: kToolbarHeight + MediaQuery.of(context).padding.top,
                            dash: dash,
                            onLogout: _processLogout,
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  'Layanan Presensi & Akademik',
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 12),

                                // ── Grid Menu Layanan ──
                                GridView.count(
                                  crossAxisCount: 4,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  mainAxisSpacing: 10,
                                  crossAxisSpacing: 8,
                                  childAspectRatio: 0.76,
                                  children: menuItems,
                                ),

                                // ── Jadwal Pelajaran Hari Ini ──
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Icon(Icons.schedule_outlined, size: 20, color: colorScheme.primary),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Jadwal Hari Ini',
                                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    const Spacer(),
                                    if (dash.schedules.isNotEmpty)
                                      Text(
                                        '${dash.schedules.length} sesi',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: colorScheme.onSurfaceVariant,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                if (dash.schedules.isEmpty)
                                  _buildEmptySchedule(colorScheme)
                                else
                                  ...dash.schedules.map((s) => _buildScheduleCard(s, colorScheme, theme, dash)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildEmptySchedule(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(76)),
      ),
      child: Column(
        children: [
          Icon(Icons.event_busy_outlined, size: 40, color: colorScheme.onSurfaceVariant.withAlpha(102)),
          const SizedBox(height: 8),
          Text(
            'Tidak ada jadwal mengajar hari ini.',
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(dynamic s, ColorScheme colorScheme, ThemeData theme, [dynamic dash]) {
    final subject = (s['subject_name'] ?? '-').toString();
    final className = (s['class_name'] ?? '-').toString();
    final startTime = (s['start_time'] ?? '').toString();
    final endTime = (s['end_time'] ?? '').toString();
    final session = (s['session_name'] ?? '').toString();
    final status = (s['teaching_status'] ?? 'UTAMA').toString();
    final isPiket = status == 'PIKET';
    final mainTeacher = (s['main_teacher_name'] ?? '').toString();
    final sid = int.tryParse('${s['schedule_id'] ?? s['id'] ?? ''}');
    final sum = (dash != null && sid != null) ? (dash.summaries[sid] as Map?) : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPiket
              ? colorScheme.tertiary.withAlpha(102)
              : colorScheme.outlineVariant.withAlpha(76),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openPresensiFromSchedule(s, subject, className, session, isPiket),
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: isPiket ? colorScheme.tertiary : colorScheme.primary,
                    width: 4,
                  ),
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Column(
                    children: [
                      Text(
                        startTime,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      Text(
                        '–',
                        style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
                      ),
                      Text(
                        endTime,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subject,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$className${session.isNotEmpty ? ' · $session' : ''}',
                          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                        ),
                        if (isPiket) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.swap_horiz, size: 12, color: colorScheme.tertiary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  mainTeacher.isNotEmpty
                                      ? 'Badal dari $mainTeacher'
                                      : 'Piket',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colorScheme.tertiary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (sum != null) ...[
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 4,
                            runSpacing: 2,
                            children: [
                              _tinyBadge('H:${sum['hadir'] ?? 0}', Colors.green.shade600),
                              _tinyBadge('S:${sum['sakit'] ?? 0}', Colors.amber.shade700),
                              _tinyBadge('I:${sum['izin'] ?? 0}', Colors.blue.shade600),
                              _tinyBadge('A:${sum['alpa'] ?? 0}', colorScheme.error),
                              _tinyBadge('Sudah ${sum['sudah'] ?? 0}/${sum['total'] ?? 0}', (sum['sudah'] ?? 0) > 0 ? Colors.green.shade600 : Colors.orange.shade600),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isPiket
                          ? colorScheme.tertiary.withAlpha(31)
                          : colorScheme.primary.withAlpha(31),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isPiket ? 'PIKET' : 'UTAMA',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isPiket ? colorScheme.tertiary : colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openPresensiFromSchedule(dynamic s, String subject, String className, String session, bool isPiket) {
    final scheduleId = int.tryParse('${s['schedule_id'] ?? s['id']}');
    if (scheduleId == null) return;
    final classroomId = int.tryParse('${s['classroom_id']}') ?? 0;
    final rombelId = int.tryParse('${s['rombel_id'] ?? ''}');
    final subjectId = int.tryParse('${s['subject_id'] ?? ''}');
    final jenjangId = int.tryParse('${s['jenjang_id'] ?? ''}');
    final today = DateTime.now();
    final tanggal =
        '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final colorScheme = Theme.of(ctx).colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  subject,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$className · $session${isPiket ? ' · Badal' : ''}',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                // Opsi Presensi KBM
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.withAlpha(31),
                    child: const Icon(Icons.menu_book_outlined, color: Colors.green, size: 20),
                  ),
                  title: const Text('Isi Presensi', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Kehadiran murid (H/S/I/A)', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PresensiKelasPage(
                          scheduleId: scheduleId,
                          classroomId: classroomId,
                          subjectName: '$subject${isPiket ? ' (Badal)' : ''}',
                          className: className,
                          sessionName: session.isNotEmpty ? session : 'PAGI',
                          rombelId: rombelId,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 4),
                // Opsi Input Nilai
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.amber.withAlpha(31),
                    child: const Icon(Icons.grade_outlined, color: Colors.amber, size: 20),
                  ),
                  title: const Text('Input Nilai', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Nilai harian murid (0–100)', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => InputNilaiHarianPage(
                          scheduleId: scheduleId,
                          classroomId: classroomId,
                          subjectName: subject,
                          className: className,
                          tanggal: tanggal,
                          subjectId: subjectId,
                          jenjangId: jenjangId,
                          rombelId: rombelId,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _tinyBadge(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withAlpha(31),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withAlpha(76)),
        ),
        child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color)),
      );

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool isAdminOnly = false,
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
            border: Border.all(color: colorScheme.outlineVariant.withAlpha(76)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: color.withAlpha(38), shape: BoxShape.circle),
                    child: Icon(icon, size: 20, color: color),
                  ),
                  if (isAdminOnly)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle),
                        child: const Icon(Icons.star_rounded, size: 10, color: Colors.black),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: colorScheme.onSurface),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 8.5, color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 2. Perbarui class DynamicCurvedHeaderDelegate berikut:
class DynamicCurvedHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double maxExtentHeight;
  final double minExtentHeight;
  final DashboardGuruProvider dash;
  final VoidCallback onLogout;

  DynamicCurvedHeaderDelegate({
    required this.maxExtentHeight,
    required this.minExtentHeight,
    required this.dash,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final percent = (shrinkOffset / (maxExtentHeight - minExtentHeight)).clamp(0.0, 1.0);
    final curveDepth = 24.0 * (1.0 - percent);

    return Material(
      elevation: percent > 0.8 ? 2 : 0,
      color: Colors.transparent,
      child: ClipPath(
        clipper: CurvedUpClipper(curveDepth: curveDepth),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colorScheme.primary, colorScheme.tertiary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Navigation Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      Text(
                        'E-Presensi Guru',
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.logout_rounded),
                        color: colorScheme.onPrimary,
                        onPressed: onLogout,
                        tooltip: 'Logout',
                      ),
                    ],
                  ),
                ),

                // Content Profile Section
                Expanded(
                  child: Opacity(
                    opacity: (1.0 - (percent * 1.5)).clamp(0.0, 1.0),
                    child: percent > 0.6
                        ? const SizedBox.shrink()
                        : Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: colorScheme.onPrimary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: CircleAvatar(
                                      backgroundColor: colorScheme.primaryContainer,
                                      radius: 24,
                                      child: Icon(
                                        Icons.person,
                                        color: colorScheme.onPrimaryContainer,
                                        size: 28,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              'Ahlan wa Sahlan,',
                                              style: TextStyle(
                                                color: colorScheme.onPrimary.withAlpha(217),
                                                fontSize: 11,
                                              ),
                                            ),
                                            if (dash.isAdmin) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                decoration: BoxDecoration(
                                                  color: colorScheme.errorContainer,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  'ADMIN',
                                                  style: TextStyle(
                                                    fontSize: 8.5,
                                                    fontWeight: FontWeight.bold,
                                                    color: colorScheme.onErrorContainer,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          dash.teacherName.toUpperCase(),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: colorScheme.onPrimary,
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: colorScheme.onPrimary.withAlpha(46),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.calendar_today_outlined, size: 10, color: colorScheme.onPrimary),
                                              const SizedBox(width: 4),
                                              Text(
                                                dash.academicYearInfo,
                                                style: TextStyle(
                                                  color: colorScheme.onPrimary,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                ),
                // Ruang ekstra bawah untuk lengkungan ke atas
                SizedBox(height: curveDepth),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  double get maxExtent => maxExtentHeight;

  @override
  double get minExtent => minExtentHeight;

  @override
  bool shouldRebuild(covariant DynamicCurvedHeaderDelegate oldDelegate) {
    return true; // Provider notifyListeners → rebuild header
  }
}
// ── Custom Clipper untuk Lengkungan ke Atas (Concave) ──
class CurvedUpClipper extends CustomClipper<Path> {
  final double curveDepth;

  CurvedUpClipper({required this.curveDepth});

  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height);

    // Titik kontrol di bagian tengah ditarik ke atas (size.height - curveDepth)
    final controlPoint = Offset(size.width / 2, size.height - (curveDepth * 2));
    final endPoint = Offset(size.width, size.height);

    path.quadraticBezierTo(
      controlPoint.dx,
      controlPoint.dy,
      endPoint.dx,
      endPoint.dy,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CurvedUpClipper oldClipper) {
    return oldClipper.curveDepth != curveDepth;
  }
}