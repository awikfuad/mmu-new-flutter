import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/guru_piket_provider.dart';
import 'guru/presensi_kelas_page.dart';


class GuruPiketPage extends StatelessWidget {
  const GuruPiketPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GuruPiketProvider()..fetchAllSchedules(),
      child: const _GuruPiketBody(),
    );
  }
}

class _GuruPiketBody extends StatelessWidget {
  const _GuruPiketBody();

  int? _toInt(dynamic value) => int.tryParse('${value ?? ''}');

  Future<void> _openPresensi(BuildContext context, dynamic schedule) async {
    final scheduleId = _toInt(schedule['schedule_id']) ?? _toInt(schedule['id']);
    final classroom = schedule['class_name'] ?? 'Kelas';

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PresensiKelasPage(
          scheduleId: scheduleId ?? 0,
          classroomId: _toInt(schedule['classroom_id']) ?? 0,
          subjectName: '${schedule['subject_name'] ?? '-'} (Badal)',
          className: classroom,
          sessionName: schedule['session_name'] ?? 'PAGI',
          rombelId: _toInt(schedule['rombel_id']),
        ),
      ),
    );

    if (!context.mounted) return;
    context.read<GuruPiketProvider>().fetchAllSchedules();
  }

  Future<void> _claimPiket(BuildContext context, dynamic schedule) async {
    final scheduleId = _toInt(schedule['schedule_id']) ?? _toInt(schedule['id']);
    final className = schedule['class_name'] ?? 'Kelas';
    final colorScheme = Theme.of(context).colorScheme;
    final provider = context.read<GuruPiketProvider>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surfaceContainerHigh,
        title: Text(
          'Ambil Alih Piket',
          style: TextStyle(color: colorScheme.onSurface),
        ),
        content: Text(
          'Anda akan menggantikan Guru Utama di kelas $className (${schedule['subject_name'] ?? '-'}). Lanjutkan?',
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal', style: TextStyle(color: colorScheme.outline)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ambil Alih'),
          ),
        ],
      ),
    );

    if (confirm != true || scheduleId == null) return;

    final success = await provider.claimPiket(schedule);
    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Anda sekarang menjadi Guru Piket di kelas ini.'),
          backgroundColor: colorScheme.primary,
          // color: colorScheme.onPrimary,
        ),
      );
      await _openPresensi(context, schedule);
    } else {
      final err = context.read<GuruPiketProvider>().error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err ?? 'Gagal mengambil alih piket'),
          backgroundColor: colorScheme.error,
          // color: colorScheme.onError,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GuruPiketProvider>();
    final isLoading = provider.isLoading;
    final currentDay = provider.currentDay;
    final todaySchedules = provider.todaySchedules;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mode Guru Piket / Badal',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        // scaffoldColorScheme: colorScheme,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : RefreshIndicator(
              color: colorScheme.primary,
              onRefresh: () => context.read<GuruPiketProvider>().fetchAllSchedules(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                children: [
                  Card(
                    elevation: 0,
                    color: colorScheme.surfaceContainerHighest,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: colorScheme.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Kelas lain hari $currentDay yang bisa dibadalkan. Ketuk "Ambil Alih" untuk menjadi guru pengganti, lalu isi presensi.',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (todaySchedules.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 60),
                      child: Center(
                        child: Text(
                          'Tidak ada jadwal KBM hari ini.',
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                      ),
                    )
                  else
                    ...todaySchedules.map((s) => _buildScheduleCard(context, s)),
                ],
              ),
            ),
    );
  }

  Widget _buildScheduleCard(BuildContext context, dynamic schedule) {
    final provider = context.read<GuruPiketProvider>();
    final scheduleId = _toInt(schedule['schedule_id']) ?? _toInt(schedule['id']);
    final classroom = schedule['class_name'] ?? 'Kelas';
    final teacher = schedule['main_teacher_name'] ?? 'Guru';
    final substituteId = _toInt(schedule['substitute_teacher_id']);
    final myTeacherId = provider.myTeacherId;
    final claimingId = provider.claimingId;
    final colorScheme = Theme.of(context).colorScheme;

    final bool isMyPiket = myTeacherId != null && substituteId == myTeacherId;
    final bool hasOtherPiket = substituteId != null && !isMyPiket && myTeacherId != null;
    final bool isClaiming = claimingId == scheduleId;
    final bool isActionable = isMyPiket || (!hasOtherPiket && substituteId == null);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(Icons.swap_horiz, color: colorScheme.onPrimaryContainer, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    schedule['subject_name'] ?? '-',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Kelas: $classroom\nGuru Asli: $teacher\nJam: ${schedule['start_time']} - ${schedule['end_time']}',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: isMyPiket
                      ? _statusChip(
                          context,
                          'Piket Anda',
                          colorScheme.primaryContainer,
                          colorScheme.onPrimaryContainer,
                        )
                      : hasOtherPiket
                          ? _statusChip(
                              context,
                              'Sudah ada piket: ${schedule['substitute_teacher_name'] ?? '-'}',
                              colorScheme.tertiaryContainer,
                              colorScheme.onTertiaryContainer,
                            )
                          : _statusChip(
                              context,
                              'Belum ada piket',
                              colorScheme.surfaceContainerHigh,
                              colorScheme.onSurfaceVariant,
                            ),
                ),
                if (isActionable) ...[
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 38,
                    child: ElevatedButton.icon(
                      onPressed: isClaiming ? null : () => _claimPiket(context, schedule),
                      icon: isClaiming
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.onPrimary,
                              ),
                            )
                          : Icon(
                              isMyPiket ? Icons.fact_check : Icons.how_to_reg,
                              size: 18,
                            ),
                      label: Text(isMyPiket ? 'Presensi' : 'Ambil Alih'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isMyPiket ? colorScheme.primary : colorScheme.secondary,
                        foregroundColor: isMyPiket ? colorScheme.onPrimary : colorScheme.onSecondary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(BuildContext context, String text, Color backgroundColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}