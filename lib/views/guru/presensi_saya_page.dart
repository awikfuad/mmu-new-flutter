import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/presensi_saya_provider.dart';
import 'input_nilai_harian_page.dart';
import 'presensi_kelas_page.dart';

class PresensiSayaPage extends StatelessWidget {
  const PresensiSayaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PresensiSayaProvider()..load(),
      child: const _PresensiSayaBody(),
    );
  }
}

class _PresensiSayaBody extends StatelessWidget {
  const _PresensiSayaBody();

  int? _toInt(dynamic value) => int.tryParse('${value ?? ''}');

  bool _isPiket(dynamic s) =>
      (s['teaching_status'] ?? '').toString().toUpperCase() == 'PIKET';

  Widget _badge(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withValues(alpha: 0.3))),
        child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color)),
      );

  void _openScheduleOptions(BuildContext context, dynamic schedule) {
    final scheduleId = _toInt(schedule['schedule_id']) ?? _toInt(schedule['id']);
    if (scheduleId == null) return;

    final isPiket = _isPiket(schedule);
    final subject = (schedule['subject_name'] ?? '-').toString();
    final className = (schedule['class_name'] ?? '-').toString();
    final session = (schedule['session_name'] ?? 'PAGI').toString();
    final classroomId = _toInt(schedule['classroom_id']) ?? 0;
    final rombelId = _toInt(schedule['rombel_id']);
    final subjectId = _toInt(schedule['subject_id']);
    final jenjangId = _toInt(schedule['jenjang_id']);
    final today = DateTime.now();
    final tanggal =
        '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
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
                      color: cs.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  subject,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface),
                ),
                const SizedBox(height: 2),
                Text(
                  '$className · $session${isPiket ? ' · Badal' : ''}',
                  style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
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
                          sessionName: session,
                          rombelId: rombelId,
                        ),
                      ),
                    ).then((_) {
                      if (context.mounted) context.read<PresensiSayaProvider>().load();
                    });
                  },
                ),
                const SizedBox(height: 4),
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PresensiSayaProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final schedules = provider.schedules;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Presensi KBM Kelas',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Jadwal mengajar hari ${provider.currentDay}',
                style: const TextStyle(fontSize: 12)),
          ],
        ),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => context.read<PresensiSayaProvider>().load(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: colorScheme.primary.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 20, color: colorScheme.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Pilih jadwal untuk mengisi presensi murid — termasuk kelas piket/badal Anda.',
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
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        children: [
                          Icon(Icons.cloud_off_outlined,
                              size: 48,
                              color: colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.5)),
                          const SizedBox(height: 8),
                          Text(provider.error!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    )
                  else if (schedules.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 60),
                      child: Column(
                        children: [
                          Icon(Icons.event_busy_outlined,
                              size: 56,
                              color: colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.4)),
                          const SizedBox(height: 8),
                          Text('Tidak ada jadwal mengajar hari ini.',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    )
                  else
                    ...schedules.map((s) => _buildScheduleCard(context, s)),
                ],
              ),
            ),
    );
  }

  Widget _buildScheduleCard(BuildContext context, dynamic s) {
    final provider = context.watch<PresensiSayaProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final isPiket = _isPiket(s);
    final accent = isPiket ? colorScheme.tertiary : colorScheme.primary;
    final mainTeacher = (s['main_teacher_name'] ?? '').toString();
    // Admin melihat seluruh jadwal → tampilkan guru pengajar
    final teacherLabel = provider.isAdmin && mainTeacher.isNotEmpty
        ? ' · Guru: $mainTeacher'
        : '';
    final sid = _toInt(s['schedule_id'] ?? s['id']);
    final sum = sid != null ? provider.summaries[sid] : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _openScheduleOptions(context, s),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: accent.withValues(alpha: 0.15),
                  child: Icon(isPiket ? Icons.swap_horiz : Icons.menu_book_outlined,
                      size: 22, color: accent),
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
                      const SizedBox(height: 2),
                      Text(
                        '${s['class_name'] ?? '-'} · ${s['session_name'] ?? '-'}'
                        '$teacherLabel'
                        '${isPiket && mainTeacher.isNotEmpty ? ' · Badal dari $mainTeacher' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (sum != null) ...[
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 4,
                          runSpacing: 2,
                          children: [
                            _badge('H:${sum['hadir'] ?? 0}', Colors.green.shade600),
                            _badge('S:${sum['sakit'] ?? 0}', Colors.amber.shade700),
                            _badge('I:${sum['izin'] ?? 0}', Colors.blue.shade600),
                            _badge('A:${sum['alpa'] ?? 0}', colorScheme.error),
                            _badge('Sudah ${sum['sudah'] ?? 0}/${sum['total'] ?? 0}', (sum['sudah'] ?? 0) > 0 ? Colors.green.shade600 : Colors.orange.shade600),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isPiket ? 'PIKET' : 'UTAMA',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: accent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${s['start_time'] ?? ''}–${s['end_time'] ?? ''}',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 18, color: colorScheme.outline),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
