import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/prestasi_pelanggaran_provider.dart';
import '../../utils/snackbar_helper.dart';

class PrestasiPelanggaranPage extends StatelessWidget {
  const PrestasiPelanggaranPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PrestasiPelanggaranProvider()..fetchList(),
      child: const _PrestasiPelanggaranBody(),
    );
  }
}

class _PrestasiPelanggaranBody extends StatelessWidget {
  const _PrestasiPelanggaranBody();

  Color _tipeColor(String tipe, ColorScheme colorScheme) {
    return tipe == 'PRESTASI' ? Colors.green.shade600 : colorScheme.error;
  }

  String _humanDate(String iso) {
    if (iso.isEmpty) return '-';
    final parts = iso.split('T').first.split('-');
    if (parts.length < 3) return iso;
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    final m = int.tryParse(parts[1]);
    return '${int.tryParse(parts[2]) ?? parts[2]} ${m != null ? months[m - 1] : parts[1]} ${parts[0]}';
  }

  String _kategoriLabel(String kategori) {
    if (kategori.isEmpty) return '-';
    return kategori.split('_').map((w) => w[0] + w.substring(1).toLowerCase()).join(' ');
  }

  Future<void> _delete(BuildContext context, dynamic item) async {
    final id = int.tryParse('${item['id'] ?? ''}') ?? 0;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Catatan'),
        content: const Text('Catatan prestasi/pelanggaran ini akan dihapus permanen. Lanjutkan?'),
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
    if (confirm != true || !context.mounted) return;
    final err = await context.read<PrestasiPelanggaranProvider>().delete(id);
    if (!context.mounted) return;
    if (err == null) {
      showSuccessSnackBar(context, 'Catatan dihapus.');
    } else {
      showErrorSnackBar(context, err);
    }
    if (err == null && context.mounted) {
      await context.read<PrestasiPelanggaranProvider>().fetchList(tipe: context.read<PrestasiPelanggaranProvider>().selectedTipe);
    }
  }

