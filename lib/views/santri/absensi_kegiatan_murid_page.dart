import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/absensi_murid_provider.dart';
import '../../utils/format.dart';
import '../../widgets/academic_year_selector.dart';

class AbsensiKegiatanMuridPage extends StatefulWidget {
  const AbsensiKegiatanMuridPage({super.key});

  @override
  State<AbsensiKegiatanMuridPage> createState() =>
      _AbsensiKegiatanMuridPageState();
}

class _AbsensiKegiatanMuridPageState extends State<AbsensiKegiatanMuridPage> {
  int? _selectedAcademicYearId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      key: ValueKey(_selectedAcademicYearId),
      create: (_) => AbsensiKegiatanMuridProvider()..load(academicYearId: _selectedAcademicYearId),
      child: Consumer<AbsensiKegiatanMuridProvider>(
        builder: (context, provider, _) {
          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;

          return Scaffold(
            backgroundColor: colorScheme.surface,
            appBar: AppBar(
              elevation: 0,
              title: const Text(
                'Kegiatan & Istighosah',
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
                              _buildTotalCard(provider, context),
                              const SizedBox(height: 16),
                              if (provider.records.isEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 50),
                                  alignment: Alignment.center,
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.event_busy_outlined,
                                        size: 56,
                                        color: colorScheme.onSurfaceVariant
                                            .withValues(alpha:0.5),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Belum ada kegiatan tercatat.',
                                        style: TextStyle(
                                          color: colorScheme.onSurfaceVariant,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                ...provider.records.map((r) => _buildCard(r, context)),
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

  Widget _buildTotalCard(
      AbsensiKegiatanMuridProvider provider, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.tertiary,
            colorScheme.tertiary.withValues(alpha:0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${provider.hadirCount} / ${provider.totalCount}',
                  style: TextStyle(
                    color: colorScheme.onTertiary,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                Text(
                  'Kehadiran Kegiatan',
                  style: TextStyle(
                    color: colorScheme.onTertiary.withValues(alpha:0.85),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.event_available,
            color: colorScheme.onTertiary,
            size: 40,
          ),
        ],
      ),
    );
  }

  Widget _buildCard(dynamic r, BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cardColor = theme.cardTheme.color ?? colorScheme.surfaceContainerLow;

    final status = (r['status'] ?? 'ALPA').toString().toUpperCase();
    final color = _getStatusColor(status, context);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha:0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha:0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (r['activity_name'] ?? '-').toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateOnly(r['activity_date']?.toString()),
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (r['notes'] != null && r['notes'].toString().isNotEmpty)
                    Text(
                      r['notes'].toString(),
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
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
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(
            5,
            (index) => Container(
              height: 60,
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (status) {
      case 'HADIR':
        return colorScheme.primary;
      case 'SAKIT':
        return colorScheme.tertiary;
      case 'IZIN':
        return colorScheme.secondary;
      default:
        return colorScheme.error;
    }
  }
}