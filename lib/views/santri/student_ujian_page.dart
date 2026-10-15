import 'package:flutter/material.dart';
import 'package:kiosk_mode/kiosk_mode.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../data/models/ujian_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/student_ujian_provider.dart';
import '../../utils/snackbar_helper.dart';
import 'kerjakan_ujian_page.dart';
import 'scan_kode_ujian_page.dart';
import 'package:flutter/cupertino.dart';

class StudentUjianPage extends StatefulWidget {
  const StudentUjianPage({super.key});

  @override
  State<StudentUjianPage> createState() => _StudentUjianPageState();
}

class _StudentUjianPageState extends State<StudentUjianPage> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StudentUjianProvider()..load(),
      child: Builder(
        builder: (context) {
          final colorScheme = Theme.of(context).colorScheme;
          return Scaffold(
            appBar: AppBar(
              elevation: 0,
              title: const Text(
                'Ujian / CBT',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              backgroundColor: colorScheme.surface,
              foregroundColor: colorScheme.onSurface,
              actions: [
                Consumer<StudentUjianProvider>(
                  builder: (context, provider, _) => IconButton(
                    icon: const Icon(CupertinoIcons.refresh),
                    onPressed: provider.isLoading ? null : provider.load,
                    tooltip: 'Muat Ulang',
                  ),
                ),
              ],
            ),
            body: Consumer<StudentUjianProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading && provider.list.isEmpty) {
                  return _buildShimmerLoading(context);
                }
                if (provider.error != null && provider.list.isEmpty) {
                  return _buildErrorState(provider, colorScheme);
                }
                return RefreshIndicator(
                  onRefresh: provider.load,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.list.length + 1,
                    itemBuilder: (context, index) {
                      if (index == provider.list.length) {
                        return _buildFootnote(colorScheme);
                      }
                      final ujian = provider.list[index];
                      return _buildCard(ujian, colorScheme);
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _onTapUjian(UjianCard ujian) async {
    if (!ujian.bisaDikerjakan) {
      if (ujian.nilai != null) {
        _showHasilDialog(ujian);
      }
      return;
    }
    await _showKodeDialog(ujian);
  }

  void _showHasilDialog(UjianCard ujian) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Hasil Ujian'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              ujian.judul,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              ujian.nilai?.toStringAsFixed(2) ?? '-',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Status: ${ujian.pesertaStatus}',
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Future<void> _showKodeDialog(UjianCard ujian) async {
    final kodeController = TextEditingController();
    var scanned = <String, dynamic>{};
    var pendingScan = false;
    var resultKode = '';

    await showCupertinoDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final colorScheme = Theme.of(dialogContext).colorScheme;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final kodeNow = kodeController.text.trim().isNotEmpty
                ? kodeController.text.trim()
                : (scanned['kode']?.toString().trim() ?? '');

            Future<void> doScan() async {
              pendingScan = true;
              setDialogState(() {});
              final result = await Navigator.of(dialogContext).push<Map<String, dynamic>>(
                MaterialPageRoute(builder: (_) => const ScanKodeUjianPage()),
              );
              pendingScan = false;
              if (!dialogContext.mounted) return;
              if (result == null) {
                setDialogState(() {});
                return;
              }
              final scannedId = result['ujianId'] as int?;
              if (scannedId != null && scannedId != ujian.ujianId) {
                showErrorSnackBar(
                  dialogContext,
                  'QR ini bukan untuk ujian "$ujian.judul".',
                );
                setDialogState(() {});
                return;
              }
              scanned = result;
              kodeController.clear();
              setDialogState(() {});
            }

            return CupertinoAlertDialog(
              title: const Text('Kode Akses Ujian'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ujian.judul,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Masukkan kode akses dari guru, atau scan QR yang tampil di layar.',
                    style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: kodeController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: 'Kode Akses',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                      suffixIcon: pendingScan
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : IconButton(
                              icon: const Icon(CupertinoIcons.qrcode_viewfinder),
                              onPressed: doScan,
                              tooltip: 'Scan QR',
                            ),
                    ),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  if (scanned['kode'] != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(CupertinoIcons.checkmark_circle, size: 16, color: Colors.green),
                        const SizedBox(width: 6),
                        Text(
                          'QR terbaca: ${scanned['kode']}',
                          style: const TextStyle(fontSize: 12, color: Colors.green),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              actions: [
                CupertinoDialogAction(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Batal'),
                ),
                CupertinoDialogAction(
                  onPressed: kodeNow.isEmpty
                      ? null
                      : () {
                          resultKode = kodeNow;
                          Navigator.pop(dialogContext);
                        },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CupertinoIcons.play_arrow, size: 18),
                      SizedBox(width: 6),
                      Text('Mulai'),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    kodeController.dispose();
    if (!mounted || resultKode.isEmpty) return;

    final user = context.read<AuthProvider>().user;
    final nim = (user?['nim']?.toString() ?? '').trim();
    final name = (user?['name']?.toString() ?? '').trim();
    if (nim.isEmpty || name.isEmpty) {
      showErrorSnackBar(context, 'Data identitas santri tidak lengkap.');
      return;
    }

    await _kioskMode(true);
    if (!mounted) return;
    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => KerjakanUjianPage(
            ujianId: ujian.ujianId,
            kode: resultKode,
            nim: nim,
            name: name,
          ),
        ),
      );
    } finally {
      await _kioskMode(false);
    }
  }

  Future<void> _kioskMode(bool enter) async {
    try {
      if (enter) {
        await startKioskMode();
      } else {
        await stopKioskMode();
      }
    } catch (_) {
      // Kiosk bersifat best-effort; bila platform tak mendukung, ujian tetap berjalan.
    }
  }

  Widget _buildCard(UjianCard ujian, ColorScheme colorScheme) {
    final statusColor = switch (ujian.pesertaStatus) {
      'SELESAI' => Colors.green,
      'MENGERJAKAN' => Colors.orange,
      _ => colorScheme.primary,
    };
    final statusIcon = switch (ujian.pesertaStatus) {
      'SELESAI' => CupertinoIcons.checkmark_circle,
      'MENGERJAKAN' => CupertinoIcons.clock,
      _ => CupertinoIcons.circle,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _onTapUjian(ujian),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, size: 18, color: statusColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ujian.judul,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                _statusChip(ujian.pesertaStatus, statusColor, colorScheme),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _infoChip(ujian.jenis, colorScheme),
                if (ujian.subjectName != null && ujian.subjectName!.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  _infoChip(ujian.subjectName!, colorScheme),
                ],
                if (ujian.durasi > 0) ...[
                  const SizedBox(width: 6),
                  _infoChip('${ujian.durasi} mnt', colorScheme),
                ],
              ],
            ),
            if (ujian.pesertaStatus == 'SELESAI' && ujian.nilai != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    'Nilai: ${ujian.nilai!.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 6),
            Text(
              ujian.bisaDikerjakan
                  ? 'Ketuk untuk memasukkan kode akses'
                  : ujian.pesertaStatus == 'SELESAI'
                      ? 'Ketuk untuk melihat hasil'
                      : ujian.pesertaStatus,
              style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String status, Color color, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'BELUM':
        return 'BELUM MENGERJAKAN';
      case 'MENGERJAKAN':
        return 'SEDANG BERJALAN';
      case 'SELESAI':
        return 'SELESAI';
      default:
        return status;
    }
  }

  Widget _infoChip(String text, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildFootnote(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        'Kode akses diperoleh dari guru/admin.\nBila sudah pernah mengerjakan, lanjutkan lewat menu ini.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
      ),
    );
  }

  Widget _buildErrorState(StudentUjianProvider provider, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.cloud, size: 56, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              provider.error ?? 'Gagal memuat ujian.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: provider.load,
              icon: const Icon(CupertinoIcons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
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
            5,
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