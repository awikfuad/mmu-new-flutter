import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/kelola_kegiatan_provider.dart';
import '../../utils/snackbar_helper.dart';
import '../../utils/cupertino_sheet.dart';
import '../../widgets/shimmer_loader.dart';
import 'package:flutter/cupertino.dart';

class KelolaKegiatanPage extends StatelessWidget {
  const KelolaKegiatanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => KelolaKegiatanProvider()..fetchList(),
      child: const _KelolaKegiatanBody(),
    );
  }
}

class _KelolaKegiatanBody extends StatelessWidget {
  const _KelolaKegiatanBody();

  String _humanDate(String iso) {
    if (iso.isEmpty) return '-';
    final parts = iso.split('-');
    if (parts.length < 3) return iso;
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    final m = int.tryParse(parts[1]);
    return '${int.tryParse(parts[2]) ?? parts[2]} ${m != null ? months[m - 1] : parts[1]} ${parts[0]}';
  }

  Color _targetColor(String target) {
    switch (target) {
      case 'MURID':
        return Colors.blue.shade600;
      case 'GURU':
        return Colors.purple.shade600;
      default:
        return Colors.teal.shade600;
    }
  }

  Future<void> _openForm(BuildContext context, {Map? existing}) async {
    final saved = await showCupertinoBottomSheet<bool>(
      context: context,
      builder: (_) => _KegiatanForm(
        existing: existing,
        provider: context.read<KelolaKegiatanProvider>(),
      ),
    );
    if (saved == true && context.mounted) {
      await context.read<KelolaKegiatanProvider>().fetchList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<KelolaKegiatanProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Kegiatan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: provider.isLoading
          ? _buildKegiatanShimmer()
          : provider.list.isEmpty
              ? _emptyState(context)
              : RefreshIndicator(
                  color: colorScheme.primary,
                  onRefresh: () => context.read<KelolaKegiatanProvider>().fetchList(),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 90),
                    itemCount: provider.list.length,
                    itemBuilder: (context, index) {
                      final k = provider.list[index];
                      final id = int.tryParse('${k['id'] ?? ''}') ?? 0;
                      final target = '${k['target'] ?? 'SEMUA'}';
                      return Card(
                        elevation: 0,
                        color: colorScheme.surfaceContainerLow,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
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
                                      '${k['activity_name'] ?? '-'}',
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _targetColor(target).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text('PESERTA $target',
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _targetColor(target))),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(CupertinoIcons.calendar, size: 15, color: colorScheme.primary),
                                  const SizedBox(width: 4),
                                  Text(
                                    _humanDate('${k['activity_date'] ?? ''}'),
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: colorScheme.onSurface),
                                  ),
                                ],
                              ),
                              if ((k['description'] ?? '').toString().isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  '${k['description']}',
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                                ),
                              ],
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(CupertinoIcons.bag, size: 13, color: colorScheme.onSurfaceVariant),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Lembaga: ${k['lembaga'] ?? 'ALL'}',
                                    style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                                  ),
                                  const Spacer(),
                                  PopupMenuButton<String>(
                                    icon: Icon(CupertinoIcons.ellipsis_vertical, size: 18, color: colorScheme.onSurfaceVariant),
                                    onSelected: (v) async {
                                      if (v == 'edit') {
                                        if (context.mounted) {
                                          await _openForm(context, existing: k);
                                        }
                                      } else if (v == 'delete') {
                                        final ok = await _confirmDelete(context);
                                        if (ok == true) {
                                          if (!context.mounted) return;
                                          final err = await context.read<KelolaKegiatanProvider>().delete(id);
                                          if (!context.mounted) return;
                                          if (err == null) {
                                            showSuccessSnackBar(context, 'Kegiatan dihapus.');
                                          } else {
                                            showErrorSnackBar(context, err);
                                          }
                                        }
                                      }
                                    },
                                    itemBuilder: (_) => const [
                                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                                      PopupMenuItem(value: 'delete', child: Text('Hapus')),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        icon: const Icon(CupertinoIcons.plus_circle),
        label: const Text('Kegiatan'),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showCupertinoDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Hapus Kegiatan'),
        content: const Text('Kegiatan akan dihapus permanen beserta data presensinya. Lanjutkan?'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Widget _buildKegiatanShimmer() {
  return ShimmerListSkeleton(
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 90),
    itemCount: 5,
    itemBuilder: (context, index) => const SkeletonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: ShimmerBox(height: 15)),
              ShimmerBox(height: 18, width: 76, radius: 6),
            ],
          ),
          SizedBox(height: 10),
          ShimmerBox(height: 13, width: 160),
          SizedBox(height: 10),
          ShimmerBox(height: 13),
          SizedBox(height: 6),
          ShimmerBox(height: 13, width: 220),
          SizedBox(height: 12),
          Row(
            children: [
              ShimmerBox(height: 12, width: 120),
              Spacer(),
              ShimmerBox(height: 18, width: 20, radius: 6),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _emptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CupertinoIcons.calendar, size: 48, color: colorScheme.outline),
          const SizedBox(height: 10),
          Text('Belum ada kegiatan', style: TextStyle(color: colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _KegiatanForm extends StatefulWidget {
  const _KegiatanForm({this.existing, required this.provider});

  final Map? existing;
  final KelolaKegiatanProvider provider;

  @override
  State<_KegiatanForm> createState() => _KegiatanFormState();
}

class _KegiatanFormState extends State<_KegiatanForm> {
  late final TextEditingController _nama;
  late final TextEditingController _deskripsi;
  late String _target;
  String _tanggal = '';

  @override
  void initState() {
    super.initState();
    _nama = TextEditingController(text: widget.existing?['activity_name']?.toString() ?? '');
    _deskripsi = TextEditingController(text: widget.existing?['description']?.toString() ?? '');
    _target = widget.existing?['target']?.toString() ?? 'SEMUA';
    _tanggal = widget.existing?['activity_date']?.toString() ?? '';
  }

  @override
  void dispose() {
    _nama.dispose();
    _deskripsi.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = DateTime.tryParse(_tanggal) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked == null) return;
    setState(() => _tanggal = _fmt(picked));
  }

  bool _validate() {
    if (_nama.text.trim().isEmpty) {
      showErrorSnackBar(context, 'Nama kegiatan wajib diisi.');
      return false;
    }
    if (_tanggal.isEmpty) {
      showErrorSnackBar(context, 'Tanggal pelaksanaan wajib dipilih.');
      return false;
    }
    return true;
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    final pr = widget.provider;
    String? err;
    if (widget.existing == null) {
      err = await pr.create(
        activityName: _nama.text.trim(),
        activityDate: _tanggal,
        description: _deskripsi.text,
        target: _target,
      );
    } else {
      err = await pr.update(
        int.tryParse('${widget.existing!['id']}') ?? 0,
        activityName: _nama.text.trim(),
        activityDate: _tanggal,
        description: _deskripsi.text,
        target: _target,
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
    final isSaving = widget.provider.isSaving;
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
                Text(isEdit ? 'Edit Kegiatan' : 'Kegiatan Baru',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                const Spacer(),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(CupertinoIcons.xmark)),
              ],
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _nama,
              enabled: !isSaving,
              decoration: const InputDecoration(labelText: 'Nama Kegiatan *', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: isSaving ? null : _pickDate,
              borderRadius: BorderRadius.circular(8),
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Tanggal Pelaksanaan *', border: OutlineInputBorder()),
                child: Row(
                  children: [
                    Icon(CupertinoIcons.calendar_today, size: 16, color: colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      _tanggal.isEmpty ? 'Pilih Tanggal' : _tanggal,
                      style: TextStyle(fontSize: 14, color: _tanggal.isEmpty ? colorScheme.outline : colorScheme.onSurface),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _target,
              decoration: const InputDecoration(labelText: 'Target Peserta', border: OutlineInputBorder()),
              items: KelolaKegiatanProvider.targetOptions
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: isSaving ? null : (v) => setState(() => _target = v ?? 'SEMUA'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _deskripsi,
              enabled: !isSaving,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Deskripsi (opsional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary),
                child: Text(isSaving ? 'Menyimpan...' : isEdit ? 'Simpan Perubahan' : 'Simpan Kegiatan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}