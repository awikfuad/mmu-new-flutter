import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/student_prestasi_provider.dart';
import '../../utils/format.dart';
import '../../widgets/academic_year_selector.dart';

class StudentPrestasiPage extends StatefulWidget {
  const StudentPrestasiPage({super.key});

  @override
  State<StudentPrestasiPage> createState() => _StudentPrestasiPageState();
}

class _StudentPrestasiPageState extends State<StudentPrestasiPage> {
  int? _selectedAcademicYearId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      key: ValueKey(_selectedAcademicYearId),
      create: (_) => StudentPrestasiProvider()..load(academicYearId: _selectedAcademicYearId),
      child: Consumer<StudentPrestasiProvider>(
        builder: (context, provider, _) {
          final colorScheme = Theme.of(context).colorScheme;

          return Scaffold(
            appBar: AppBar(
              elevation: 0,
              title: const Text(
                'Prestasi & Pelanggaran',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              backgroundColor: colorScheme.surface,
              foregroundColor: colorScheme.onSurface,
            ),
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: AcademicYearSelector(
                    selectedId: _selectedAcademicYearId,
                    compact: true,
                    onChanged: (id) => setState(() => _selectedAcademicYearId = id),
                  ),
                ),
                Expanded(
                  child: provider.isLoading
                      ? _buildShimmerLoading(context)
                      : RefreshIndicator(
                          onRefresh: () => provider.load(academicYearId: _selectedAcademicYearId),
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            children: [
                              _buildSummaryCards(provider, colorScheme),
                              const SizedBox(height: 16),
                              if (provider.records.isEmpty)
                                _buildEmptyState(colorScheme)
                              else
                                ...provider.records.map((r) => _buildCard(r, colorScheme)),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCards(StudentPrestasiProvider provider, ColorScheme colorScheme) {
    return Row(
      children: [
        _summaryItem('Prestasi', provider.prestasiCount.toString(), Colors.green, colorScheme),
        const SizedBox(width: 10),
        _summaryItem('Pelanggaran', provider.pelanggaranCount.toString(), Colors.red, colorScheme),
        const SizedBox(width: 10),
        _summaryItem('Total Poin', provider.totalPoin.toString(), colorScheme.primary, colorScheme),
      ],
    );
  }

  Widget _summaryItem(String label, String value, Color color, ColorScheme colorScheme) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha:0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha:0.2)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> r, ColorScheme colorScheme) {
    final tipe = (r['tipe'] ?? '').toString().toUpperCase();
    final isPrestasi = tipe == 'PRESTASI';
    final tanggal = dateOnly(r['tanggal']?.toString());
    final kategori = r['kategori']?.toString() ?? '-';
    final deskripsi = r['deskripsi']?.toString() ?? '';
    final poin = (r['poin'] as num?) ?? 0;
    final catatan = r['catatan']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isPrestasi ? Colors.green : Colors.red).withValues(alpha:0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isPrestasi ? Colors.green : Colors.red).withValues(alpha:0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPrestasi ? Icons.emoji_events_outlined : Icons.warning_amber_rounded,
              size: 20,
              color: isPrestasi ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (isPrestasi ? Colors.green : Colors.red).withValues(alpha:0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tipe,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: isPrestasi ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      kategori,
                      style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
                    ),
                    const Spacer(),
                    Text(
                      tanggal,
                      style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  deskripsi,
                  style: TextStyle(fontSize: 13, color: colorScheme.onSurface),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.star_outline, size: 14, color: colorScheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      '${poin.toInt()} poin',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.primary),
                    ),
                    if (catatan != null && catatan.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          catatan,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 50),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.emoji_events_outlined, size: 56, color: colorScheme.onSurfaceVariant.withValues(alpha:0.5)),
          const SizedBox(height: 10),
          Text(
            'Belum ada catatan prestasi / pelanggaran.',
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final highlightColor = isDark ? Colors.grey.shade700 : Colors.grey.shade100;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(height: 60, margin: const EdgeInsets.only(bottom: 16)),
            ...List.generate(
              3,
              (_) => Container(
                height: 80,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
