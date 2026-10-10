import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/izin_guru_admin_provider.dart';
import '../../utils/snackbar_helper.dart';

class IzinGuruAdminPage extends StatelessWidget {
  const IzinGuruAdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => IzinGuruAdminProvider()..fetchList(),
      child: const _IzinGuruListBody(),
    );
  }
}

class _IzinGuruListBody extends StatelessWidget {
  const _IzinGuruListBody();

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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<IzinGuruAdminProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Izin Guru & Badal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                    onTap: () => context.read<IzinGuruAdminProvider>().fetchList()),
                const SizedBox(width: 6),
                _filterChip(context, 'Aktif',
                    selected: provider.selectedStatus == 'AKTIF',
                    onTap: () => context.read<IzinGuruAdminProvider>().fetchList(status: 'AKTIF')),
                const SizedBox(width: 6),
                _filterChip(context, 'Selesai',
                    selected: provider.selectedStatus == 'SELESAI',
                    onTap: () => context.read<IzinGuruAdminProvider>().fetchList(status: 'SELESAI')),
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
                        onRefresh: () => context.read<IzinGuruAdminProvider>().fetchList(status: provider.selectedStatus),
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 90),
                          itemCount: provider.list.length,
                          itemBuilder: (context, index) {
                            final item = provider.list[index];
                            final id = int.tryParse('${item['id'] ?? ''}') ?? 0;
                            final aktif = '${item['status'] ?? 'AKTIF'}' == 'AKTIF';
                            return Card(
                              elevation: 0,
                              color: colorScheme.surfaceContainerLow,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: (aktif ? Colors.orange.shade600 : Colors.green.shade600).withValues(alpha: 0.4),
                                ),
                              ),
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => _IzinGuruDetailPage(izinId: id, izin: item),
                                    ),
                                  );
                                  if (context.mounted) {
                                    await context.read<IzinGuruAdminProvider>().fetchList(status: provider.selectedStatus);
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '${item['teacher_name'] ?? '-'}',
                                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                                            ),
                                          ),
                                          _badge(context, '${item['jenis'] ?? 'IZIN'}', color: Colors.indigo.shade400),
                                          const SizedBox(width: 6),
                                          _badge(context,
                                              '${item['status'] ?? ''}',
                                              color: aktif ? Colors.orange.shade600 : Colors.green.shade600),
                                        ],
                                      ),
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
                                          if (aktif)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.orange.shade600.withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                '${item['pengganti_count'] ?? 0} badal',
                                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange.shade700),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
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
        label: const Text('Buat Izin'),
      ),
    );
  }

  Future<void> _openCreateForm(BuildContext context) async {
    final pr = context.read<IzinGuruAdminProvider>();
    await pr.fetchTeachers();
    if (!context.mounted) return;
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => ChangeNotifierProvider.value(
        value: pr,
        child: _IzinGuruForm(teachers: pr.teachers),
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
          Icon(Icons.fact_check_outlined, size: 48, color: colorScheme.outline),
          const SizedBox(height: 10),
          Text('Belum ada catatan izin guru', style: TextStyle(color: colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

// ── Form buat catatan izin guru ──
class _IzinGuruForm extends StatefulWidget {
  const _IzinGuruForm({required this.teachers});

  final List<dynamic> teachers;

  @override
  State<_IzinGuruForm> createState() => _IzinGuruFormState();
}

class _IzinGuruFormState extends State<_IzinGuruForm> {
  int? _teacherId;
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
    if (_teacherId == null) {
      showErrorSnackBar(context, 'Pilih guru yang izin.');
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
    final err = await context.read<IzinGuruAdminProvider>().createIzin(
          teacherId: _teacherId!,
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
    final isSaving = context.select<IzinGuruAdminProvider, bool>((p) => p.isSaving);

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
                Text('Catatan Izin Guru Baru',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                const Spacer(),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 4),
            DropdownButtonFormField<int>(
              initialValue: _teacherId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Guru *', border: OutlineInputBorder()),
              items: widget.teachers
                  .map((t) => DropdownMenuItem(
                        value: int.tryParse('${t['id'] ?? ''}') ?? 0,
                        child: Text(
                          '${t['name'] ?? '-'}${(t['lembaga'] ?? 'ALL') != 'ALL' ? ' (${t['lembaga']})' : ''}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ))
                  .toList(),
              onChanged: isSaving ? null : (v) => setState(() => _teacherId = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _jenis,
              decoration: const InputDecoration(labelText: 'Jenis', border: OutlineInputBorder()),
              items: IzinGuruAdminProvider.jenisOptions
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

// ── Detail: jadwal terdampak + penetapan badal ──
class _IzinGuruDetailPage extends StatefulWidget {
  const _IzinGuruDetailPage({required this.izinId, required this.izin});

  final int izinId;
  final dynamic izin;

  @override
  State<_IzinGuruDetailPage> createState() => _IzinGuruDetailPageState();
}

class _IzinGuruDetailPageState extends State<_IzinGuruDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<IzinGuruAdminProvider>().fetchTeachers();
        context.read<IzinGuruAdminProvider>().fetchDetail(widget.izinId);
      }
    });
  }

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

  Future<void> _assignBadal(dynamic schedule, int? substituteId) async {
    final pr = context.read<IzinGuruAdminProvider>();
    final err = await pr.assignBadal(
      widget.izinId,
      int.tryParse('${schedule['schedule_id'] ?? ''}') ?? 0,
      '${schedule['tanggal'] ?? ''}',
      substituteId,
    );
    if (!mounted) return;
    if (err != null && !err.contains('berhasil') && !err.contains('dihapus')) {
      showErrorSnackBar(context, err);
    } else {
      showSuccessSnackBar(context, err ?? 'Badal diperbarui.');
    }
    await pr.fetchDetail(widget.izinId);
  }

  Future<void> _finish() async {
    final pr = context.read<IzinGuruAdminProvider>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tandai Selesai'),
        content: const Text('Izin akan ditandai SELESAI dan penunjukan badal akan dibersihkan. Lanjutkan?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Selesai')),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final err = await pr.finishIzin(widget.izinId);
    if (!mounted) return;
    if (err == null || err.contains('SELESAI')) {
      showSuccessSnackBar(context, err ?? 'Izin ditandai selesai.');
      await pr.fetchDetail(widget.izinId);
    } else {
      showErrorSnackBar(context, err);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<IzinGuruAdminProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final detail = provider.detail?['izin'] as Map? ?? const {};
    final status = '${detail['status'] ?? widget.izin['status'] ?? 'AKTIF'}';
    final aktif = status == 'AKTIF';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Atur Badal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: provider.isLoading && provider.detailIzinId == widget.izinId
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : RefreshIndicator(
              color: colorScheme.primary,
              onRefresh: () => provider.fetchDetail(widget.izinId),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 90),
                children: [
                  Card(
                    elevation: 0,
                    color: colorScheme.surfaceContainerHigh,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${detail['teacher_name'] ?? widget.izin['teacher_name'] ?? '-'}',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
                                ),
                              ),
                              _badge(context, '${detail['jenis'] ?? widget.izin['jenis'] ?? 'IZIN'}',
                                  color: Colors.indigo.shade400),
                              const SizedBox(width: 6),
                              _badge(context, status, color: aktif ? Colors.orange.shade600 : Colors.green.shade600),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('${detail['alasan'] ?? widget.izin['alasan'] ?? '-'}',
                              style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)),
                          const SizedBox(height: 6),
                          Text(
                            '${_humanDate('${detail['tanggal_mulai'] ?? widget.izin['tanggal_mulai']}')} s.d. '
                            '${_humanDate('${detail['tanggal_selesai'] ?? widget.izin['tanggal_selesai']}')}',
                            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Total jadwal terdampak: ${provider.detail?['total_jadwal_terdampak'] ?? 0} • '
                            'Sudah berbadal: ${provider.detail?['total_sudah_badal'] ?? 0}',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.primary),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      aktif ? 'Pilih guru pengganti untuk tiap slot jadwal yang terdampak:' : 'Izin telah selesai — jadwal berikut tetap tampil sebagai catatan.',
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (provider.detailSchedules.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Center(
                        child: Text('Tidak ada jadwal mengajar dalam periode izin.',
                            style: TextStyle(color: colorScheme.onSurfaceVariant)),
                      ),
                    ),
                  for (final schedule in provider.detailSchedules)
                    _scheduleCard(context, schedule, aktif),
                ],
              ),
            ),
      floatingActionButton: aktif
          ? FloatingActionButton.extended(
              onPressed: provider.isSaving ? null : _finish,
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              icon: const Icon(Icons.done_all),
              label: const Text('Tandai Selesai'),
            )
          : null,
    );
  }

  Widget _scheduleCard(BuildContext context, dynamic schedule, bool aktif) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentSubstituteId = schedule['substitute_teacher_id'] != null
        ? int.tryParse('${schedule['substitute_teacher_id']}')
        : null;
    final mainTeacherId = int.tryParse('${context.watch<IzinGuruAdminProvider>().detail?['izin']?['teacher_id'] ?? ''}');

    // Dropdown options: semua guru kecuali guru yang izin (tidak boleh badal dirinya sendiri)
    final teacherList = context.watch<IzinGuruAdminProvider>().teachers;
    final options = teacherList.where((t) {
      final tid = int.tryParse('${t['id'] ?? ''}');
      return tid != null && tid != mainTeacherId;
    }).toList();
    final selectedId = options.any((t) => int.tryParse('${t['id'] ?? ''}') == currentSubstituteId)
        ? currentSubstituteId
        : null;

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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _humanDate('${schedule['tanggal'] ?? ''}'),
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colorScheme.onPrimaryContainer),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${schedule['subject_name'] ?? '-'} • ${schedule['class_name'] ?? '-'}',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${schedule['jam'] ?? '-'} • ${schedule['session_name'] ?? ''}',
              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 10),
            if (!aktif)
              Text(
                currentSubstituteId != null
                    ? 'Guru pengganti: ${schedule['substitute_name'] ?? '-'}'
                    : 'Tidak ada badal ditugaskan.',
                style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
              )
            else
              DropdownButtonFormField<int?>(
                initialValue: selectedId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Guru Pengganti (Badal)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.person_add_alt, size: 20),
                ),
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('— Tanpa badal —')),
                  ...options.map((t) => DropdownMenuItem<int?>(
                        value: int.tryParse('${t['id'] ?? ''}'),
                        child: Text('${t['name'] ?? '-'}', overflow: TextOverflow.ellipsis),
                      )),
                ],
                onChanged: (v) {
                  if (v == selectedId) return;
                  _assignBadal(schedule, v);
                },
              ),
            if (schedule['assigned_via_izin'] == true && aktif)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Ditugaskan lewat catatan izin ini.',
                  style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.orange.shade700),
                ),
              ),
          ],
        ),
      ),
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
}