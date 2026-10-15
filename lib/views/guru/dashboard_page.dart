import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_guru_provider.dart';
import 'absensi_guru_kbm_page.dart';
import 'arsip_soalan_page.dart';
import 'gaji_guru_page.dart';
import 'input_nilai_harian_page.dart';
import 'izin_guru_admin_page.dart';
import 'izin_sakit_admin_page.dart';
import 'jadwal_mingguan_page.dart';
import 'kegiatan_internal_guru_page.dart';
import 'kegiatan_non_akademik_page.dart';
import 'kelola_kegiatan_page.dart';
import 'pembayaran_page.dart';
import 'pengumuman_admin_page.dart';
import 'portal_wali_page.dart';
import 'presensi_kelas_page.dart';
import 'presensi_saya_page.dart';
import 'piket_hari_ini_page.dart';
import 'piket_pimpinan_page.dart';
import 'prestasi_pelanggaran_page.dart';
import 'tabungan_page.dart';
import '../../utils/cupertino_sheet.dart';
import 'package:flutter/cupertino.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Future<void> _processLogout() async {
    final confirm = await showCupertinoDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      await context.read<AuthProvider>().logout();
    }
  }

  /// DEBUG PIMPINAN: log sekali saja setiap perubahan kondisi avatar, lalu
  /// teruskan [action] sebagai onAvatarTap (null = avatar tak bisa diklik).
  VoidCallback? _loggedAvatarTapState({
    required bool isAdmin,
    required bool isPimpinan,
    required bool mode,
    required String? jabatan,
    required VoidCallback? action,
  }) {
    debugPrint(
      '[PIMPINAN] avatar-state: isAdmin=$isAdmin isPimpinan=$isPimpinan '
      'isPimpinanMode=$mode jabatan=$jabatan -> onAvatarTap=${action != null}',
    );
    return action;
  }

  /// Dialog pindah mode: Mode Guru ⇄ Mode Pimpinan (guru yang merangkap pimpinan).
  void _showModeSwitchDialog() {
    final auth = context.read<AuthProvider>();
    showCupertinoBottomSheet<void>(
      context: context,
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
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.arrow_left_right,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Pindah Mode',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  auth.isPimpinanMode
                      ? 'Anda sedang dalam Mode Pimpinan (${auth.pimpinanJabatan ?? 'Pimpinan'}).'
                      : 'Guru yang merangkap pimpinan dapat membuka menu kelola lembaga.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                if (!auth.isPimpinanMode)
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.amber.withValues(alpha: 0.12),
                      child: Icon(
                        CupertinoIcons.checkmark_seal,
                        color: Colors.amber.shade800,
                        size: 20,
                      ),
                    ),
                    title: const Text(
                      'Masuk Mode Pimpinan',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      auth.pimpinanJabatan ?? 'Pimpinan',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: const Icon(CupertinoIcons.chevron_right),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      auth.setPimpinanMode(true);
                    },
                  )
                else
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: colorScheme.primaryContainer,
                      child: Icon(
                        CupertinoIcons.person,
                        color: colorScheme.onPrimaryContainer,
                        size: 20,
                      ),
                    ),
                    title: const Text(
                      'Kembali ke Mode Guru',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Menu pribadi & presensi KBM',
                      style: TextStyle(fontSize: 12),
                    ),
                    trailing: const Icon(CupertinoIcons.chevron_right),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      auth.setPimpinanMode(false);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Kartu menu khusus guru yang merangkap pimpinan (5 fitur).
  List<Widget> _pimpinanFeatureCards(
    BuildContext context,
    Color Function(Color, Color) getVibrantColor,
  ) {
    return [
      _buildActionCard(
        context,
        icon: CupertinoIcons.checkmark_shield,
        title: 'Izin Guru',
        subtitle: 'Setujui & Badal',
        isAdminOnly: true,
        color: getVibrantColor(
          const Color(0xFFF97316),
          const Color(0xFFFB923C),
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const IzinGuruAdminPage()),
        ),
      ),
      _buildActionCard(
        context,
        icon: CupertinoIcons.person_crop_circle,
        title: 'Absen Guru KBM',
        subtitle: 'Kehadiran Mengajar',
        isAdminOnly: true,
        color: getVibrantColor(
          const Color(0xFF0EA5E9),
          const Color(0xFF38BDF8),
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AbsensiGuruKbmPage()),
        ),
      ),
      _buildActionCard(
        context,
        icon: CupertinoIcons.calendar,
        title: 'Izin Murid',
        subtitle: 'Setujui / Tolak',
        isAdminOnly: true,
        color: getVibrantColor(
          const Color(0xFF64748B),
          const Color(0xFF94A3B8),
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const IzinSakitAdminPage()),
        ),
      ),
      _buildActionCard(
        context,
        icon: CupertinoIcons.speaker_3,
        title: 'Pengumuman',
        subtitle: 'Buat & Publikasi',
        isAdminOnly: true,
        color: getVibrantColor(
          const Color(0xFFDB2777),
          const Color(0xFFF472B6),
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PengumumanAdminPage()),
        ),
      ),
      _buildActionCard(
        context,
        icon: CupertinoIcons.calendar,
        title: 'Kegiatan',
        subtitle: 'Buat Agenda',
        isAdminOnly: true,
        color: getVibrantColor(
          const Color(0xFF7C3AED),
          const Color(0xFFA78BFA),
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const KelolaKegiatanPage()),
        ),
      ),
      _buildActionCard(
        context,
        icon: CupertinoIcons.calendar_badge_plus,
        title: 'Piket Pimpinan',
        subtitle: 'Jadwal & Presensi',
        isAdminOnly: true,
        color: getVibrantColor(
          const Color(0xFF0F766E),
          const Color(0xFF2DD4BF),
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PiketPimpinanPage()),
        ),
      ),
      _buildActionCard(
        context,
        icon: CupertinoIcons.rosette,
        title: 'Prestasi & Pelanggaran',
        subtitle: 'Catat & Kelola',
        isAdminOnly: true,
        color: getVibrantColor(
          const Color(0xFFB45309),
          const Color(0xFFFBBF24),
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PrestasiPelanggaranPage()),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();

    Color getVibrantColor(Color lightColor, Color darkColor) {
      return isDark ? darkColor : lightColor;
    }

    return ChangeNotifierProvider(
      create: (_) => DashboardGuruProvider()..fetchDashboardData(),
      child: Consumer<DashboardGuruProvider>(
        builder: (context, dash, _) {
          final personalMenuItems = [
            _buildActionCard(
              context,
              icon: CupertinoIcons.book,
              title: 'Presensi KBM',
              subtitle: 'KBM Kelas',
              color: getVibrantColor(
                const Color(0xFF007722),
                const Color(0xFF22C55E),
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PresensiSayaPage()),
              ),
            ),
            _buildActionCard(
              context,
              icon: CupertinoIcons.person_3,
              title: 'Non-Akademik',
              subtitle: 'Kegiatan Santri',
              color: getVibrantColor(
                const Color(0xFF0D9488),
                const Color(0xFF14B8A6),
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const KegiatanNonAkademikPage(),
                ),
              ),
            ),
            _buildActionCard(
              context,
              icon: CupertinoIcons.person_crop_circle,
              title: 'Kegiatan Guru',
              subtitle: 'Internal Asatidz',
              color: getVibrantColor(
                const Color(0xFF4338CA),
                const Color(0xFF6366F1),
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const KegiatanInternalGuruPage(),
                ),
              ),
            ),
            _buildActionCard(
              context,
              icon: CupertinoIcons.doc_text,
              title: 'Riwayat Bisyaroh',
              subtitle: 'Slip Pendapatan',
              color: getVibrantColor(
                const Color(0xFFB45309),
                const Color(0xFFF59E0B),
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GajiGuruPage()),
              ),
            ),
            _buildActionCard(
              context,
              icon: CupertinoIcons.folder,
              title: 'Arsip Soalan',
              subtitle: 'Soal & Ujian',
              color: getVibrantColor(
                const Color(0xFF7C3AED),
                const Color(0xFFA78BFA),
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ArsipSoalanPage()),
              ),
            ),
            _buildActionCard(
              context,
              icon: CupertinoIcons.person_3,
              title: 'Portal Wali',
              subtitle: 'Guru + Orang Tua',
              color: getVibrantColor(
                const Color(0xFFBE185D),
                const Color(0xFFF472B6),
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PortalWaliPage()),
              ),
            ),
          ];

          final adminMenuItems = [
            if (dash.isAdmin) ...[
              _buildActionCard(
                context,
                icon: CupertinoIcons.creditcard,
                title: 'Tabungan',
                subtitle: 'Saldo & Mutasi',
                isAdminOnly: true,
                color: getVibrantColor(
                  const Color(0xFF0284C7),
                  const Color(0xFF38BDF8),
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TabunganPage()),
                ),
              ),
              _buildActionCard(
                context,
                icon: CupertinoIcons.creditcard,
                title: 'Pembayaran',
                subtitle: 'Yaumiyah & DU',
                isAdminOnly: true,
                color: getVibrantColor(
                  const Color(0xFF16A34A),
                  const Color(0xFF4ADE80),
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PembayaranPage()),
                ),
              ),
              ..._pimpinanFeatureCards(context, getVibrantColor),
            ],
          ];

          final pimpinanMenuItems = _pimpinanFeatureCards(
            context,
            getVibrantColor,
          );
          final inPimpinanMode =
              !dash.isAdmin && dash.isPimpinan && auth.isPimpinanMode;

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
                            minExtentHeight:
                                kToolbarHeight +
                                MediaQuery.of(context).padding.top,
                            dash: dash,
                            onLogout: _processLogout,
                            onAvatarTap: _loggedAvatarTapState(
                              isAdmin: auth.isAdmin,
                              isPimpinan: auth.isPimpinan,
                              mode: auth.isPimpinanMode,
                              jabatan: auth.pimpinanJabatan,
                              action: auth.isPimpinan && !auth.isAdmin
                                  ? _showModeSwitchDialog
                                  : null,
                            ),
                            isPimpinanMode: auth.isPimpinanMode,
                            pimpinanJabatan: auth.pimpinanJabatan,
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      CupertinoIcons.clock,
                                      size: 20,
                                      color: colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Jadwal Hari Ini',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    if (dash.schedules.isNotEmpty)
                                      Text(
                                        '=${dash.schedules.length} sesi',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: colorScheme.onSurfaceVariant,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    const Spacer(),
                                    TextButton.icon(
                                      onPressed: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const JadwalMingguanPage(),
                                        ),
                                      ),
                                      label: Text(
                                        'Jadwal Sepekan  >',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                      icon: const Icon(
                                        CupertinoIcons.calendar,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                if (dash.schedules.isEmpty)
                                  _buildEmptySchedule(colorScheme)
                                else
                                  ...dash.schedules.map(
                                    (s) => _buildScheduleCard(
                                      s,
                                      colorScheme,
                                      theme,
                                      dash,
                                    ),
                                  ),
                                _buildSectionHeader(
                                  context,
                                  icon: CupertinoIcons.person,
                                  title: 'Menu Pribadi',
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(height: 10),
                                GridView.count(
                                  crossAxisCount: 4,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  mainAxisSpacing: 10,
                                  crossAxisSpacing: 8,
                                  childAspectRatio: 0.76,
                                  children: personalMenuItems,
                                ),
                                if (dash.isAdmin) ...[
                                  const SizedBox(height: 20),
                                  _buildSectionHeader(
                                    context,
                                    icon: CupertinoIcons.shield,
                                    title: 'Kelola Lembaga',
                                    color: Colors.amber.shade700,
                                    showAdminBadge: true,
                                  ),
                                  const SizedBox(height: 10),
                                  GridView.count(
                                    crossAxisCount: 4,
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    mainAxisSpacing: 10,
                                    crossAxisSpacing: 8,
                                    childAspectRatio: 0.76,
                                    children: adminMenuItems,
                                  ),
                                ],
                                if (inPimpinanMode) ...[
                                  const SizedBox(height: 20),
                                  _buildSectionHeader(
                                    context,
                                    icon: CupertinoIcons.checkmark_seal,
                                    title: 'Mode Pimpinan',
                                    color: Colors.amber.shade700,
                                    badgeText: 'PIMPINAN',
                                  ),
                                  const SizedBox(height: 10),
                                  GridView.count(
                                    crossAxisCount: 4,
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    mainAxisSpacing: 10,
                                    crossAxisSpacing: 8,
                                    childAspectRatio: 0.76,
                                    children: pimpinanMenuItems,
                                  ),
                                ],
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
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            CupertinoIcons.calendar_badge_minus,
            size: 40,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 8),
          Text(
            'Tidak ada jadwal mengajar hari ini.',
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
          ),
        ],
      ),
    );
  }

  /// Kartu tugas Piket Guru (roster mingguan) — berbeda dari jadwal KBM.
  /// Tap membuka halaman daftar kelas hari ini untuk diambil alih.
  Widget _buildPiketDutyCard(
    dynamic s,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    final startTime = (s['start_time'] ?? '').toString();
    final endTime = (s['end_time'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.tertiary.withValues(alpha: 0.45),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PiketHariIniPage(
                  piketStart: startTime,
                  piketEnd: endTime,
                ),
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: colorScheme.tertiary, width: 4),
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
                          color: colorScheme.tertiary,
                        ),
                      ),
                      Text(
                        '–',
                        style: TextStyle(
                          fontSize: 10,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        endTime,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.tertiary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              CupertinoIcons.arrow_left_right,
                              size: 14,
                              color: colorScheme.tertiary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Jadwal Piket',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Siap menggantikan guru yang berhalangan',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.tertiary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'PIKET',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.tertiary,
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

  Widget _buildScheduleCard(
    dynamic s,
    ColorScheme colorScheme,
    ThemeData theme, [
    dynamic dash,
  ]) {
    // Tugas piket guru (roster mingguan) — bukan jadwal KBM kelas. Tap membuka
    // daftar semua kelas hari ini untuk diambil alih (badal) bila guru berhalangan.
    if ((s['_kind'] ?? '').toString() == 'PIKET_GURU') {
      return _buildPiketDutyCard(s, colorScheme, theme);
    }

    final subject = (s['subject_name'] ?? '-').toString();
    final className = (s['class_name'] ?? '-').toString();
    final startTime = (s['start_time'] ?? '').toString();
    final endTime = (s['end_time'] ?? '').toString();
    final session = (s['session_name'] ?? '').toString();
    final status = (s['teaching_status'] ?? 'UTAMA').toString();
    final isPiket = status == 'PIKET';
    final mainTeacher = (s['main_teacher_name'] ?? '').toString();
    final sid = int.tryParse('${s['schedule_id'] ?? s['id'] ?? ''}');
    final sum = (dash != null && sid != null)
        ? (dash.summaries[sid] as Map?)
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPiket
              ? colorScheme.tertiary.withValues(alpha: 0.4)
              : colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openPresensiFromSchedule(
              s,
              subject,
              className,
              session,
              isPiket,
            ),
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
                        style: TextStyle(
                          fontSize: 10,
                          color: colorScheme.onSurfaceVariant,
                        ),
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
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (isPiket) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                CupertinoIcons.arrow_left_right,
                                size: 12,
                                color: colorScheme.tertiary,
                              ),
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
                              _tinyBadge(
                                'H:${sum['hadir'] ?? 0}',
                                Colors.green.shade600,
                              ),
                              _tinyBadge(
                                'S:${sum['sakit'] ?? 0}',
                                Colors.amber.shade700,
                              ),
                              _tinyBadge(
                                'I:${sum['izin'] ?? 0}',
                                Colors.blue.shade600,
                              ),
                              _tinyBadge(
                                'A:${sum['alpa'] ?? 0}',
                                colorScheme.error,
                              ),
                              _tinyBadge(
                                'Sudah ${sum['sudah'] ?? 0}/${sum['total'] ?? 0}',
                                (sum['sudah'] ?? 0) > 0
                                    ? Colors.green.shade600
                                    : Colors.orange.shade600,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isPiket
                              ? colorScheme.tertiary.withValues(alpha: 0.12)
                              : colorScheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isPiket ? 'PIKET' : 'UTAMA',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isPiket
                                ? colorScheme.tertiary
                                : colorScheme.primary,
                          ),
                        ),
                      ),
                      if (sum != null) ...[
                        const SizedBox(height: 4),
                        _absenStatusBadge(sum, colorScheme),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openPresensiFromSchedule(
    dynamic s,
    String subject,
    String className,
    String session,
    bool isPiket,
  ) {
    final scheduleId = int.tryParse('${s['schedule_id'] ?? s['id']}');
    if (scheduleId == null) return;
    final classroomId = int.tryParse('${s['classroom_id']}') ?? 0;
    final rombelId = int.tryParse('${s['rombel_id'] ?? ''}');
    final subjectId = int.tryParse('${s['subject_id'] ?? ''}');
    final jenjangId = int.tryParse('${s['jenjang_id'] ?? ''}');
    final today = DateTime.now();
    final tanggal =
        '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    showCupertinoBottomSheet(
      context: context,
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
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.withValues(alpha: 0.12),
                    child: const Icon(
                      CupertinoIcons.book,
                      color: Colors.green,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Isi Presensi',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Kehadiran murid (H/S/I/A)',
                    style: TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(CupertinoIcons.chevron_right),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.amber.withValues(alpha: 0.12),
                    child: const Icon(
                      CupertinoIcons.star,
                      color: Colors.amber,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Input Nilai',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Nilai harian murid (0–100)',
                    style: TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(CupertinoIcons.chevron_right),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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

  Widget _buildSectionHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    bool showAdminBadge = false,
    String? badgeText,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (showAdminBadge || badgeText != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              badgeText ?? 'ADMIN',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Colors.amber.shade700,
              ),
            ),
          ),
      ],
    );
  }

  Widget _tinyBadge(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      );

  Widget _absenStatusBadge(Map summary, ColorScheme colorScheme) {
    final int sudah = int.tryParse('${summary['sudah'] ?? 0}') ?? 0;
    final bool done = sudah > 0;
    final Color color = done ? Colors.green.shade600 : Colors.orange.shade600;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            done ? CupertinoIcons.checkmark_circle : CupertinoIcons.circle,
            size: 11,
            color: color,
          ),
          const SizedBox(width: 3),
          Text(
            done ? 'Sudah absen' : 'Belum absen',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

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
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 20, color: color),
                  ),
                  if (isAdminOnly)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.amber,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          CupertinoIcons.star,
                          size: 10,
                          color: Colors.black,
                        ),
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
}

class DynamicCurvedHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double maxExtentHeight;
  final double minExtentHeight;
  final DashboardGuruProvider dash;
  final VoidCallback onLogout;
  final VoidCallback? onAvatarTap;
  final bool isPimpinanMode;
  final String? pimpinanJabatan;

  DynamicCurvedHeaderDelegate({
    required this.maxExtentHeight,
    required this.minExtentHeight,
    required this.dash,
    required this.onLogout,
    this.onAvatarTap,
    this.isPimpinanMode = false,
    this.pimpinanJabatan,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final percent = (shrinkOffset / (maxExtentHeight - minExtentHeight)).clamp(
      0.0,
      1.0,
    );
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
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 2.0,
                  ),
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
                Expanded(
                  child: Opacity(
                    opacity: (1.0 - (percent * 1.5)).clamp(0.0, 1.0),
                    child: percent > 0.6
                        ? const SizedBox.shrink()
                        : Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  GestureDetector(
                                    onTap: onAvatarTap,
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            color: colorScheme.onPrimary,
                                            shape: BoxShape.circle,
                                          ),
                                          child: CircleAvatar(
                                            backgroundColor:
                                                colorScheme.primaryContainer,
                                            radius: 24,
                                            child: Icon(
                                              CupertinoIcons.person,
                                              color: colorScheme
                                                  .onPrimaryContainer,
                                              size: 28,
                                            ),
                                          ),
                                        ),
                                        if (isPimpinanMode)
                                          Positioned(
                                            right: -2,
                                            bottom: -2,
                                            child: Container(
                                              padding: const EdgeInsets.all(3),
                                              decoration: const BoxDecoration(
                                                color: Colors.amber,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                CupertinoIcons.checkmark_seal,
                                                size: 12,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              'Ahlan wa Sahlan,',
                                              style: TextStyle(
                                                color: colorScheme.onPrimary
                                                    .withValues(alpha: 0.85),
                                                fontSize: 11,
                                              ),
                                            ),
                                            if (dash.isAdmin) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 5,
                                                  vertical: 1,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: colorScheme
                                                      .errorContainer,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  'ADMIN',
                                                  style: TextStyle(
                                                    fontSize: 8.5,
                                                    fontWeight: FontWeight.bold,
                                                    color: colorScheme
                                                        .onErrorContainer,
                                                  ),
                                                ),
                                              ),
                                            ],
                                            if (isPimpinanMode) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 5,
                                                  vertical: 1,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.amber,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: const Text(
                                                  'PIMPINAN',
                                                  style: TextStyle(
                                                    fontSize: 8.5,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black,
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
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: colorScheme.onPrimary
                                                .withValues(alpha: 0.18),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                CupertinoIcons.calendar_today,
                                                size: 10,
                                                color: colorScheme.onPrimary,
                                              ),
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
    return true;
  }
}

class CurvedUpClipper extends CustomClipper<Path> {
  final double curveDepth;

  CurvedUpClipper({required this.curveDepth});

  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height);

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