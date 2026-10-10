import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/pengumuman_provider.dart';
import '../../utils/snackbar_helper.dart';

class PengumumanAdminPage extends StatelessWidget {
  const PengumumanAdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PengumumanProvider()..fetchList(),
      child: const _PengumumanBody(),
    );
  }
}

class _PengumumanBody extends StatelessWidget {
  const _PengumumanBody();

  String _humanDate(String iso) {
    if (iso.isEmpty) return '-';
    final parts = iso.split('-');
    if (parts.length < 3) return iso;
    final ts = parts.length >= 3 && parts[2].contains(' ') ? parts[2].split(' ').first : parts[2];
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    final m = int.tryParse(parts[1]);
    return '${int.tryParse(ts) ?? ts} ${m != null ? months[m - 1] : parts[1]} ${parts[0]}';
  }

  Future<void> _openForm(BuildContext context, {Map? existing}) async {
    final pr = context.read<PengumumanProvider>();
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => ChangeNotifierProvider.value(
        value: pr,
        child: _PengumumanForm(existing: existing),
      ),
    );
    if (saved == true && context.mounted) {
      await pr.fetchList(kategori: pr.selectedKategori, status: pr.selectedStatus);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PengumumanProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: TextStyleHelper.text('Pengumuman', fontSize: 18, weight: FontWeight.bold),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _filterChip(context, 'Semua',
                    selected: provider.selectedStatus == null,
                    onTap: () => context.read<PengumumanProvider>().fetchList()),
                const SizedBox(width: 6),
                _filterChip(context, 'Terbit (${provider.publishedCount})',
                    selected: provider.selectedStatus == 'PUBLISHED',
                    onTap: () => context.read<PengumumanProvider>().fetchList(status: 'PUBLISHED')),
                const SizedBox(width: 6),
                _filterChip(context, 'Draf (${provider.draftCount})',
                    selected: provider.selectedStatus == 'DRAFT',
                    onTap: () => context.read<PengumumanProvider>().fetchList(status: 'DRAFT')),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: provider.isLoading
                ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
                : provider.list.isEmpty
                    ? _emptyState(context)
                    : RefreshIndicator(
                        color: colorScheme.primary,
                        onRefresh: () => provider.fetchList(
                            kategori: provider.selectedKategori, status: provider.selectedStatus),
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 90),
                          itemCount: provider.list.length,
                          itemBuilder: (context, index) {
                            final p = provider.list[index];
                            final id = int.tryParse('${p['id'] ?? ''}') ?? 0;
                            final published = (p['is_published'] ?? 0) == 1;
                            return Card(
                              elevation: 0,
                              color: colorScheme.surfaceContainerLow,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: (published ? Colors.green.shade600 : colorScheme.outlineVariant).withValues(alpha: 0.4),
                                ),
                              ),
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${p['judul'] ?? '-'}',
                                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                                          ),
                                        ),
                                        _badge(context,
                                            '${p['kategori'] ?? 'UMUM'}',
                                            color: Colors.indigo.shade400),
                                        const SizedBox(width: 6),
                                        _badge(context,
                                            published ? 'TERBIT' : 'DRAF',
                                            color: published ? Colors.green.shade600 : colorScheme.outline),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${p['isi'] ?? ''}',
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.calendar_today_outlined, size: 14, color: colorScheme.onSurfaceVariant),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${_humanDate('${p['tanggal_mulai'] ?? ''}')}${p['tanggal_selesai'] != null ? ' s.d. ${_humanDate('${p['tanggal_selesai']}')}' : ''}',
                                          style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                                        ),
                                        const Spacer(),
                                        PopupMenuButton<String>(
                                          icon: Icon(Icons.more_vert, size: 18, color: colorScheme.onSurfaceVariant),
                                          onSelected: (v) async {
                                            if (v == 'publish') {
                                              final err = await context.read<PengumumanProvider>().togglePublish(id, !published);
                                              if (!context.mounted) return;
                                              if (err == null) {
                                                showSuccessSnackBar(context, 'Status berhasil diubah.');
                                              } else {
                                                showErrorSnackBar(context, err);
                                              }
                                            } else if (v == 'edit') {
                                              if (context.mounted) {
                                                await _openForm(context, existing: p);
                                              }
                                             } else if (v == 'delete') {
                                               final ok = await _confirmDelete(context);
                                               if (ok == true) {
                                                 if (!context.mounted) return;
                                                 final err = await context.read<PengumumanProvider>().delete(id);
                                                 if (!context.mounted) return;
                                                  if (err == null) {
                                                    showSuccessSnackBar(context, 'Pengumuman dihapus.');
                                                  } else {
                                                    showErrorSnackBar(context, err);
                                                  }
                                               }
                                             }
                                          },
                                          itemBuilder: (_) => [
                                            PopupMenuItem(value: 'publish', child: Text(published ? 'Tarik dari publikasi' : 'Publikasikan')),
                                            const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                            const PopupMenuItem(value: 'delete', child: Text('Hapus')),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        icon: const Icon(Icons.add_alert_outlined),
        label: const Text('Pengumuman'),
      ),
    );
  }

  Widget _filterChip(BuildContext context, String label, {required bool selected, required VoidCallback onTap}) {
    final colorScheme = Theme.of(context).colorScheme;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
      selected: selected,
      selectedColor: colorScheme.primary,
      labelStyle: TextStyle(color: selected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant, fontSize: 12),
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
      onSelected: (_) => onTap(),
    );
  }

  Widget _badge(BuildContext context, String text, {required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Pengumuman'),
        content: const Text('Pengumuman akan dihapus permanen. Lanjutkan?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.campaign_outlined, size: 48, color: colorScheme.outline),
          const SizedBox(height: 10),
          Text('Belum ada pengumuman', style: TextStyle(color: colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

// Helper untuk teks AppBar agar ringkas
class TextStyleHelper {
  static Widget text(String data, {double fontSize = 18, FontWeight weight = FontWeight.bold}) {
    return Text(data, style: TextStyle(fontSize: fontSize, fontWeight: weight));
  }
}

class _PengumumanForm extends StatefulWidget {
  const _PengumumanForm({this.existing});

  final Map? existing;

  @override
  State<_PengumumanForm> createState() => _PengumumanFormState();
}

class _PengumumanFormState extends State<_PengumumanForm> {
  late final TextEditingController _judul;
  late final TextEditingController _isi;
  late String _kategori;
  bool _isiPublished = false;
  String _tanggalMulai = '';
  String _tanggalSelesai = '';

  @override
  void initState() {
    super.initState();
    _judul = TextEditingController(text: widget.existing?['judul']?.toString() ?? '');
    _isi = TextEditingController(text: widget.existing?['isi']?.toString() ?? '');
    _kategori = widget.existing?['kategori']?.toString() ?? 'UMUM';
    _isiPublished = (widget.existing?['is_published'] ?? 0) == 1;
    _tanggalMulai = widget.existing?['tanggal_mulai']?.toString() ?? '';
    _tanggalSelesai = widget.existing?['tanggal_selesai']?.toString() ?? '';
  }

  @override
  void dispose() {
    _judul.dispose();
    _isi.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate(bool isMulai) async {
    final now = DateTime.now();
    final initial = DateTime.tryParse(isMulai ? _tanggalMulai : _tanggalSelesai) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked == null) return;
    setState(() {
      if (isMulai) {
        _tanggalMulai = _fmt(picked);
      } else {
        _tanggalSelesai = _fmt(picked);
      }
    });
  }

  Future<void> _submit() async {
    final pr = context.read<PengumumanProvider>();
    String? err;
    if (widget.existing == null) {
      err = await pr.create(
        judul: _judul.text.trim(),
        isi: _isi.text.trim(),
        kategori: _kategori,
        tanggalMulai: _tanggalMulai,
        tanggalSelesai: _tanggalSelesai,
        isPublished: _isiPublished,
      );
    } else {
      err = await pr.update(
        int.tryParse('${widget.existing!['id']}') ?? 0,
        judul: _judul.text.trim(),
        isi: _isi.text.trim(),
        kategori: _kategori,
        tanggalMulai: _tanggalMulai,
        tanggalSelesai: _tanggalSelesai,
      );
    }

    if (!mounted) return;
    if (err == null) {
      Navigator.pop(context, true);
    } else {
      showErrorSnackBar(context, err);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSaving = context.select<PengumumanProvider, bool>((p) => p.isSaving);
    final isEdit = widget.existing != null;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(isEdit ? 'Edit Pengumuman' : 'Pengumuman Baru',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                const Spacer(),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _judul,
              enabled: !isSaving,
              decoration: const InputDecoration(labelText: 'Judul *', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _isi,
              enabled: !isSaving,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Isi Pengumuman *', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _kategori,
              decoration: const InputDecoration(labelText: 'Kategori', border: OutlineInputBorder()),
              items: PengumumanProvider.kategoriOptions
                  .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                  .toList(),
              onChanged: isSaving ? null : (v) => setState(() => _kategori = v ?? 'UMUM'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _dateField(context, 'Mulai Tayang', _tanggalMulai, () => _pickDate(true)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _dateField(context, 'Selesai', _tanggalSelesai, () => _pickDate(false)),
                ),
              ],
            ),
            if (!isEdit) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Switch(
                    value: _isiPublished,
                    onChanged: isSaving ? null : (v) => setState(() => _isiPublished = v),
                    activeTrackColor: Colors.green.shade600,
                  ),
                  const SizedBox(width: 8),
                  Text('Langsung publikasikan', style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)),
                ],
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary),
                child: Text(isSaving ? 'Menyimpan...' : isEdit ? 'Simpan Perubahan' : 'Simpan Pengumuman'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateField(BuildContext context, String label, String value, VoidCallback onTap) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12)),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined, size: 16, color: colorScheme.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                value.isEmpty ? 'Pilih' : value,
                style: TextStyle(fontSize: 13, color: value.isEmpty ? colorScheme.outline : colorScheme.onSurface),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}