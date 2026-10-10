import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_windowmanager_plus/flutter_windowmanager_plus.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../data/models/ujian_models.dart';
import '../../providers/student_ujian_provider.dart';
import '../../utils/snackbar_helper.dart';

class KerjakanUjianPage extends StatefulWidget {
  final int ujianId;
  final String kode;
  final String nim;
  final String name;

  const KerjakanUjianPage({
    super.key,
    required this.ujianId,
    required this.kode,
    required this.nim,
    required this.name,
  });

  @override
  State<KerjakanUjianPage> createState() => _KerjakanUjianPageState();
}

class _KerjakanUjianPageState extends State<KerjakanUjianPage> {
  Future<void> _submit(
    StudentUjianProvider provider,
    Map<String, dynamic> jawaban,
  ) async {
    await provider.submit(
      ujianId: widget.ujianId,
      kode: widget.kode,
      nim: widget.nim,
      jawaban: jawaban,
    );
    if (mounted) setState(() {});
  }

  void _confirmExit() async {
    final colorScheme = Theme.of(context).colorScheme;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Keluar dari Ujian?'),
        content: const Text(
          'Jawaban Anda tersimpan otomatis di server.\nAnda bisa melanjutkan kembali lewat menu Ujian.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Keluar', style: TextStyle(color: colorScheme.onError)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          StudentUjianProvider()
            ..start(
              ujianId: widget.ujianId,
              kode: widget.kode,
              nim: widget.nim,
              name: widget.name,
            ),
      child: Builder(
        builder: (context) {
          final colorScheme = Theme.of(context).colorScheme;
          return Consumer<StudentUjianProvider>(
            builder: (context, provider, _) {
              final inExam =
                  !provider.isLoading &&
                  provider.sesi != null &&
                  provider.hasil == null;
              return PopScope(
                canPop: !inExam,
                onPopInvokedWithResult: (didPop, result) {
                  if (!didPop && inExam) _confirmExit();
                },
                child: Scaffold(
                  appBar: AppBar(
                    elevation: 0,
                    title: Text(
                      provider.sesi?.judul ?? 'Kerjakan Ujian',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    automaticallyImplyLeading: !inExam,
                    leading: !inExam
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.logout_rounded),
                            onPressed: _confirmExit,
                            tooltip: 'Keluar',
                          ),
                  ),
                  body: _buildBody(provider, colorScheme),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBody(StudentUjianProvider provider, ColorScheme colorScheme) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final hasil = provider.hasil;

    if (hasil != null) {
      return _UjianHasilView(
        hasil: hasil,
        onSelesai: () => Navigator.pop(context),
      );
    }

    final sesi = provider.sesi;
    if (sesi == null && provider.error != null) {
      return _buildErrorView(provider.error!, colorScheme);
    }

    if (sesi == null) {
      return const Center(child: Text('Tidak dapat memulai ujian.'));
    }

    return _UjianExamView(
      key: ValueKey('exam-${sesi.ujianId}-${sesi.pesertaNim}'),
      sesi: sesi,
      provider: provider,
      kode: widget.kode,
      onSubmit: (jawaban) => _submit(provider, jawaban),
      onExit: _confirmExit,
    );
  }

  Widget _buildErrorView(String message, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 56, color: colorScheme.error),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Kembali'),
            ),
          ],
        ),
      ),
    );
  }
}

class _UjianExamView extends StatefulWidget {
  final SesiUjian sesi;
  final StudentUjianProvider provider;
  final String kode;
  final Future<void> Function(Map<String, dynamic> jawaban) onSubmit;
  final VoidCallback onExit;

  const _UjianExamView({
    super.key,
    required this.sesi,
    required this.provider,
    required this.kode,
    required this.onSubmit,
    required this.onExit,
  });

  @override
  State<_UjianExamView> createState() => _UjianExamViewState();
}

