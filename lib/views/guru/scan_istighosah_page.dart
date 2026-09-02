import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../providers/scan_istighosah_provider.dart';

class ScanIstighosahPage extends StatelessWidget {
  final int activityId;
  final String activityName;

  const ScanIstighosahPage({
    super.key,
    required this.activityId,
    required this.activityName,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ScanIstighosahProvider(),
      child: _ScanIstighosahBody(activityId: activityId, activityName: activityName),
    );
  }
}

class _ScanIstighosahBody extends StatefulWidget {
  final int activityId;
  final String activityName;

  const _ScanIstighosahBody({required this.activityId, required this.activityName});

  @override
  State<_ScanIstighosahBody> createState() => _ScanIstighosahBodyState();
}

class _ScanIstighosahBodyState extends State<_ScanIstighosahBody> {
  late MobileScannerController _scannerController;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      facing: kIsWeb ? CameraFacing.front : CameraFacing.back,
      detectionSpeed: DetectionSpeed.noDuplicates,
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _processQrData(String nimRaw) async {
    final provider = context.read<ScanIstighosahProvider>();
    await _scannerController.stop();

    final success = await provider.processQrData(nimRaw, widget.activityId);
    if (!mounted) return;

    if (success) {
      _showResultDialog(
        title: 'Presensi Sukses',
        message: 'Wali dari:\n\n${provider.lastStudentName}\nKelas: ${provider.lastClassName}\n\nBerhasil dicatat hadir.',
        isSuccess: true,
      );
    } else {
      _showResultDialog(
        title: 'Presensi Gagal',
        message: provider.error ?? 'Kode QR tidak dikenali atau santri tidak terdaftar di sistem.',
        isSuccess: false,
      );
    }
  }

  void _showResultDialog({
    required String title,
    required String message,
    required bool isSuccess,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final dialogColorScheme = Theme.of(context).colorScheme;
        return AlertDialog(
          title: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSuccess ? dialogColorScheme.primary : dialogColorScheme.error,
            ),
          ),
          content: Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15)),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.read<ScanIstighosahProvider>().resetResult();
                _scannerController.start();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isSuccess ? dialogColorScheme.primary : dialogColorScheme.error,
              ),
              child: Text(
                'SCAN BERIKUTNYA',
                style: TextStyle(color: dialogColorScheme.onPrimary, fontWeight: FontWeight.bold),
              ),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan: ${widget.activityName}'),
        backgroundColor: colorScheme.tertiary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                _processQrData(barcodes.first.rawValue!);
              }
            },
            errorBuilder: (context, error,) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.videocam_off, size: 64, color: colorScheme.error),
                      const SizedBox(height: 16),
                      Text(
                        'Gagal Membuka Kamera: ${error.errorCode}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Pastikan izin kamera/webcam di browser sudah diaktifkan, atau pastikan menggunakan koneksi HTTPS.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 4),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
