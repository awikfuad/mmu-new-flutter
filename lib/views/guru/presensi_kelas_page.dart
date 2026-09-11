import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/presensi_kelas_provider.dart';
import '../../utils/foto_helper.dart';

class PresensiKelasPage extends StatelessWidget {
  final int scheduleId;
  final int classroomId;
  final String subjectName;
  final String className;
  final String sessionName;
  final int? rombelId;

  const PresensiKelasPage({
    super.key,
    required this.scheduleId,
    required this.classroomId,
    required this.subjectName,
    required this.className,
    this.sessionName = 'PAGI',
    this.rombelId,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PresensiKelasProvider()..fetchStudents(classroomId, sessionName: sessionName, rombelId: rombelId),
      child: _PresensiKelasBody(
        scheduleId: scheduleId,
        classroomId: classroomId,
        subjectName: subjectName,
        className: className,
        sessionName: sessionName,
      ),
    );
  }
}

class _PresensiKelasBody extends StatelessWidget {
  final int scheduleId;
  final int classroomId;
  final String subjectName;
  final String className;
  final String sessionName;

  const _PresensiKelasBody({
    required this.scheduleId,
    required this.classroomId,
    required this.subjectName,
    required this.className,
    required this.sessionName,
  });

  // Helper warna adaptif untuk tiap status
  Color _getStatusColor(String status, ColorScheme colorScheme) {
    switch (status) {
      case 'hadir':
        return Colors.green.shade600;
      case 'sakit':
        return Colors.amber.shade700;
      case 'izin':
        return Colors.blue.shade600;
      case 'alfa':
        return colorScheme.error;
      default:
        return colorScheme.primary;
    }
  }

  Widget _buildCountChip(String label, Color color, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final provider = context.watch<PresensiKelasProvider>();
    final students = provider.students;
    final isLoading = provider.isLoading;
    final isSaving = provider.isSaving;
    final attendanceStatus = provider.attendanceStatus;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subjectName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              'Kelas: $className',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : Column(
              children: [
                // Ringkasan jumlah hadir/sakit/izin/alpa/belum
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                  color: colorScheme.surfaceContainerLow,
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _buildCountChip('Hadir ${provider.hadirCount}', Colors.green.shade600, provider.hadirCount),
                      _buildCountChip('Sakit ${provider.sakitCount}', Colors.amber.shade700, provider.sakitCount),
                      _buildCountChip('Izin ${provider.izinCount}', Colors.blue.shade600, provider.izinCount),
                      _buildCountChip('Alpa ${provider.alfaCount}', colorScheme.error, provider.alfaCount),
                      _buildCountChip('Belum ${provider.belumCount}', provider.belumCount > 0 ? Colors.orange.shade600 : Colors.green.shade600, provider.belumCount),
                      _buildCountChip('Sudah ${provider.sudahCount}/${provider.totalCount}', colorScheme.primary, provider.sudahCount),
                    ],
                  ),
                ),
                // Header Bar List
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: colorScheme.surfaceContainerHighest,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Nama Murid / Santri',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Text(
                        'H  |  S  |  I  |  A',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      final student = students[index];
                      final String nim = student['nim']?.toString() ?? '';
                      String currentStatus = attendanceStatus[nim] ?? 'hadir';
                      final already = provider.alreadyAbsenMap[nim] ?? false;
                      final prev = provider.previousStatusMap[nim];

                      return Card(
                        elevation: 0,
                        color: already ? colorScheme.surfaceContainerHigh : colorScheme.surfaceContainerLow,
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                              color: already ? colorScheme.primary.withValues(alpha: 0.4) : colorScheme.outlineVariant.withValues(alpha: 0.5)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          child: Row(
                            children: [
                              // Foto murid
                              Builder(builder: (_) {
                                final fotoUrl = resolveFotoUrl(student['foto']?.toString());
                                return CircleAvatar(
                                  radius: 18,
                                  backgroundColor: colorScheme.primaryContainer,
                                  backgroundImage: cachedFotoProvider(fotoUrl),
                                  onBackgroundImageError: (_, _) {},
                                  child: fotoUrl == null
                                      ? Icon(Icons.person, size: 18, color: colorScheme.onPrimaryContainer)
                                      : null,
                                );
                              }),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            student['name'] ?? '-',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500,
                                              color: colorScheme.onSurface,
                                            ),
                                          ),
                                        ),
                                        if (already)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: colorScheme.primary.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text('Sudah', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colorScheme.primary)),
                                          ),
                                      ],
                                    ),
                                    Text(
                                      '${student['nim'] ?? '-'}${prev != null && prev.isNotEmpty && prev.toLowerCase() != currentStatus ? ' • sebelumnya: $prev' : ''}',
                                      style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: ['hadir', 'sakit', 'izin', 'alfa'].map((status) {
                                  final isSelected = currentStatus == status;
                                  final statusColor = _getStatusColor(status, colorScheme);

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                                    child: ChoiceChip(
                                      label: Text(
                                        status[0].toUpperCase(),
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
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      side: BorderSide(
                                        color: isSelected ? statusColor : colorScheme.outlineVariant,
                                      ),
                                      onSelected: (bool selected) {
                                        if (selected) {
                                          context.read<PresensiKelasProvider>().setStatus(nim, status);
                                        }
                                      },
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                // Bottom Button
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    border: Border(top: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3))),
                  ),
                  child: ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            final skippedNames = await context.read<PresensiKelasProvider>().submitAttendance(
                                  scheduleId: scheduleId,
                                  sessionName: sessionName,
                                );
                            if (!context.mounted) return;
                            final prov = context.read<PresensiKelasProvider>();
                            String message = 'Presensi KBM Berhasil Disimpan! H:${prov.hadirCount} S:${prov.sakitCount} I:${prov.izinCount} A:${prov.alfaCount}';
                            if (skippedNames.isNotEmpty) {
                              message += '\n${skippedNames.length} santri tanpa akun siswa diabaikan: ${skippedNames.take(3).join(', ')}${skippedNames.length > 3 ? ', ...' : ''}';
                            } else if (prov.submittedCount == 0) {
                              message = 'Tidak ada perubahan — semua status sudah sesuai.';
                            } else {
                              message = 'Presensi ${prov.submittedCount} santri disimpan (H:${prov.hadirCount} S:${prov.sakitCount} I:${prov.izinCount} A:${prov.alfaCount})';
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(message),
                                backgroundColor: colorScheme.primary,
                                // color: colorScheme.onPrimary,
                              ),
                            );
                            Navigator.pop(context);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: isSaving
                        ? SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: colorScheme.onPrimary,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'SIMPAN PRESENSI',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                )
              ],
            ),
    );
  }
}