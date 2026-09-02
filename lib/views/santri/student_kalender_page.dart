import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/student_kalender_provider.dart';
import '../../utils/format.dart';

class StudentKalenderPage extends StatefulWidget {
  const StudentKalenderPage({super.key});

  @override
  State<StudentKalenderPage> createState() => _StudentKalenderPageState();
}

class _StudentKalenderPageState extends State<StudentKalenderPage> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StudentKalenderProvider()..load(),
      child: Consumer<StudentKalenderProvider>(
        builder: (context, provider, _) {
          final colorScheme = Theme.of(context).colorScheme;

          return Scaffold(
            // backgroundColor: colorScheme.surface,
            appBar: AppBar(
              elevation: 0,
              title: const Text(
                'Kalender Pendidikan',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              backgroundColor: colorScheme.surface,
              foregroundColor: colorScheme.onSurface,
            ),
            body: provider.isLoading
                ? _buildShimmerLoading(context)
                : RefreshIndicator(
                    onRefresh: () => provider.load(),
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
          );
        },
      ),
    );
  }

  Color _kategoriColor(String kategori, ColorScheme colorScheme) {
    switch (kategori.toUpperCase()) {
      case 'EFEKTIF':
        return Colors.green;
      case 'LIBUR':
        return Colors.orange;
      case 'UJIAN':
        return Colors.red;
      case 'KEGIATAN':
        return colorScheme.primary;
      default:
        return colorScheme.outline;
    }
  }

  IconData _kategoriIcon(String kategori) {
    switch (kategori.toUpperCase()) {
      case 'EFEKTIF':
        return Icons.check_circle_outline;
      case 'LIBUR':
        return Icons.holiday_village_outlined;
      case 'UJIAN':
        return Icons.quiz_outlined;
      case 'KEGIATAN':
        return Icons.celebration_outlined;
      default:
        return Icons.event_outlined;
    }
  }

  Widget _buildCard(Map<String, dynamic> r, ColorScheme colorScheme) {
    final judul = r['judul']?.toString() ?? '-';
    final kategori = r['kategori']?.toString() ?? '-';
    final tanggalMulai = dateOnly(r['tanggal_mulai']?.toString());
    final tanggalSelesai = dateOnly(r['tanggal_selesai']?.toString());
    final hijriMulai = r['hijriyah_mulai']?.toString();
    final hijriSelesai = r['hijriyah_selesai']?.toString();
    final keterangan = r['keterangan']?.toString();
    final semester = r['semester']?.toString() ?? '';
    final color = _kategoriColor(kategori, colorScheme);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha:0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_kategoriIcon(kategori), size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  judul,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: colorScheme.onSurface),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  kategori,
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.date_range, size: 14, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                '$tanggalMulai – $tanggalSelesai',
                style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
              ),
              if (semester.isNotEmpty) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: colorScheme.secondary.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    semester,
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: colorScheme.secondary),
                  ),
                ),
              ],
            ],
          ),
          if (hijriMulai != null || hijriSelesai != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.mosque_outlined, size: 14, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  hijriSelesai != null && hijriSelesai != hijriMulai
                      ? '$hijriMulai – $hijriSelesai'
                      : (hijriMulai ?? ''),
                  style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ],
          if (keterangan != null && keterangan.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              keterangan,
              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
            ),
          ],
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
          Icon(Icons.calendar_month_outlined, size: 56, color: colorScheme.onSurfaceVariant.withValues(alpha:0.5)),
          const SizedBox(height: 10),
          Text(
            'Belum ada agenda kalender.',
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
              height: 90,
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
