import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/absensi_guru_kbm_provider.dart';
import '../../utils/snackbar_helper.dart';
import 'package:flutter/cupertino.dart';

class AbsensiGuruKbmPage extends StatelessWidget {
  const AbsensiGuruKbmPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AbsensiGuruKbmProvider()..fetchRoster(AbsensiGuruKbmProvider.defaultDate()),
      child: const _AbsensiGuruKbmBody(),
    );
  }
}

class _AbsensiGuruKbmBody extends StatelessWidget {
  const _AbsensiGuruKbmBody();

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _humanDate(String iso) {
    final parts = iso.split('-');
    if (parts.length != 3) return iso;
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    final m = int.tryParse(parts[1]);
    return '${int.parse(parts[2])} ${m != null ? months[m - 1] : parts[1]} ${parts[0]}';
  }

  Color _statusColor(String status, ColorScheme colorScheme) {
    switch (status.toUpperCase()) {
      case 'HADIR':
        return Colors.green.shade600;
      case 'SAKIT':
        return Colors.amber.shade700;
      case 'IZIN':
        return Colors.blue.shade600;
      case 'ALPA':
        return colorScheme.error;
      default:
        return colorScheme.primary;
    }
  }

  Future<void> _pickDate(BuildContext context, String current) async {
    final now = DateTime.now();
    final initial = DateTime.tryParse(current) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'Pilih Tanggal',
    );
    if (picked == null) return;
    if (!context.mounted) return;
    await context.read<AbsensiGuruKbmProvider>().fetchRoster(_fmt(picked));
  }

  Future<void> _save(BuildContext context, AbsensiGuruKbmProvider provider) async {
    final ok = await provider.save();
    if (!context.mounted) return;
    if (ok) {
      final s = provider.summary;
      showSuccessSnackBar(
        context,
        provider.changedCount == 0
            ? 'Tidak ada perubahan — semua status sudah tersimpan.'
            : 'Absensi guru KBM disimpan (H:${s['hadir']} S:${s['sakit']} I:${s['izin']} A:${s['alpa']}).',
      );
    } else {
      showErrorSnackBar(context, provider.error ?? 'Gagal menyimpan absensi');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AbsensiGuruKbmProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final statuses = ['HADIR', 'SAKIT', 'IZIN', 'ALPA'];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Absensi Guru KBM',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: Column(
        children: [
          // Tanggal picker
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: InkWell(
              onTap: () => _pickDate(context, provider.tanggal),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(CupertinoIcons.calendar_today, color: colorScheme.primary, size: 20),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          provider.tanggal.isEmpty ? 'Pilih Tanggal Hari Ini' : _humanDate(provider.tanggal),
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                        ),
                        Text(
                          'Ketuk untuk pindah tanggal',
                          style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Icon(CupertinoIcons.chevron_right, color: colorScheme.onSurfaceVariant),
                  ],
                ),
              ),
            ),
          ),

          if (provider.roster.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _summaryChip(context, '${provider.hadirCount}', 'H', Colors.green.shade600),
                  const SizedBox(width: 6),
                  _summaryChip(context, '${provider.sakitCount}', 'S', Colors.amber.shade700),
                  const SizedBox(width: 6),
                  _summaryChip(context, '${provider.izinCount}', 'I', Colors.blue.shade600),
                  const SizedBox(width: 6),
                  _summaryChip(context, '${provider.alpaCount}', 'A', colorScheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${provider.roster.length} jadwal • ${provider.changedCount} diubah',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),

          const Divider(height: 1),

          Expanded(
            child: provider.isLoading
                ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
                : provider.roster.isEmpty
                    ? _emptyState(context)
                    : RefreshIndicator(
                        color: colorScheme.primary,
                        onRefresh: () => provider.fetchRoster(provider.tanggal),
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 90),
                          itemCount: provider.roster.length,
                          itemBuilder: (context, index) {
                            final row = provider.roster[index];
                            final scheduleId = int.tryParse('${row['schedule_id'] ?? ''}') ?? 0;
                            final current = (provider.status[scheduleId] ?? 'HADIR').toUpperCase();
                            final teacherName = row['teacher_name'] ?? row['main_teacher_name'] ?? '-';
                            final substitute = row['substitute_name'];

                            return Card(
                              elevation: 0,
                              color: colorScheme.surfaceContainerLow,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
                              ),
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${row['subject_name'] ?? '-'} • ${row['class_name'] ?? '-'}',
                                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '${row['start_time'] ?? ''}-${row['end_time'] ?? ''} • ${row['session_name'] ?? ''}',
                                                style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                                              ),
                                            ],
                                          ),
                                        ),
                                        _statusBadge(context, current),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(CupertinoIcons.person, size: 16, color: colorScheme.onSurfaceVariant),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            substitute != null ? '$teacherName (digantikan $substitute)' : '$teacherName',
                                            style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: statuses.map((status) {
                                        final isSelected = current == status;
                                        final statusColor = _statusColor(status, colorScheme);
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 2),
                                          child: ChoiceChip(
                                            label: Text(
                                              status[0],
                                              style: TextStyle(
                                                color: isSelected ? Colors.white : colorScheme.onSurfaceVariant,
                                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                fontSize: 12,
                                              ),
                                            ),
                                            selected: isSelected,
                                            selectedColor: statusColor,
                                            backgroundColor: colorScheme.surfaceContainerHigh,
                                            showCheckmark: false,
                                            visualDensity: VisualDensity.compact,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            side: BorderSide(
                                              color: isSelected ? statusColor : colorScheme.outlineVariant,
                                            ),
                                            onSelected: (bool selected) {
                                              if (selected) {
                                                provider.setStatus(scheduleId, status);
                                              }
                                            },
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      initialValue: provider.keterangan[scheduleId] ?? '',
                                      decoration: InputDecoration(
                                        labelText: 'Keterangan (opsional)',
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      style: TextStyle(fontSize: 13, color: colorScheme.onSurface),
                                      onChanged: (v) => provider.setKeterangan(scheduleId, v),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: provider.isLoading
          ? null
          : FloatingActionButton.extended(
              onPressed: provider.isSaving ? null : () => _save(context, provider),
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              icon: provider.isSaving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(CupertinoIcons.floppy_disk),
              label: Text(provider.isSaving ? 'Menyimpan...' : 'Simpan Absensi'),
            ),
    );
  }

  Widget _summaryChip(BuildContext context, String count, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _statusBadge(BuildContext context, String status) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = _statusColor(status, colorScheme);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CupertinoIcons.calendar_badge_minus, size: 48, color: colorScheme.outline),
          const SizedBox(height: 10),
          Text(
            'Tidak ada jadwal mengajar di tanggal ini',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}