import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/presensi_kegiatan_provider.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/shimmer_loader.dart';
import 'package:flutter/cupertino.dart';

Widget _buildShimmer(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  return ThemedShimmer(
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            itemCount: 8,
            itemBuilder: (context, index) => const Card(
              margin: EdgeInsets.symmetric(vertical: 4),
              elevation: 0,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  children: [
                    ShimmerBox(height: 36, width: 36, radius: 18),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShimmerBox(height: 13, width: 160),
                          SizedBox(height: 6),
                          ShimmerBox(height: 11, width: 90),
                        ],
                      ),
                    ),
                    SizedBox(width: 8),
                    ShimmerBox(height: 28, width: 48, radius: 8),
                    SizedBox(width: 6),
                    ShimmerBox(height: 28, width: 48, radius: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class PresensiKegiatanDetailPage extends StatelessWidget {
  final int activityId;
  final String activityName;

  const PresensiKegiatanDetailPage({
    super.key,
    required this.activityId,
    required this.activityName,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PresensiKegiatanProvider()..fetchStudentsAndAttendance(activityId),
      child: _PresensiKegiatanDetailBody(
        activityId: activityId,
        activityName: activityName,
      ),
    );
  }
}

class _PresensiKegiatanDetailBody extends StatelessWidget {
  final int activityId;
  final String activityName;

  const _PresensiKegiatanDetailBody({
    required this.activityId,
    required this.activityName,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final provider = context.watch<PresensiKegiatanProvider>();
    final isLoading = provider.isLoading;
    final isSaving = provider.isSaving;
    final filteredStudents = provider.filteredStudents;
    final todayDate = provider.todayDate;

    return Scaffold(
      appBar: AppBar(
        title: Text(activityName),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Chip(
              label: Text(todayDate, style: TextStyle(color: colorScheme.secondary, fontWeight: FontWeight.bold)),
              backgroundColor: colorScheme.surface,
            ),
          )
        ],
      ),
      body: isLoading
          ? _buildShimmer(context)
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: TextField(
                    onChanged: (q) => context.read<PresensiKegiatanProvider>().filterSearch(q),
                    decoration: InputDecoration(
                      labelText: 'Cari Nama Santri atau Kelas...',
                      prefixIcon: Icon(CupertinoIcons.search, color: colorScheme.onSurface),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                Expanded(
                  child: filteredStudents.isEmpty
                      ? const Center(child: Text('Santri tidak ditemukan.'))
                      : ListView.builder(
                          itemCount: filteredStudents.length,
                          itemBuilder: (context, index) {
                            final student = filteredStudents[index];
                            final String nim = student['nim']?.toString() ?? '';
                            final String currentStatus = provider.getStatus(nim);

                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(student['student_name'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                          const SizedBox(height: 2),
                                          Text('Kelas: ${student['class_name'] ?? '-'}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
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
                                      onPressed: (buttonIndex) {
                                        final statuses = ['hadir', 'sakit', 'izin', 'alfa'];
                                        context.read<PresensiKegiatanProvider>().setStatus(nim, statuses[buttonIndex]);
                                      },
                                      borderRadius: BorderRadius.circular(8),
                                      selectedColor: colorScheme.surface,
                                      fillColor: colorScheme.secondary,
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
                Container(
                  padding: const EdgeInsets.all(16),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
                  ),
                  child: ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            await context.read<PresensiKegiatanProvider>().submitAttendance(activityId);
                            if (!context.mounted) return;
                            final err = context.read<PresensiKegiatanProvider>().error;
                            if (err != null) {
                              showErrorSnackBar(context, 'Gagal menyimpan: $err', duration: const Duration(seconds: 5));
                            } else {
                              showSuccessSnackBar(context, 'Presensi kegiatan berhasil disimpan!');
                              Navigator.pop(context);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.secondary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: isSaving
                        ? ShimmerSpinner(size: 24, color: colorScheme.onPrimary, strokeWidth: 2.5)
                        : const Text('SIMPAN PRESENSI KEGIATAN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
    );
  }
}
