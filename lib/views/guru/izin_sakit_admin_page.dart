import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/izin_sakit_admin_provider.dart';
import '../../utils/snackbar_helper.dart';

class IzinSakitAdminPage extends StatelessWidget {
  const IzinSakitAdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => IzinSakitAdminProvider()..fetchList(),
      child: const _IzinSakitBody(),
    );
  }
}

class _IzinSakitBody extends StatelessWidget {
  const _IzinSakitBody();

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

  Color _statusColor(String status, ColorScheme colorScheme) {
    switch (status) {
      case 'DISETUJUI':
        return Colors.green.shade600;
      case 'DITOLAK':
        return colorScheme.error;
      default:
        return Colors.orange.shade600;
    }
  }

  Future<void> _setStatus(BuildContext context, dynamic item, String status) async {
    final id = int.tryParse('${item['id'] ?? ''}') ?? 0;
    final err = await context.read<IzinSakitAdminProvider>().setStatus(id, status);
    if (!context.mounted) return;
    if (err == null) {
      showSuccessSnackBar(context, "Status ${item['student_name'] ?? item['nim'] ?? ''} menjadi $status.");
    } else {
      showErrorSnackBar(context, err);
    }
    if (err == null && context.mounted) {
      await context.read<IzinSakitAdminProvider>().fetchList(status: context.read<IzinSakitAdminProvider>().selectedStatus);
    }
  }

