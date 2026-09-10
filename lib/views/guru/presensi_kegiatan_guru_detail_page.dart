import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/presensi_kegiatan_guru_provider.dart';

class PresensiKegiatanGuruDetailPage extends StatelessWidget {
  final int activityId;
  final String activityName;

  const PresensiKegiatanGuruDetailPage({
    super.key,
    required this.activityId,
    required this.activityName,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PresensiKegiatanGuruProvider(),
      child: _PresensiKegiatanGuruBody(
        activityId: activityId,
        activityName: activityName,
      ),
    );
  }
}

class _PresensiKegiatanGuruBody extends StatefulWidget {
  final int activityId;
  final String activityName;

  const _PresensiKegiatanGuruBody({
    required this.activityId,
    required this.activityName,
  });

  @override
  State<_PresensiKegiatanGuruBody> createState() => _PresensiKegiatanGuruBodyState();
}

class _PresensiKegiatanGuruBodyState extends State<_PresensiKegiatanGuruBody> {
  @override
  void initState() {
    super.initState();
    final provider = context.read<PresensiKegiatanGuruProvider>();
    provider.init().then((_) {
      provider.fetchTeachersAndAttendance(widget.activityId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final provider = context.watch<PresensiKegiatanGuruProvider>();
    final isLoading = provider.isLoading;
    final isSaving = provider.isSaving;
    final teachers = provider.teachers;
    final currentTeacherId = provider.currentTeacherId;
    final isTeacher = provider.isTeacher;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.activityName),
        backgroundColor: colorScheme.tertiary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: teachers.isEmpty
                      ? const Center(child: Text('Data guru gagal dimuat.'))
                      : ListView.builder(
                          itemCount: teachers.length,
                          itemBuilder: (context, index) {
                            final teacher = teachers[index];
                            if (teacher == null) return const SizedBox();

                            final int teacherId = teacher['teacher_id'] ?? 0;
                            final bool isSelf = teacherId == currentTeacherId;
                            final String currentStatus = provider.getStatus(teacherId);

                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  teacher['name'] ?? '-',
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                ),
                                              ),
                                              if (isSelf) ...[
                                                const SizedBox(width: 6),
                                                Chip(
                                                  label: Text('Saya', style: TextStyle(fontSize: 10, color: colorScheme.onPrimary)),
                                                  backgroundColor: colorScheme.tertiary,
                                                  visualDensity: VisualDensity.compact,
                                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            teacher['username'] ?? '-',
                                            style: TextStyle(color: Colors.grey.shade600),
                                          ),
                                        ],
                                      ),
                                    ),
                                    ToggleButtons(
                                      isSelected: [
                                        currentStatus == 'hadir',
                                        currentStatus == 'sakit',
                                        currentStatus == 'izin',
                                        currentStatus == 'alfa',
                                      ],
                                      onPressed: isSelf
                                          ? (buttonIndex) {
                                              final statuses = ['hadir', 'sakit', 'izin', 'alfa'];
                                              context.read<PresensiKegiatanGuruProvider>().setStatus(teacherId, statuses[buttonIndex]);
                                            }
                                          : null,
                                      borderRadius: BorderRadius.circular(8),
                                      selectedColor: colorScheme.surface,
                                      fillColor: colorScheme.tertiary,
                                      disabledColor: colorScheme.surfaceContainerHighest,
                                      constraints: const BoxConstraints(minWidth: 40, minHeight: 35),
                                      children: const [
                                        Text('H', style: TextStyle(fontWeight: FontWeight.bold)),
                                        Text('S', style: TextStyle(fontWeight: FontWeight.bold)),
                                        Text('I', style: TextStyle(fontWeight: FontWeight.bold)),
                                        Text('A', style: TextStyle(fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                if (!isTeacher) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    color: colorScheme.surfaceContainerLow,
                    child: Text(
                      'Mode Admin: hanya menampilkan rekap kehadiran asatidz.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                ] else
                  Container(
                    padding: const EdgeInsets.all(16),
                    width: double.infinity,
                    color: colorScheme.surface,
                    child: ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              await context.read<PresensiKegiatanGuruProvider>().submitAttendance(widget.activityId);
                              if (!context.mounted) return;
                              final err = context.read<PresensiKegiatanGuruProvider>().error;
                              if (err != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Gagal menyimpan presensi: $err'), backgroundColor: colorScheme.error),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: const Text('Kehadiran Anda berhasil dikonfirmasi!'), backgroundColor: colorScheme.primary),
                                );
                                Navigator.pop(context);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.tertiary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: isSaving
                          ? CircularProgressIndicator(color: colorScheme.onPrimary)
                          : const Text('KONFIRMASI KEHADIRAN SAYA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
    );
  }
}
