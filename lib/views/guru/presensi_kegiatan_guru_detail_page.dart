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
      create: (_) {
        final p = PresensiKegiatanGuruProvider();
        p.init()
            .then((_) => p.fetchTeachersAndAttendance(activityId))
            .catchError((e) {
          debugPrint('Init/fetch kegiatan guru gagal: $e');
        });
        return p;
      },
      child: _PresensiKegiatanGuruBody(
        activityId: activityId,
        activityName: activityName,
      ),
    );
  }
}

class _PresensiKegiatanGuruBody extends StatelessWidget {
  final int activityId;
  final String activityName;

  const _PresensiKegiatanGuruBody({
    super.key,
    required this.activityId,
    required this.activityName,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final provider = context.watch<PresensiKegiatanGuruProvider>();
    final isLoading = provider.isLoading;
    final isSaving = provider.isSaving;
    final teachers = provider.teachers;
    final currentTeacherId = provider.currentTeacherId;
    final isTeacher = provider.isTeacher;

    final myData = teachers.firstWhere(
      (t) => t != null && t['teacher_id'] == currentTeacherId,
      orElse: () => null,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(activityName),
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
                      : isTeacher
                          ? _buildTeacherSingleCardView(
                              context,
                              myData,
                              currentTeacherId,
                              provider,
                              colorScheme,
                            )
                          : _buildAdminListView(
                              teachers,
                              currentTeacherId,
                              provider,
                              colorScheme,
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
                              final p = context.read<PresensiKegiatanGuruProvider>();
                              await p.submitAttendance(activityId);

                              if (!context.mounted) return;

                              if (p.error != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Gagal menyimpan presensi: ${p.error}'),
                                    backgroundColor: colorScheme.error,
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Kehadiran Anda berhasil dikonfirmasi!'),
                                    backgroundColor: colorScheme.primary,
                                  ),
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
                          ? CircularProgressIndicator(color: colorScheme.primary)
                          : const Text('KONFIRMASI KEHADIRAN SAYA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
    );
  }

  // ── TAMPILAN KHUSUS GURU ──
  Widget _buildTeacherSingleCardView(
    BuildContext context,
    Map<String, dynamic>? myData,
    int? currentTeacherId,
    PresensiKegiatanGuruProvider provider,
    ColorScheme colorScheme,
  ) {
    if (myData == null || currentTeacherId == null) {
      return const Center(child: Text('Data profil Anda tidak ditemukan.'));
    }

    final String currentStatus = provider.getStatus(currentTeacherId);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: colorScheme.tertiaryContainer,
                child: Icon(Icons.person, size: 40, color: colorScheme.onTertiaryContainer),
              ),
              const SizedBox(height: 12),
              Text(
                myData['name'] ?? '-',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 4),
              Text(
                myData['username'] ?? '-',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              const Text(
                'Pilih Status Kehadiran Anda:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'hadir', label: Text('Hadir')),
                  ButtonSegment(value: 'sakit', label: Text('Sakit')),
                  ButtonSegment(value: 'izin', label: Text('Izin')),
                  ButtonSegment(value: 'alfa', label: Text('Alfa')),
                ],
                selected: {currentStatus},
                onSelectionChanged: (Set<String> newSelection) {
                  provider.setStatus(currentTeacherId, newSelection.first);
                },
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: colorScheme.tertiary,
                  selectedForegroundColor: colorScheme.onPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── TAMPILAN KHUSUS ADMIN ──
  Widget _buildAdminListView(
    List<dynamic> teachers,
    int? currentTeacherId,
    PresensiKegiatanGuruProvider provider,
    ColorScheme colorScheme,
  ) {
    return ListView.builder(
      itemCount: teachers.length,
      itemBuilder: (context, index) {
        final teacher = teachers[index];
        if (teacher == null) return const SizedBox();

        final int teacherId = teacher['teacher_id'] ?? 0;
        final bool isSelf = teacherId == currentTeacherId;
        final String currentStatus = provider.getStatus(teacherId);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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
                      const SizedBox(height: 2),
                      Text(
                        teacher['username'] ?? '-',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
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
                  onPressed: null,
                  borderRadius: BorderRadius.circular(8),
                  selectedColor: colorScheme.surface,
                  fillColor: colorScheme.tertiary,
                  disabledColor: colorScheme.surfaceContainerHighest,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 32),
                  children: const [
                    Text('H', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    Text('S', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    Text('I', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    Text('A', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}