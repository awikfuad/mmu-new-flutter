import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/arsip_soalan_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/foto_helper.dart';
import '../../utils/snackbar_helper.dart';
import 'package:flutter/cupertino.dart';

class ArsipSoalanPage extends StatefulWidget {
  const ArsipSoalanPage({super.key});

  @override
  State<ArsipSoalanPage> createState() => _ArsipSoalanPageState();
}

class _ArsipSoalanPageState extends State<ArsipSoalanPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      context.read<ArsipSoalanProvider>().fetchList(search: value);
    });
  }

  Future<void> _openFile(Map item) async {
    final url = resolveFotoUrl(item['file_path']?.toString());
    if (url == null) {
      showErrorSnackBar(context, 'File arsip tidak ditemukan.');
      return;
    }
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      showErrorSnackBar(context, 'Gagal membuka file arsip.');
    }
  }

  Future<void> _confirmDelete(Map item) async {
    final provider = context.read<ArsipSoalanProvider>();
    final confirm = await showCupertinoDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Hapus Arsip Soal'),
        content: Text(
          'Hapus arsip "${item['judul'] ?? '-'}" beserta file PDF-nya? '
          'Tindakan ini tidak bisa dibatalkan.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;
    final err = await provider.delete((item['id'] ?? 0) as int);
    if (!mounted) return;
    if (err != null) {
      showErrorSnackBar(context, err);
    } else {
      showSuccessSnackBar(context, 'Arsip soal berhasil dihapus.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isAdmin = context.watch<AuthProvider>().isAdmin;

    return ChangeNotifierProvider(
      create: (_) => ArsipSoalanProvider()..fetchList(),
      child: Consumer<ArsipSoalanProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            appBar: AppBar(
              elevation: 0,
              title: const Text(
                'Arsip Soalan',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              actions: [
                IconButton(
                  tooltip: 'Muat ulang',
                  icon: const Icon(CupertinoIcons.refresh),
                  onPressed: provider.isLoading
                      ? null
                      : () => provider.fetchList(),
                ),
              ],
            ),
            body: Column(
              children: [
                _buildFilterBar(provider, colorScheme, theme),
                Expanded(
                  child: provider.isLoading
                      ? _buildShimmer(colorScheme)
                      : provider.error != null
                          ? _buildErrorState(provider, colorScheme)
                          : RefreshIndicator(
                              onRefresh: () => provider.fetchList(),
                              child: _buildList(
                                provider,
                                isAdmin,
                                colorScheme,
                                theme,
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

  Widget _buildFilterBar(
    ArsipSoalanProvider provider,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Container(
      color: colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Column(
        children: [
          TextField(
            controller: _searchCtrl,
            onChanged: _onSearchChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Cari judul / keterangan arsip...',
              prefixIcon: const Icon(CupertinoIcons.search),
              suffixIcon: _searchCtrl.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Bersihkan',
                      icon: const Icon(CupertinoIcons.xmark),
                      onPressed: () {
                        _searchCtrl.clear();
                        provider.fetchList(search: '');
                        setState(() {});
                      },
                    ),
              isDense: true,
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip(
                  label: 'Semua',
                  selected: provider.imda.isEmpty,
                  colorScheme: colorScheme,
                  onTap: () => provider.fetchList(imda: ''),
                ),
                const SizedBox(width: 8),
                ...ArsipSoalanProvider.imdaOptions.map(
                  (imda) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _filterChip(
                      label: imda,
                      selected: provider.imda == imda,
                      colorScheme: colorScheme,
                      onTap: () => provider.fetchList(imda: imda),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required ColorScheme colorScheme,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primary.withValues(alpha: 0.14)
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? colorScheme.primary
                : colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildShimmer(ColorScheme colorScheme) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 8,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, _) => Container(
          height: 92,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(
    ArsipSoalanProvider provider,
    ColorScheme colorScheme,
  ) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        Icon(
          CupertinoIcons.exclamationmark_circle,
          size: 64,
          color: colorScheme.error.withValues(alpha: 0.4),
        ),
        const SizedBox(height: 16),
        Text(
          provider.error ?? 'Terjadi kesalahan.',
          textAlign: TextAlign.center,
          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
        ),
        const SizedBox(height: 12),
        Center(
          child: FilledButton.tonalIcon(
            onPressed: () => provider.fetchList(),
            icon: const Icon(CupertinoIcons.refresh),
            label: const Text('Coba Lagi'),
          ),
        ),
      ],
    );
  }

  Widget _buildList(
    ArsipSoalanProvider provider,
    bool isAdmin,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    if (provider.list.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          Icon(
            CupertinoIcons.folder_open,
            size: 64,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada arsip soal.',
            textAlign: TextAlign.center,
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            'Arsip soal/ujian yang diunggah admin\nakan muncul di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Icon(CupertinoIcons.folder, size: 20, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Daftar Arsip Soal',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              '${provider.totalCount} arsip',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...provider.list.map(
          (raw) {
            final item = Map<String, dynamic>.from(raw as Map);
            return _buildArsipCard(item, isAdmin, colorScheme, theme);
          },
        ),
      ],
    );
  }

  Widget _buildArsipCard(
    Map<String, dynamic> item,
    bool isAdmin,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    final judul = (item['judul'] ?? '-').toString();
    final keterangan = (item['keterangan'] ?? '').toString();
    final jenjang = (item['jenjang_name'] ?? '').toString();
    final kelas = (item['class_name'] ?? '').toString();
    final imda = (item['imda'] ?? '').toString();
    final tahun = (item['academic_year_name'] ?? '').toString();
    final createdAt = (item['created_at'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openFile(item),
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: colorScheme.primary, width: 4),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(12, 12, 6, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.error.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      CupertinoIcons.doc_text,
                      size: 22,
                      color: colorScheme.error,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          judul,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        if (keterangan.isNotEmpty &&
                            keterangan != 'null') ...[
                          const SizedBox(height: 3),
                          Text(
                            keterangan,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            if (jenjang.isNotEmpty) _chip(jenjang, colorScheme),
                            if (kelas.isNotEmpty) _chip(kelas, colorScheme),
                            if (imda.isNotEmpty && imda != 'null')
                              _chip(imda, colorScheme, highlight: true),
                            if (tahun.isNotEmpty && tahun != 'null')
                              _chip(tahun, colorScheme),
                          ],
                        ),
                        if (createdAt.isNotEmpty && createdAt != 'null') ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                CupertinoIcons.clock,
                                size: 12,
                                color: colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDate(createdAt),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Aksi',
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      CupertinoIcons.ellipsis_vertical,
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    onSelected: (value) {
                      if (value == 'open') {
                        _openFile(item);
                      } else if (value == 'delete' && isAdmin) {
                        _confirmDelete(item);
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'open',
                        child: ListTile(
                          leading: Icon(CupertinoIcons.arrow_up_right_square),
                          title: Text('Buka File'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      if (isAdmin)
                        PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(
                              CupertinoIcons.trash,
                              color: colorScheme.error,
                            ),
                            title: const Text('Hapus'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, ColorScheme colorScheme, {bool highlight = false}) {
    final color = highlight ? colorScheme.tertiary : colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  String _formatDate(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    const bulan = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${dt.day} ${bulan[dt.month - 1]} ${dt.year}';
  }
}
