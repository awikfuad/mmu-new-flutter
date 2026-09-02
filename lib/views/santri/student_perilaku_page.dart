import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/student_perilaku_provider.dart';
import '../../utils/format.dart';
import '../../widgets/academic_year_selector.dart';

class StudentPerilakuPage extends StatefulWidget {
  const StudentPerilakuPage({super.key});

  @override
  State<StudentPerilakuPage> createState() => _StudentPerilakuPageState();
}

class _StudentPerilakuPageState extends State<StudentPerilakuPage> {
  int? _selectedAcademicYearId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      key: ValueKey(_selectedAcademicYearId),
      create: (_) => StudentPerilakuProvider()..load(academicYearId: _selectedAcademicYearId),
      child: Consumer<StudentPerilakuProvider>(
        builder: (context, provider, _) {
          final colorScheme = Theme.of(context).colorScheme;

          return Scaffold(
            appBar: AppBar(
              elevation: 0,
              title: const Text(
                'Perilaku Harian',
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

  Widget _buildCard(Map<String, dynamic> r, ColorScheme colorScheme) {
    final tanggal = dateOnly(r['tanggal']?.toString());
    final kerajinan = r['kerajinan']?.toString() ?? '-';
    final kedisiplinan = r['kedisiplinan']?.toString() ?? '-';
    final kebersihan = r['kebersihan']?.toString() ?? '-';
    final catatan = r['catatan']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha:0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                tanggal,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildPredikatChip('Kerajinan', kerajinan, colorScheme),
              const SizedBox(width: 8),
              _buildPredikatChip('Kedisiplinan', kedisiplinan, colorScheme),
              const SizedBox(width: 8),
              _buildPredikatChip('Kebersihan', kebersihan, colorScheme),
            ],
          ),
          if (catatan != null && catatan.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              catatan,
              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPredikatChip(String label, String predikat, ColorScheme colorScheme) {
    Color bgColor;
    switch (predikat.toUpperCase()) {
      case 'SANGAT_BAIK':
        bgColor = Colors.green;
        break;
      case 'BAIK':
        bgColor = Colors.blue;
        break;
      case 'CUKUP':
        bgColor = Colors.orange;
        break;
      case 'KURANG':
        bgColor = Colors.red;
        break;
      default:
        bgColor = colorScheme.outline;
    }

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: bgColor.withValues(alpha:0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: bgColor.withValues(alpha:0.3)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 9, color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 2),
            Text(
              predikat.replaceAll('_', ' '),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: bgColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 50),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.psychology_outlined, size: 56, color: colorScheme.onSurfaceVariant.withValues(alpha:0.5)),
          const SizedBox(height: 10),
          Text(
            'Belum ada catatan perilaku.',
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
          children: List.generate(
            4,
            (_) => Container(
              height: 80,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