  Future<void> _delete(BuildContext context, dynamic item) async {
    final id = int.tryParse('${item['id'] ?? ''}') ?? 0;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Catatan'),
        content: const Text('Catatan izin/sakit ini akan dihapus permanen. Lanjutkan?'),
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
    final err = await context.read<IzinSakitAdminProvider>().delete(id);
    if (!context.mounted) return;
    if (err == null) {
      showSuccessSnackBar(context, 'Catatan dihapus.');
    } else {
      showErrorSnackBar(context, err);
    }
    if (err == null && context.mounted) {
      await context.read<IzinSakitAdminProvider>().fetchList(status: context.read<IzinSakitAdminProvider>().selectedStatus);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<IzinSakitAdminProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Izin & Sakit Murid', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                    onTap: () => context.read<IzinSakitAdminProvider>().fetchList()),
                const SizedBox(width: 6),
                _filterChip(context, 'Menunggu',
                    selected: provider.selectedStatus == 'MENUNGGU',
                    onTap: () => context.read<IzinSakitAdminProvider>().fetchList(status: 'MENUNGGU')),
                const SizedBox(width: 6),
                _filterChip(context, 'Disetujui',
                    selected: provider.selectedStatus == 'DISETUJUI',
                    onTap: () => context.read<IzinSakitAdminProvider>().fetchList(status: 'DISETUJUI')),
                const SizedBox(width: 6),
                _filterChip(context, 'Ditolak',
                    selected: provider.selectedStatus == 'DITOLAK',
                    onTap: () => context.read<IzinSakitAdminProvider>().fetchList(status: 'DITOLAK')),
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
                        onRefresh: () => context.read<IzinSakitAdminProvider>().fetchList(status: provider.selectedStatus),
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 90),
                          itemCount: provider.list.length,
                          itemBuilder: (context, index) {
                            final item = provider.list[index];
                            final status = '${item['status'] ?? 'MENUNGGU'}';
                            final menunggu = status == 'MENUNGGU';
                            return Card(
                              elevation: 0,
                              color: colorScheme.surfaceContainerLow,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: _statusColor(status, colorScheme).withValues(alpha: 0.4),
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
                                            '${item['student_name'] ?? item['nim'] ?? '-'}',
                                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                                          ),
                                        ),
                                        _badge(context,
                                            '${item['jenis'] ?? 'IZIN'}',
                                            color: (item['jenis'] == 'SAKIT' ? Colors.red.shade400 : Colors.indigo.shade400)),
                                        const SizedBox(width: 6),
                                        _badge(context, status, color: _statusColor(status, colorScheme)),
                                      ],
                                    ),
                                    if ((item['class_name'] ?? '').toString().isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text('${item['class_name']} • NIM ${item['nim'] ?? '-'}',
                                          style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                                    ],
                                    const SizedBox(height: 6),
                                    Text(
                                      '${item['alasan'] ?? '-'}',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(Icons.date_range_outlined, size: 14, color: colorScheme.onSurfaceVariant),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            '${_humanDate('${item['tanggal_mulai'] ?? ''}')} s.d. ${_humanDate('${item['tanggal_selesai'] ?? ''}')}',
                                            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                                          ),
                                        ),
                                        if (item['disetujui_oleh'] != null)
                                          Text(
                                            'oleh ${item['disetujui_oleh']}',
                                            style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: colorScheme.onSurfaceVariant),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    if (menunggu)
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed: () => _setStatus(context, item, 'DISETUJUI'),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: Colors.green.shade700,
                                                side: BorderSide(color: Colors.green.shade600),
                                              ),
                                              icon: const Icon(Icons.check, size: 18),
                                              label: const Text('Setujui'),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed: () => _setStatus(context, item, 'DITOLAK'),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: colorScheme.error,
                                                side: BorderSide(color: colorScheme.error),
                                              ),
                                              icon: const Icon(Icons.close, size: 18),
                                              label: const Text('Tolak'),
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () => _delete(context, item),
                                            icon: Icon(Icons.delete_outline, size: 20, color: colorScheme.outline),
                                          ),
                                        ],
                                      )
                                    else
                                      Row(
                                        children: [
                                          Icon(Icons.info_outline, size: 14, color: colorScheme.onSurfaceVariant),
                                          const SizedBox(width: 4),
                                          Text(
                                            status == 'DISETUJUI' ? 'Izin disetujui, murid dibolehkan absen.' : 'Izin ditolak.',
                                            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                                          ),
                                          const Spacer(),
                                          IconButton(
                                            onPressed: () => _delete(context, item),
                                            icon: Icon(Icons.delete_outline, size: 20, color: colorScheme.outline),
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
        onPressed: () => _openCreateForm(context),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        icon: const Icon(Icons.add),
        label: const Text('Catat Izin'),
      ),
    );
  }

  Future<void> _openCreateForm(BuildContext context) async {
    final pr = context.read<IzinSakitAdminProvider>();
    await pr.fetchStudents();
    if (!context.mounted) return;
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => ChangeNotifierProvider.value(
        value: pr,
        child: _IzinSakitForm(students: pr.students),
      ),
    );
    if (created == true && context.mounted) {
      await pr.fetchList(status: pr.selectedStatus);
    }
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
          Icon(Icons.event_note_outlined, size: 48, color: colorScheme.outline),
          const SizedBox(height: 10),
          Text('Belum ada catatan izin/sakit', style: TextStyle(color: colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _IzinSakitForm extends StatefulWidget {
  const _IzinSakitForm({required this.students});

  final List<dynamic> students;

  @override
  State<_IzinSakitForm> createState() => _IzinSakitFormState();
}

class _IzinSakitFormState extends State<_IzinSakitForm> {
  int? _studentId;
  String _jenis = 'IZIN';
  String _alasan = '';
  String _keterangan = '';
  String _mulai = '';
  String _selesai = '';

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pick(bool mulai) async {
    final now = DateTime.now();
    final initial = DateTime.tryParse(mulai ? _mulai : _selesai) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked == null) return;
    setState(() {
      if (mulai) {
        _mulai = _fmt(picked);
      } else {
        _selesai = _fmt(picked);
      }
    });
  }

  bool _validate() {
    if (_studentId == null) {
      showErrorSnackBar(context, 'Pilih murid.');
      return false;
    }
    if (_alasan.trim().isEmpty) {
      showErrorSnackBar(context, 'Alasan wajib diisi.');
      return false;
    }
    if (_mulai.isEmpty || _selesai.isEmpty) {
      showErrorSnackBar(context, 'Tanggal mulai & selesai wajib dipilih.');
      return false;
    }
    if (_selesai.compareTo(_mulai) < 0) {
      showErrorSnackBar(context, 'Tanggal selesai tidak boleh sebelum tanggal mulai.');
      return false;
    }
    return true;
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    final err = await context.read<IzinSakitAdminProvider>().create(
          studentId: _studentId!,
          jenis: _jenis,
          alasan: _alasan.trim(),
          tanggalMulai: _mulai,
          tanggalSelesai: _selesai,
          keterangan: _keterangan,
        );
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
    final isSaving = context.select<IzinSakitAdminProvider, bool>((p) => p.isSaving);

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
                Text('Catat Izin/Sakit Murid',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                const Spacer(),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 4),
            DropdownButtonFormField<int>(
              initialValue: _studentId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Murid *', border: OutlineInputBorder()),
              items: widget.students
                  .map((s) => DropdownMenuItem(
                        value: int.tryParse('${s['id'] ?? ''}') ?? 0,
                        child: Text(
                          '${s['name'] ?? '-'} (${s['nim'] ?? '-'})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ))
                  .toList(),
              onChanged: isSaving ? null : (v) => setState(() => _studentId = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _jenis,
              decoration: const InputDecoration(labelText: 'Jenis', border: OutlineInputBorder()),
              items: IzinSakitAdminProvider.jenisOptions
                  .map((j) => DropdownMenuItem(value: j, child: Text(j)))
                  .toList(),
              onChanged: isSaving ? null : (v) => setState(() => _jenis = v ?? 'IZIN'),
            ),
            const SizedBox(height: 12),
            TextField(
              enabled: !isSaving,
              decoration: const InputDecoration(labelText: 'Alasan *', border: OutlineInputBorder()),
              onChanged: (v) => _alasan = v,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _dateField(context, 'Tanggal Mulai', _mulai, () => _pick(true))),
                const SizedBox(width: 10),
                Expanded(child: _dateField(context, 'Tanggal Selesai', _selesai, () => _pick(false))),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              enabled: !isSaving,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Keterangan (opsional)', border: OutlineInputBorder()),
              onChanged: (v) => _keterangan = v,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary),
                child: Text(isSaving ? 'Menyimpan...' : 'Simpan Catatan'),
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
        decoration: InputDecoration(labelText: label, border: OutlineInputBorder(), contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12)),
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