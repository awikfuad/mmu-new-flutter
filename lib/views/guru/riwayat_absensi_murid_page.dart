import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/riwayat_murid_provider.dart';
import '../../utils/foto_helper.dart';

class RiwayatAbsensiMuridPage extends StatefulWidget {
  const RiwayatAbsensiMuridPage({super.key});

  @override
  State<RiwayatAbsensiMuridPage> createState() =>
      _RiwayatAbsensiMuridPageState();
}

class _RiwayatAbsensiMuridPageState extends State<RiwayatAbsensiMuridPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ChangeNotifierProvider(
      create: (_) => RiwayatMuridProvider()..fetchMuridList(),
      child: Consumer<RiwayatMuridProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            backgroundColor: colorScheme.surfaceContainerLowest,
            appBar: AppBar(
              elevation: 0,
              scrolledUnderElevation: 0,
              title: const Text(
                'Riwayat Absensi Murid',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              backgroundColor: colorScheme.surface,
              foregroundColor: colorScheme.onSurface,
            ),
            body: provider.isLoadingList
                ? _buildShimmerLoadingList(context)
                : provider.selected == null
                    ? _buildSearchViewWithClassTabs(provider, context)
                    : _buildHistoryView(provider, context),
          );
        },
      ),
    );
  }

  // --- TAMPILAN PENCARIAN MURID DENGAN TAB KELAS ---
  Widget _buildSearchViewWithClassTabs(
    RiwayatMuridProvider provider,
    BuildContext context,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    // Mendapatkan daftar kelas unik secara dinamis dari data murid
    final Set<String> uniqueClassesSet = provider.filtered
        .map((m) => (m['class_name'] ?? 'Tanpa Kelas').toString())
        .toSet();

    final List<String> sortedClasses = uniqueClassesSet.toList()..sort();
    final List<String> classesList = ['Semua Kelas', ...sortedClasses];

    return Column(
      children: [
        // Input Search Bar
        Container(
          padding: const EdgeInsets.all(16),
          color: colorScheme.surface,
          child: TextField(
            controller: _searchController,
            onChanged: provider.filterSearch,
            style: TextStyle(color: colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: 'Cari nama atau NIM murid...',
              hintStyle: TextStyle(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                fontSize: 14,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: colorScheme.primary,
              ),
              filled: true,
              fillColor: colorScheme.surfaceContainerLow,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      icon: Icon(
                        Icons.clear_rounded,
                        size: 20,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        provider.filterSearch('');
                      },
                    ),
            ),
          ),
        ),

        // DefaultTabController dengan Key Dinamis
        Expanded(
          child: DefaultTabController(
            key: ValueKey(classesList.join('_')),
            length: classesList.length,
            child: Column(
              children: [
                // TabBar Kelas (Kapsul Scrollable)
                Container(
                  color: colorScheme.surface,
                  width: double.infinity,
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    indicator: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    labelColor: colorScheme.onPrimary,
                    unselectedLabelColor: colorScheme.onSurfaceVariant,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 13,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    tabs: classesList
                        .map(
                          (c) => Tab(
                            height: 36,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(c),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),

                // Isi Konten List Murid
                Expanded(
                  child: TabBarView(
                    children: classesList.map((className) {
                      final listForTab = className == 'Semua Kelas'
                          ? provider.filtered
                          : provider.filtered
                              .where(
                                (m) =>
                                    (m['class_name'] ?? 'Tanpa Kelas')
                                        .toString() ==
                                    className,
                              )
                              .toList();

                      return _buildMuridListView(listForTab, provider, context);
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- WIDGET LIST MURID ---
  Widget _buildMuridListView(
    List<dynamic> muridList,
    RiwayatMuridProvider provider,
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (muridList.isEmpty) {
      return _buildEmptyState(context, 'Tidak ada murid di kelas ini.');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: muridList.length,
      itemBuilder: (context, index) {
        final m = muridList[index];
        final fotoUrl = resolveFotoUrl(m['foto']?.toString());

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          elevation: 0,
          color: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 6,
            ),
            leading: CircleAvatar(
              radius: 22,
              backgroundColor: colorScheme.primaryContainer,
              backgroundImage: cachedFotoProvider(fotoUrl),
              onBackgroundImageError: fotoUrl != null ? (_, __) {} : null,
              child: fotoUrl == null
                  ? Icon(
                      Icons.person_outline_rounded,
                      color: colorScheme.onPrimaryContainer,
                    )
                  : null,
            ),
            title: Text(
              m['name'] ?? '-',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: colorScheme.onSurface,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'NIM: ${m['nim'] ?? '-'}${m['class_name'] != null ? '  •  ${m['class_name']}' : ''}',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: colorScheme.primary,
            ),
            onTap: () {
              FocusScope.of(context).unfocus();
              provider.selectMurid(m as Map<String, dynamic>);
            },
          ),
        );
      },
    );
  }

  // --- TAMPILAN DETAIL RIWAYAT MURID ---
  Widget _buildHistoryView(
    RiwayatMuridProvider provider,
    BuildContext context,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedFoto = resolveFotoUrl(provider.selected?['foto']?.toString());

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          // Header Profil Murid
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primary,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: colorScheme.onPrimary.withValues(alpha: 0.2),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: colorScheme.primaryContainer,
                    backgroundImage:
                        cachedFotoProvider(selectedFoto),
                    onBackgroundImageError:
                        selectedFoto != null ? (_, __) {} : null,
                    child: selectedFoto == null
                        ? Icon(
                            Icons.person,
                            color: colorScheme.onPrimaryContainer,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.selected?['name'] ?? '-',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'NIM: ${provider.selected?['nim'] ?? '-'}  ${provider.selected?['class_name'] != null ? '• ${provider.selected?['class_name']}' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onPrimary.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: colorScheme.onPrimary.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.refresh_rounded,
                      color: colorScheme.onPrimary,
                      size: 18,
                    ),
                  ),
                  tooltip: 'Ganti murid',
                  onPressed: () {
                    _searchController.clear();
                    provider.resetSelection();
                  },
                ),
              ],
            ),
          ),

          // TabBar Detail
          Material(
            color: colorScheme.surface,
            elevation: 1,
            child: TabBar(
              indicatorColor: colorScheme.primary,
              indicatorWeight: 3,
              labelColor: colorScheme.primary,
              unselectedLabelColor: colorScheme.onSurfaceVariant,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: 'Kegiatan Non-Akademik'),
                Tab(text: 'Absensi KBM'),
              ],
            ),
          ),

          // Konten Utama
          Expanded(
            child: provider.isLoadingDetail
                ? _buildShimmerLoadingList(context)
                : TabBarView(
                    children: [
                      RefreshIndicator(
                        onRefresh: () =>
                            provider.selectMurid(provider.selected!),
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16.0),
                          children: _buildKegiatanTab(provider, context),
                        ),
                      ),
                      RefreshIndicator(
                        onRefresh: () =>
                            provider.selectMurid(provider.selected!),
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16.0),
                          children: _buildKbmTab(provider, context),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // --- TAB KEGIATAN ---
  List<Widget> _buildKegiatanTab(
    RiwayatMuridProvider provider,
    BuildContext context,
  ) {
    if (provider.kegiatanRecords.isEmpty) {
      return [
        _buildEmptyState(
          context,
          'Belum ada riwayat kegiatan non-akademik murid ini.',
        ),
      ];
    }
    return [
      _buildSummaryRow(provider.kegiatanRecords, context),
      const SizedBox(height: 16),
      ...provider.kegiatanRecords.map((r) => _buildKegiatanCard(r, context)),
    ];
  }

  Widget _buildKegiatanCard(dynamic record, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final status = (record['status'] ?? 'ALPA').toString().toUpperCase();
    final statusColor = _statusColor(status, context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: statusColor, width: 5)),
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
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.event_outlined,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    (record['activity_date'] ?? '-').toString(),
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              if (record['notes'] != null &&
                  record['notes'].toString().isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Catatan: ${record['notes']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // --- TAB KBM ---
  List<Widget> _buildKbmTab(
    RiwayatMuridProvider provider,
    BuildContext context,
  ) {
    if (provider.kbmRecords.isEmpty) {
      return [
        _buildEmptyState(context, 'Belum ada riwayat absensi KBM murid ini.'),
      ];
    }
    return [
      _buildSummaryRow(provider.kbmRecords, context),
      const SizedBox(height: 16),
      ...provider.kbmRecords.map((r) => _buildKbmCard(r, context)),
    ];
  }

  Widget _buildKbmCard(dynamic record, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final status = (record['status'] ?? 'ALPA').toString().toUpperCase();
    final statusColor = _statusColor(status, context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: statusColor, width: 5)),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      (record['session_name'] ?? 'SESI').toString(),
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    (record['date'] ?? '-').toString(),
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (record['teacher_name'] != null &&
                  record['teacher_name'].toString().isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Dikabsen oleh: ${record['teacher_name']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
              if (record['notes'] != null &&
                  record['notes'].toString().isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Catatan: ${record['notes']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // --- RINGKASAN REKAP ---
  Widget _buildSummaryRow(List<dynamic> records, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    int hadir = 0, sakit = 0, izin = 0, alpa = 0;
    for (final r in records) {
      switch (r['status']) {
        case 'HADIR':
          hadir++;
          break;
        case 'SAKIT':
          sakit++;
          break;
        case 'IZIN':
          izin++;
          break;
        default:
          alpa++;
      }
    }
    return Row(
      children: [
        _summaryChip(context, '$hadir', 'HADIR', colorScheme.primary),
        const SizedBox(width: 8),
        _summaryChip(context, '$sakit', 'SAKIT', colorScheme.tertiary),
        const SizedBox(width: 8),
        _summaryChip(context, '$izin', 'IZIN', colorScheme.secondary),
        const SizedBox(width: 8),
        _summaryChip(context, '$alpa', 'ALPA', colorScheme.error),
      ],
    );
  }

  Widget _summaryChip(
    BuildContext context,
    String count,
    String label,
    Color color,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              count,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- EMPTY STATE & UTILITIES ---
  Widget _buildEmptyState(BuildContext context, String message) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            Icons.history_toggle_off_rounded,
            size: 56,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
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

  Widget _buildShimmerLoadingList(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final highlightColor = isDark ? Colors.grey.shade700 : Colors.grey.shade100;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (_, _) => Container(
          height: 80,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status, BuildContext context) {
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