  Future<void> _openEdit(BuildContext context, dynamic item) async {
    final pr = context.read<PrestasiPelanggaranProvider>();
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => ChangeNotifierProvider.value(
        value: pr,
        child: _PrestasiForm(initial: item),
      ),
    );
    if (saved == true && context.mounted) {
      await pr.fetchList(tipe: pr.selectedTipe);
    }
  }

  Future<void> _openCreate(BuildContext context) async {
    final pr = context.read<PrestasiPelanggaranProvider>();
    await pr.fetchMurids();
    if (!context.mounted) return;
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => ChangeNotifierProvider.value(
        value: pr,
        child: _PrestasiForm(murids: pr.murids),
      ),
    );
    if (created == true && context.mounted) {
      await pr.fetchList(tipe: pr.selectedTipe);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PrestasiPelanggaranProvider>();
    final auth = context.watch<AuthProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prestasi & Pelanggaran', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                    selected: provider.selectedTipe == null,
                    onTap: () => context.read<PrestasiPelanggaranProvider>().fetchList()),
                const SizedBox(width: 6),
                _filterChip(context, 'Prestasi',
                    selected: provider.selectedTipe == 'PRESTASI',
                    onTap: () => context.read<PrestasiPelanggaranProvider>().fetchList(tipe: 'PRESTASI')),
                const SizedBox(width: 6),
                _filterChip(context, 'Pelanggaran',
                    selected: provider.selectedTipe == 'PELANGGARAN',
                    onTap: () => context.read<PrestasiPelanggaranProvider>().fetchList(tipe: 'PELANGGARAN')),
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
                        onRefresh: () => context.read<PrestasiPelanggaranProvider>().fetchList(tipe: provider.selectedTipe),
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 90),
                          itemCount: provider.list.length,
                          itemBuilder: (context, index) {
                            final item = provider.list[index];
                            final tipe = '${item['tipe'] ?? 'PRESTASI'}';
                            final isPrestasi = tipe == 'PRESTASI';
                            final tipeColor = _tipeColor(tipe, colorScheme);
                            return Card(
                              elevation: 0,
                              color: colorScheme.surfaceContainerLow,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: tipeColor.withValues(alpha: 0.4)),
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
                                            '${item['student_name'] ?? item['nim'] ?? '-'}',
                                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                                          ),
                                        ),
                                        _badge(context, isPrestasi ? 'PRESTASI' : 'PELANGGARAN', color: tipeColor),
                                        if (auth.isAdmin) ...[
                                          const SizedBox(width: 4),
                                          IconButton(
                                            visualDensity: VisualDensity.compact,
                                            onPressed: () => _delete(context, item),
                                            icon: Icon(Icons.delete_outline, size: 18, color: colorScheme.outline),
                                          ),
                                        ],
                                      ],
                                    ),
                                    if ((item['class_name'] ?? '').toString().isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text('${item['class_name']} • NIM ${item['nim'] ?? '-'}',
                                          style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                                    ],
                                    const SizedBox(height: 6),
                                    Text(
                                      '${item['deskripsi'] ?? '-'}',
                                      style: TextStyle(fontSize: 13, color: colorScheme.onSurface),
                                    ),
                                    if ((item['catatan'] ?? '').toString().isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        '${item['catatan']}',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: colorScheme.onSurfaceVariant),
                                      ),
                                    ],
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        _badge(context, _kategoriLabel('${item['kategori'] ?? ''}'),
                                            color: isPrestasi ? Colors.green.shade400 : Colors.red.shade400),
                                        const Spacer(),
                                        Icon(Icons.date_range_outlined, size: 14, color: colorScheme.onSurfaceVariant),
                                        const SizedBox(width: 4),
                                        Text(
                                          _humanDate('${item['tanggal'] ?? ''}'),
                                          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                                        ),
                                        if ('${item['poin'] ?? ''}' != 'null' &&
                                            '${item['poin'] ?? ''}'.isNotEmpty) ...[
                                          const SizedBox(width: 8),
                                          Text(
                                            'Poin: ${item['poin']}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: isPrestasi ? Colors.green.shade600 : colorScheme.error,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    TextButton.icon(
                                      onPressed: () => _openEdit(context, item),
                                      style: TextButton.styleFrom(
                                        foregroundColor: colorScheme.primary,
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        minimumSize: const Size(0, 32),
                                      ),
                                      icon: const Icon(Icons.edit_outlined, size: 16),
                                      label: const Text('Ubah', style: TextStyle(fontSize: 12)),
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
        onPressed: () => _openCreate(context),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Catatan'),
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

  Widget _emptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.emoji_events_outlined, size: 48, color: colorScheme.outline),
          const SizedBox(height: 10),
          Text('Belum ada catatan prestasi/pelanggaran', style: TextStyle(color: colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _PrestasiForm extends StatefulWidget {
  const _PrestasiForm({this.murids, this.initial});

  final List<dynamic>? murids;
  final dynamic initial;

  @override
  State<_PrestasiForm> createState() => _PrestasiFormState();
}

class _PrestasiFormState extends State<_PrestasiForm> {
  String? _tipe;
  String? _kategori;
  String _deskripsi = '';
  String _catatan = '';
  String _tanggal = '';
  String? _poin;

  dynamic _muridId;
  String _nim = '';
  String _sumber = 'madrasah';

  @override
  void initState() {
    super.initState();
    final ini = widget.initial;
    if (ini != null) {
      _tipe = '${ini['tipe'] ?? 'PRESTASI'}';
      _kategori = '${ini['kategori'] ?? ''}'.isEmpty ? null : '${ini['kategori']}';
      _deskripsi = '${ini['deskripsi'] ?? ''}';
      _catatan = '${ini['catatan'] ?? ''}';
      _tanggal = '${ini['tanggal'] ?? ''}'.split('T').first;
      _poin = '${ini['poin'] ?? ''}' != 'null' && '${ini['poin'] ?? ''}'.isNotEmpty ? '${ini['poin']}' : null;
    } else {
      _tipe = 'PRESTASI';
    }
  }

  bool get isEdit => widget.initial != null;

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickTanggal() async {
    final now = DateTime.now();
    final initial = DateTime.tryParse(_tanggal) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2015),
      lastDate: DateTime.now(),
      helpText: 'Pilih Tanggal',
    );
    if (picked == null) return;
    setState(() => _tanggal = _fmt(picked));
  }

  bool _validate() {
    if (widget.initial == null && _muridId == null) {
      showErrorSnackBar(context, 'Pilih murid.');
      return false;
    }
    if (_deskripsi.trim().isEmpty) {
      showErrorSnackBar(context, 'Deskripsi wajib diisi.');
      return false;
    }
    if (_tanggal.isEmpty) {
      showErrorSnackBar(context, 'Tanggal wajib dipilih.');
      return false;
    }
    if (_poin != null && _poin!.isNotEmpty && int.tryParse(_poin!) == null) {
      showErrorSnackBar(context, 'Poin harus angka.');
      return false;
    }
    return true;
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    final pr = context.read<PrestasiPelanggaranProvider>();
    final int? poin = _poin != null && _poin!.isNotEmpty ? int.parse(_poin!) : null;
    String? err;
    if (widget.initial != null) {
      final id = int.tryParse('${widget.initial['id'] ?? ''}') ?? 0;
      err = await pr.update(
        id,
        tipe: _tipe,
        kategori: _kategori,
        deskripsi: _deskripsi.trim(),
        poin: poin,
        catatan: _catatan,
        tanggal: _tanggal,
      );
    } else {
      err = await pr.create(
        muridId: _muridId,
        nim: _nim,
        sumber: _sumber,
        tipe: _tipe!,
        kategori: _kategori ?? '',
        deskripsi: _deskripsi.trim(),
        tanggal: _tanggal,
        poin: poin,
        catatan: _catatan,
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
    final isSaving = context.select<PrestasiPelanggaranProvider, bool>((p) => p.isSaving);
    final murids = widget.murids ?? const [];

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
                Text(isEdit ? 'Ubah Catatan' : 'Tambah Catatan',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                const Spacer(),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 4),
            if (widget.initial == null) ...[
              DropdownButtonFormField<dynamic>(
                initialValue: _muridId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Murid *', border: OutlineInputBorder()),
                items: murids
                    .map((s) => DropdownMenuItem(
                          value: s['id'],
                          child: Text(
                            '${s['name'] ?? '-'} (${s['nim'] ?? '-'})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ))
                    .toList(),
                onChanged: isSaving
                    ? null
                    : (v) {
                        final sel = murids.cast<Map<String, dynamic>>().firstWhere(
                              (s) => s['id'] == v,
                              orElse: () => <String, dynamic>{},
                            );
                        setState(() {
                          _muridId = v;
                          _nim = '${sel['nim'] ?? ''}';
                          _sumber = '${sel['sumber'] ?? 'madrasah'}';
                        });
                      },
              ),
              const SizedBox(height: 12),
            ],
            DropdownButtonFormField<String>(
              initialValue: _tipe,
              decoration: const InputDecoration(labelText: 'Tipe *', border: OutlineInputBorder()),
              items: PrestasiPelanggaranProvider.tipeOptions
                  .map((t) => DropdownMenuItem(value: t, child: Text(t == 'PRESTASI' ? 'Prestasi' : 'Pelanggaran')))
                  .toList(),
              onChanged: isSaving
                  ? null
                  : (v) => setState(() {
                        _tipe = v;
                        _kategori = null;
                      }),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _kategori,
              decoration: const InputDecoration(labelText: 'Kategori', border: OutlineInputBorder()),
              items: (_tipe == 'PELANGGARAN'
                      ? PrestasiPelanggaranProvider.kategoriPelanggaran
                      : PrestasiPelanggaranProvider.kategoriPrestasi)
                  .map((k) => DropdownMenuItem(value: k, child: Text(k.split('_').join(' '))))
                  .toList(),
              onChanged: isSaving ? null : (v) => setState(() => _kategori = v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              enabled: !isSaving,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Deskripsi *', border: OutlineInputBorder()),
              initialValue: _deskripsi,
              onChanged: (v) => _deskripsi = v,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: isSaving ? null : _pickTanggal,
                    borderRadius: BorderRadius.circular(8),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Tanggal *',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 16, color: colorScheme.primary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _tanggal.isEmpty ? 'Pilih' : _tanggal,
                              style: TextStyle(
                                fontSize: 13,
                                color: _tanggal.isEmpty ? colorScheme.outline : colorScheme.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    enabled: !isSaving,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Poin (+/-)',
                      border: OutlineInputBorder(),
                      hintText: 'opsional',
                    ),
                    initialValue: _poin ?? '',
                    onChanged: (v) => _poin = v,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              enabled: !isSaving,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Catatan (opsional)', border: OutlineInputBorder()),
              initialValue: _catatan,
              onChanged: (v) => _catatan = v,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary),
                child: Text(isSaving ? 'Menyimpan...' : (isEdit ? 'Simpan Perubahan' : 'Simpan Catatan')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}