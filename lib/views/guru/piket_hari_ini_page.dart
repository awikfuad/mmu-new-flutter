import 'package:flutter/material.dart';
import '../../widgets/shimmer_loader.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../providers/piket_hari_ini_provider.dart';
import '../../utils/snackbar_helper.dart';
import 'presensi_kelas_page.dart';

/// Halaman "Piket Hari Ini": daftar seluruh jadwal kelas hari ini yang belum
/// selesai. Guru piket dapat memilih kelas untuk diambil alih (badal) lalu
/// mengisi presensi murid. Dipakai dari kartu tugas piket di dashboard guru.
class PiketHariIniPage extends StatelessWidget {
  final String? piketStart;
  final String? piketEnd;

  const PiketHariIniPage({super.key, this.piketStart, this.piketEnd});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PiketHariIniProvider()
        ..configure(piketStart: piketStart, piketEnd: piketEnd)
        ..load(),
      child: _PiketHariIniBody(piketStart: piketStart, piketEnd: piketEnd),
    );
  }
}

class _PiketHariIniBody extends StatelessWidget {
  final String? piketStart;
  final String? piketEnd;

  const _PiketHariIniBody({this.piketStart, this.piketEnd});

  int? _toInt(dynamic v) => int.tryParse('${v ?? ''}');

  bool _isPiket(dynamic s) =>
      (s['teaching_status'] ?? '').toString().toUpperCase() == 'PIKET';

  Future<void> _claim(BuildContext context, dynamic s) async {
    final scheduleId = _toInt(s['schedule_id'] ?? s['id']);
    if (scheduleId == null) return;

    final subject = (s['subject_name'] ?? '-').toString();
    final className = (s['class_name'] ?? '-').toString();
    final mainTeacher = (s['main_teacher_name'] ?? '-').toString();

    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Ambil Alih Kelas?'),
        content: Text(
          'Anda akan menggantikan guru kelas ini dan dapat mengisi presensinya.\n\n'
          '$subject — $className\nGuru utama: $mainTeacher',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ambil Alih'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;

    final provider = context.read<PiketHariIniProvider>();
    final err = await provider.claimPiket(scheduleId);
    if (!context.mounted) return;
    if (err != null) {
      showErrorSnackBar(context, err);
      return;
    }

    showSuccessSnackBar(context, 'Kelas berhasil diambil alih.');
    // Buka presensi kelas yang baru diambil alih.
    await Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (_) => PresensiKelasPage(
          scheduleId: scheduleId,
          classroomId: _toInt(s['classroom_id']) ?? 0,
          subjectName: '$subject (Piket)',
          className: className,
          sessionName: (s['session_name'] ?? 'PAGI').toString(),
          rombelId: _toInt(s['rombel_id']),
        ),
      ),
    );
    if (context.mounted) {
      context.read<PiketHariIniProvider>().load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PiketHariIniProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final schedules = provider.schedules;
    final window = (piketStart != null && piketEnd != null)
        ? 'Piket $piketStart–$piketEnd'
        : 'Jadwal piket hari ini';

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colorScheme.tertiary,
        foregroundColor: colorScheme.onTertiary,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Piket Hari Ini',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(window, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
      body: provider.isLoading
          ? _buildShimmer(context)
          : RefreshIndicator(
              onRefresh: () => context.read<PiketHariIniProvider>().load(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.tertiary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: colorScheme.tertiary.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        Icon(CupertinoIcons.info_circle,
                            size: 20, color: colorScheme.tertiary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Seluruh jadwal kelas hari ini ditampilkan (semua jenjang). '
                            'Kelas yang bertanda "Jam Piket" beririsan dengan jam piket Anda. '
                            'Pilih kelas yang guru utamanya berhalangan untuk diambil alih.',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (provider.error != null)
                    _buildEmpty(
                      colorScheme,
                      icon: CupertinoIcons.cloud,
                      text: provider.error!,
                    )
                  else if (schedules.isEmpty)
                    _buildEmpty(
                      colorScheme,
                      icon: CupertinoIcons.calendar_badge_minus,
                      text: 'Tidak ada jadwal kelas hari ini.',
                    )
                  else
                    ...schedules.map((s) => _buildCard(context, s)),
                ],
              ),
            ),
    );
  }

  Widget _buildShimmer(BuildContext context) {
  return ThemedShimmer(
    child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        const ShimmerBox(height: 64, radius: 12),
        const SizedBox(height: 16),
        ...List.generate(
          5,
          (_) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant),
            ),
            child: Row(
              children: const [
                ShimmerBox(height: 44, width: 44, radius: 22),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(height: 14, width: 160),
                      SizedBox(height: 8),
                      ShimmerBox(height: 18, width: 120, radius: 6),
                      SizedBox(height: 8),
                      ShimmerBox(height: 12, width: 180),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildEmpty(ColorScheme colorScheme,
      {required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Icon(icon,
              size: 56,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
          const SizedBox(height: 8),
          Text(text,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, dynamic s) {
    final colorScheme = Theme.of(context).colorScheme;
    final provider = context.read<PiketHariIniProvider>();
    final isPiket = _isPiket(s);
    final within = provider.withinPiket(s);
    final finished = provider.isFinished(s);
    final accent =
        (isPiket || within) ? colorScheme.tertiary : colorScheme.primary;
    final jenjang = provider.jenjangName(s);
    final mainTeacher = (s['main_teacher_name'] ?? '-').toString();
    final substitute = (s['substitute_teacher_name'] ?? '').toString();

    return Opacity(
      opacity: finished ? 0.5 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ??
              colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withValues(alpha: 0.35)),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _claim(context, s),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: accent.withValues(alpha: 0.15),
                    child: Icon(
                      (isPiket || within)
                          ? CupertinoIcons.arrow_left_right
                          : CupertinoIcons.person_2,
                      size: 22,
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (s['subject_name'] ?? '-').toString(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (jenjang.isNotEmpty)
                              _chip(jenjang, colorScheme.primary),
                            if (within)
                              _chip('Jam Piket', colorScheme.tertiary),
                            if (finished)
                              _chip('Selesai', colorScheme.outline),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${s['class_name'] ?? '-'} · ${s['session_name'] ?? '-'} · Guru: $mainTeacher',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (isPiket && substitute.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Piket: $substitute',
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.tertiary,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${s['start_time'] ?? ''}–${s['end_time'] ?? ''}',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: accent,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Icon(CupertinoIcons.chevron_right,
                          size: 18, color: colorScheme.outline),
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

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style:
            TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