class _UjianExamViewState extends State<_UjianExamView> with WidgetsBindingObserver {
  final Map<String, dynamic> _jawaban = {};
  final Map<String, TextEditingController> _esaiControllers = {};
  late PageController _pageController;
  int _currentIndex = 0;
  Timer? _timer;
  Timer? _saveTimer;
  DateTime? _deadline;
  Duration? _sisa;
  bool _submitted = false;
  int _cheatCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pageController = PageController();
    _deadline = widget.sesi.deadline;

    // Prefill jawaban sebelumnya (resume / refresh)
    widget.sesi.jawabanSebelum.forEach((key, value) {
      _jawaban[key.toString()] = value;
    });

    // Controller untuk soal ESAI
    for (final s in widget.sesi.soal) {
      final sid = s['id']?.toString() ?? '';
      if (sid.isEmpty) continue;
      if ((s['tipe']?.toString() ?? '').toUpperCase() == 'ESAI') {
        _esaiControllers[sid] = TextEditingController(
          text: widget.sesi.jawabanSebelum[sid]?.toString(),
        );
      }
    }

    if (_deadline != null) {
      _sisa = _deadline!.difference(DateTime.now());
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    }

    // Security & Mode Kiosk
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    WakelockPlus.enable();
    _enableSecureScreen();
  }

  Future<void> _enableSecureScreen() async {
    try {
      await FlutterWindowManagerPlus.addFlags(FlutterWindowManagerPlus.FLAG_SECURE);
    } catch (_) {}
  }

  Future<void> _disableSecureScreen() async {
    try {
      await FlutterWindowManagerPlus.clearFlags(FlutterWindowManagerPlus.FLAG_SECURE);
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_submitted) return;
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _cheatCount++;
      showWarningSnackBar(
        context,
        'Peringatan ($_cheatCount): Dilarang meninggalkan aplikasi saat ujian!',
      );
    }
  }

  // Saat keluar (keluar / selesai / kembali) — dorong jawaban terakhir agar tak hilang.
  Future<void> _saveOnExit() async {
    await _flushSave();
  }

  void _tick() {
    if (!mounted || _deadline == null) return;
    final sisa = _deadline!.difference(DateTime.now());
    setState(() => _sisa = sisa);
    if (sisa <= Duration.zero) {
      _autoSubmit();
    }
  }

  // Jadwalkan autosave progres (debounce 800ms) — wizard: jawaban di halaman yang sedang
  // dikerjakan ikut tersimpan & bisa dilanjutkan lagi lewat menu Ujian.
  void _scheduleSave() {
    if (_submitted) return;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 800), _flushSave);
  }

  Future<void> _flushSave() async {
    _saveTimer?.cancel();
    if (_submitted || widget.provider.isSubmitting) return;
    await widget.provider.save(
      ujianId: widget.sesi.ujianId,
      kode: widget.kode,
      nim: widget.sesi.pesertaNim,
      jawaban: Map<String, dynamic>.from(_jawaban),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveTimer?.cancel();
    _pageController.dispose();
    _timer?.cancel();
    for (final c in _esaiControllers.values) {
      c.dispose();
    }
    if (!_submitted) _saveOnExit();
    WakelockPlus.disable();
    _disableSecureScreen();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _autoSubmit() async {
    if (_submitted) return;
    _submitted = true;
    _saveTimer?.cancel();
    _timer?.cancel();
    try {
      await widget.onSubmit(_jawaban);
    } catch (e) {
      _submitted = false;
      if (mounted) {
        showWarningSnackBar(context, 'Gagal mengirim jawaban. Periksa koneksi internet Anda.');
      }
    }
  }

  Future<void> _manualSubmit() async {
    if (_submitted || widget.provider.isSubmitting) return;
    final colorScheme = Theme.of(context).colorScheme;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Kumpulkan Jawaban?'),
        content: const Text(
          'Pastikan semua jawaban sudah terisi. Jawaban yang sudah dikumpulkan tidak bisa diubah lagi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Kumpulkan', style: TextStyle(color: colorScheme.onPrimary)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _autoSubmit();
    }
  }

  bool _isAnswered(String id) {
    final val = _jawaban[id]?.toString().trim() ?? '';
    return val.isNotEmpty;
  }

  void _showNavigasiSheet() {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Navigasi Soal',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    children: [
                      _buildLegendItem(colorScheme.primary, 'Sedang Dibuka'),
                      const SizedBox(width: 12),
                      _buildLegendItem(Colors.green, 'Sudah Dijawab'),
                      const SizedBox(width: 12),
                      _buildLegendItem(
                        colorScheme.surfaceContainerHighest,
                        'Belum Dijawab',
                        border: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: SingleChildScrollView(
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: widget.sesi.soal.length,
                        itemBuilder: (context, index) {
                          final soal = widget.sesi.soal[index];
                          final id = soal['id']?.toString() ?? '';
                          final isCurrent = index == _currentIndex;
                          final answered = _isAnswered(id);

                          Color bg = colorScheme.surfaceContainerHighest;
                          Color textColor = colorScheme.onSurfaceVariant;

                          if (isCurrent) {
                            bg = colorScheme.primary;
                            textColor = colorScheme.onPrimary;
                          } else if (answered) {
                            bg = Colors.green;
                            textColor = Colors.white;
                          }

                          return InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              _pageController.animateToPage(
                                index,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: bg,
                                borderRadius: BorderRadius.circular(8),
                                border: isCurrent
                                    ? Border.all(color: colorScheme.primary, width: 2)
                                    : null,
                              ),
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLegendItem(Color color, String label, {bool border = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: border ? Border.all(color: colorScheme.outline) : null,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  String _fmtCountdown(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final total = widget.sesi.soal.length;
    final terjawab = _jawaban.values.where((v) {
      final s = v?.toString().trim() ?? '';
      return s.isNotEmpty;
    }).length;

    return Column(
      children: [
        // Header Info Ujian
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              Icon(
                _deadline == null ? Icons.timer_off_outlined : Icons.timer_outlined,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                _deadline == null
                    ? 'Tanpa batas waktu'
                    : 'Sisa waktu: ${_fmtCountdown(_sisa ?? Duration.zero)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: (_sisa != null && _sisa! < const Duration(minutes: 5))
                      ? colorScheme.error
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              ActionChip(
                avatar: const Icon(Icons.grid_view_rounded, size: 16),
                label: Text('Soal ${_currentIndex + 1}/$total ($terjawab Selesai)'),
                onPressed: _showNavigasiSheet,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),

        // Wizard PageView Soal
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (idx) {
              setState(() => _currentIndex = idx);
              // Perpindahan halaman = momen aman utk menyimpan jawaban halaman sebelumnya.
              _scheduleSave();
            },
            itemCount: total,
            itemBuilder: (context, index) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _buildSoalCard(index, widget.sesi.soal[index], colorScheme),
              );
            },
          ),
        ),

        // Bottom Navigation Wizard
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Tombol Sebelumnya
              OutlinedButton.icon(
                onPressed: _currentIndex > 0
                    ? () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    : null,
                icon: const Icon(Icons.arrow_back_ios_new, size: 14),
                label: const Text('Sebelumnya'),
              ),

              // Tombol Selanjutnya / Kumpulkan
              if (_currentIndex == total - 1)
                FilledButton.icon(
                  onPressed: widget.provider.isSubmitting ? null : _manualSubmit,
                  icon: widget.provider.isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_outlined, size: 16),
                  label: Text(
                    widget.provider.isSubmitting ? 'Mengirim...' : 'Kumpulkan',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                )
              else
                FilledButton.icon(
                  onPressed: () {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  label: const Row(
                    children: [
                      Text('Selanjutnya'),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios, size: 14),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSoalCard(int index, Map<String, dynamic> soal, ColorScheme colorScheme) {
    final id = soal['id']?.toString() ?? '';
    final tipe = soal['tipe']?.toString() ?? 'PG';
    final pertanyaan = soal['pertanyaan']?.toString() ?? '';
    final urutan = soal['urutan']?.toString() ?? '${index + 1}';
    final jawabanObj = _jawaban[id];
    final jawaban = jawabanObj?.toString();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  urutan,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  pertanyaan,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
              Chip(
                label: Text(tipe, style: const TextStyle(fontSize: 9)),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                backgroundColor: colorScheme.secondaryContainer,
                side: BorderSide.none,
                labelStyle: TextStyle(fontSize: 9, color: colorScheme.onSecondaryContainer),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (tipe.toUpperCase() == 'ESAI')
            TextField(
              controller: _esaiControllers[id],
              maxLines: 5,
              textInputAction: TextInputAction.done,
              onChanged: (v) {
                _jawaban[id] = v;
                _scheduleSave();
                setState(() {});
              },
              decoration: InputDecoration(
                hintText: 'Tulis jawaban Anda di sini...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                isDense: true,
              ),
            )
          else
            ...(['a', 'b', 'c', 'd', 'e']).map((label) {
              final text = soal['opsi_$label']?.toString();
              if (text == null || text.trim().isEmpty) return const SizedBox.shrink();
              final isSelected = jawaban?.toUpperCase() == label.toUpperCase();
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _jawaban.remove(id);
                      } else {
                        _jawaban[id] = label.toUpperCase();
                      }
                    });
                    _scheduleSave();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primary.withValues(alpha: 0.12)
                          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.outlineVariant.withValues(alpha: 0.4),
                        width: isSelected ? 1.4 : 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.surface,
                            border: Border.all(color: colorScheme.outlineVariant),
                          ),
                          child: Text(
                            label.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(text, style: const TextStyle(fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _UjianHasilView extends StatelessWidget {
  final HasilUjian hasil;
  final VoidCallback onSelesai;

  const _UjianHasilView({required this.hasil, required this.onSelesai});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final nilaiText = hasil.nilai?.toStringAsFixed(2) ?? '-';

    return Center(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(20),
        children: [
          Icon(Icons.task_alt, size: 64, color: colorScheme.primary),
          const SizedBox(height: 12),
          const Text(
            'Ujian Selesai',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  'Nilai Anda',
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 4),
                Text(
                  nilaiText,
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _hasilStat('Total Soal', hasil.totalSoal, colorScheme),
              _hasilStat('Dijawab', hasil.dijawab, colorScheme),
              _hasilStat('Benar', hasil.benar, colorScheme),
              _hasilStat('Salah', hasil.salah, colorScheme),
            ],
          ),
          if (hasil.adaEsai) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.edit_note, size: 16, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  'Mengandung soal esai (dinilai guru)',
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ],
          if (hasil.tampilkanHasil && hasil.detail.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'Rincian Jawaban',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 10),
            ...hasil.detail.map((d) => _buildDetailRow(d, colorScheme)),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onSelesai,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Selesai', style: TextStyle(fontWeight: FontWeight.bold)),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          ),
        ],
      ),
    );
  }

  Widget _hasilStat(String label, int value, ColorScheme colorScheme) {
    return Column(
      children: [
        Text(
          '$value',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
        ),
        Text(label, style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
      ],
    );
  }

  Widget _buildDetailRow(Map<String, dynamic> d, ColorScheme colorScheme) {
    final bankId = d['bank_soal_id']?.toString() ?? '?';
    final benar = d['benar'] == true;
    final jawaban = d['jawaban']?.toString() ?? '-';
    final kunci = d['kunci']?.toString() ?? '-';
    final pembahasan = d['pembahasan']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: (benar ? Colors.green : Colors.red).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (benar ? Colors.green : Colors.red).withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                benar ? Icons.check_circle : Icons.cancel,
                size: 16,
                color: benar ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Soal $bankId',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Jawaban Anda: $jawaban  •  Kunci: $kunci',
            style: const TextStyle(fontSize: 12),
          ),
          if (pembahasan != null && pembahasan.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Pembahasan: $pembahasan', style: const TextStyle(fontSize: 11)),
          ],
        ],
      ),
    );
  }
}