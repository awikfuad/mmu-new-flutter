import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/student_jadwal_provider.dart';
import '../../widgets/academic_year_selector.dart';

class StudentJadwalPage extends StatefulWidget {
  const StudentJadwalPage({super.key});

  @override
  State<StudentJadwalPage> createState() => _StudentJadwalPageState();
}

class _StudentJadwalPageState extends State<StudentJadwalPage> {
  int? _selectedAcademicYearId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      key: ValueKey(_selectedAcademicYearId),
      create: (_) => StudentJadwalProvider()..load(academicYearId: _selectedAcademicYearId),
      child: Consumer<StudentJadwalProvider>(
        builder: (context, provider, _) {
          final colorScheme = Theme.of(context).colorScheme;

          return Scaffold(
            appBar: AppBar(
              elevation: 0,
              title: const Text(
                'Jadwal Pelajaran',
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
                                ...provider.dayOrder.where((d) => provider.groupedByDay.containsKey(d)).map((day) {
                                  final items = provider.groupedByDay[day]!;
                                  return _buildDaySection(day, items, colorScheme);
                                }),
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

  Widget _buildDaySection(String day, List<dynamic> items, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha:0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha:0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Text(
              day,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: colorScheme.primary,
              ),
            ),
          ),
          ...items.map((r) => _buildScheduleItem(r, colorScheme)),
        ],
      ),
    );
  }

  Widget _buildScheduleItem(Map<String, dynamic> r, ColorScheme colorScheme) {
    final startTime = r['start_time']?.toString() ?? '';
    final endTime = r['end_time']?.toString() ?? '';
    final mapel = r['subject_name']?.toString() ?? '-';
    final guru = r['guru']?.toString() ?? '-';
    final session = r['session_name']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 50,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha:0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              children: [
                Text(
                  startTime,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colorScheme.primary),
                ),
                Text(
                  '–',
                  style: TextStyle(fontSize: 9, color: colorScheme.onSurfaceVariant),
                ),
                Text(
                  endTime,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colorScheme.primary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mapel,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colorScheme.onSurface),
                ),
                const SizedBox(height: 2),
                Text(
                  '$guru${session.isNotEmpty ? ' • $session' : ''}',
                  style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
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
          Icon(Icons.schedule_outlined, size: 56, color: colorScheme.onSurfaceVariant.withValues(alpha:0.5)),
          const SizedBox(height: 10),
          Text(
            'Belum ada jadwal pelajaran.',
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
            5,
            (_) => Container(
              height: 60,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
