import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/riwayat_guru_provider.dart';
import '../../utils/format.dart';

class RiwayatAbsensiGuruPage extends StatefulWidget {
  const RiwayatAbsensiGuruPage({super.key});

  @override
  State<RiwayatAbsensiGuruPage> createState() => _RiwayatAbsensiGuruPageState();
}

class _RiwayatAbsensiGuruPageState extends State<RiwayatAbsensiGuruPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ChangeNotifierProvider(
      create: (_) => RiwayatGuruProvider()..init(),
      child: Consumer<RiwayatGuruProvider>(
        builder: (context, provider, _) {
          return DefaultTabController(
            length: 2,
            child: Scaffold(
              appBar: AppBar(
                elevation: 0,
                title: const Text(
                  'Riwayat Absensi Guru',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
                bottom: PreferredSize(
                  preferredSize: Size.fromHeight(provider.isAdmin ? 120 : 48),
                  child: Column(
                    children: [
                      if (provider.isAdmin)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: _buildTeacherPicker(provider, colorScheme),
                        ),
                      TabBar(
                        indicatorColor: colorScheme.onPrimary,
                        indicatorWeight: 3,
                        labelColor: colorScheme.onPrimary,
                        unselectedLabelColor: colorScheme.onPrimary.withValues(alpha:0.7),
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                        tabs: const [
                          Tab(text: 'Kegiatan Internal'),
                          Tab(text: 'Mengajar (KBM)'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              body: provider.isLoading
                  ? _buildShimmerLoading(context)
                  : TabBarView(
                      children: [
                        RefreshIndicator(
                          onRefresh: () => provider.selectTeacher(
                            provider.selectedTeacherId ?? 0,
                          ),
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16.0),
                            children: _buildKegiatanTab(provider, context),
                          ),
                        ),
                        RefreshIndicator(
                          onRefresh: () => provider.selectTeacher(
                            provider.selectedTeacherId ?? 0,
                          ),
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16.0),
                            children: _buildMengajarTab(provider, context),
                          ),
                        ),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTeacherPicker(RiwayatGuruProvider provider, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha:0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha:0.5)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<int>(
          initialValue: provider.selectedTeacherId,
          isExpanded: true,
          decoration: InputDecoration(
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            prefixIcon: Icon(Icons.person_search_rounded, color: colorScheme.primary),
            labelText: 'Pilih Guru / Asatidz',
            labelStyle: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
          ),
          dropdownColor: colorScheme.surface,
          items: provider.teachers
              .map((t) => DropdownMenuItem<int>(
                    value: t['id'],
                    child: Text(
                      '${t['name'] ?? '-'} (${t['lembaga'] ?? 'ALL'})',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: colorScheme.onSurface),
                    ),
                  ))
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            provider.selectTeacher(value);
          },
        ),
      ),
    );
  }

  List<Widget> _buildKegiatanTab(RiwayatGuruProvider provider, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (provider.kegiatanRecords.isEmpty) {
      return [_buildEmptyState(context, 'Belum ada riwayat kegiatan internal untuk guru ini.')];
    }
    return [
      if (!provider.isAdmin)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'Asatidz: ${provider.teacherName}',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: colorScheme.onSurface),
          ),
        ),
      _buildKegiatanSummary(provider, context),
      const SizedBox(height: 16),
      ...provider.kegiatanRecords.map((r) => _buildKegiatanCard(r, context)),
    ];
  }

  Widget _buildKegiatanSummary(RiwayatGuruProvider provider, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        _summaryChip(context, '${provider.hadirKegiatan}', 'HADIR', colorScheme.primary),
        const SizedBox(width: 8),
        _summaryChip(context, '${provider.sakitKegiatan}', 'SAKIT', colorScheme.tertiary),
        const SizedBox(width: 8),
        _summaryChip(context, '${provider.izinKegiatan}', 'IZIN', colorScheme.secondary),
        const SizedBox(width: 8),
        _summaryChip(context, '${provider.alpaKegiatan}', 'ALPA', colorScheme.error),
      ],
    );
  }

  Widget _buildKegiatanCard(dynamic record, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cardColor = Theme.of(context).cardTheme.color;
    final status = (record['status'] ?? 'ALPA').toString().toUpperCase();
    final statusColorValue = statusColor(status);
    final date = (record['activity_date'] ?? '-').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha:0.3)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: statusColorValue, width: 5)),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      record['activity_name'] ?? '-',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: colorScheme.onSurface),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColorValue.withValues(alpha:0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(color: statusColorValue, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.event_outlined, size: 14, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(
                    date,
                    style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
              if (record['notes'] != null && record['notes'].toString().isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha:0.4),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Catatan: ${record['notes']}',
                    style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildMengajarTab(RiwayatGuruProvider provider, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (provider.mengajarRecords.isEmpty) {
      return [_buildEmptyState(context, 'Belum ada riwayat KBM / mengajar untuk guru ini.')];
    }
    return [
      if (!provider.isAdmin)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'Asatidz: ${provider.teacherName}',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: colorScheme.onSurface),
          ),
        ),
      ...provider.mengajarRecords.map((r) => _buildMengajarCard(r, context)),
    ];
  }

  Widget _buildMengajarCard(dynamic record, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cardColor = Theme.of(context).cardTheme.color;
    final date = (record['date'] ?? '-').toString();
    final session = (record['session_name'] ?? '-').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha:0.3)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: colorScheme.primary, width: 5)),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha:0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      session,
                      style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.calendar_today_outlined, size: 13, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    date,
                    style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                record['subject_names'] ?? '-',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: colorScheme.onSurface),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.meeting_room_outlined, size: 14, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Kelas: ${record['class_names'] ?? '-'}',
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurface),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha:0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    _countChip('${record['hadir'] ?? 0}', 'H', colorScheme.primary),
                    const SizedBox(width: 6),
                    _countChip('${record['sakit'] ?? 0}', 'S', colorScheme.tertiary),
                    const SizedBox(width: 6),
                    _countChip('${record['izin'] ?? 0}', 'I', colorScheme.secondary),
                    const SizedBox(width: 6),
                    _countChip('${record['alpa'] ?? 0}', 'A', colorScheme.error),
                    const Spacer(),
                    Text(
                      'Total: ${record['total'] ?? 0} Santri',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _countChip(String count, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(count, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: color)),
          const SizedBox(width: 2),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _summaryChip(BuildContext context, String count, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha:0.3)),
        ),
        child: Column(
          children: [
            Text(count, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.history_toggle_off_rounded, size: 56, color: colorScheme.onSurfaceVariant.withValues(alpha:0.5)),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
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
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (_, _) => Container(
          height: 100,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}