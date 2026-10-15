import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../utils/snackbar_helper.dart';
import 'package:flutter/cupertino.dart';

class ScanKodeUjianPage extends StatefulWidget {
  const ScanKodeUjianPage({super.key});

  @override
  State<ScanKodeUjianPage> createState() => _ScanKodeUjianPageState();
}

class _ScanKodeUjianPageState extends State<ScanKodeUjianPage> {
  late MobileScannerController _scannerController;
  bool _processing = false;

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

  /// Parse isi QR kode akses ujian.
  /// Format: MMU-UJIAN|ujianId|kode
  Map<String, dynamic>? _parsePayload(String raw) {
    final match = RegExp(
      r'^[mM][mM][uU]-[uU][jJ][iI][aA][nN]\|(\d+)\|([^|]+)$',
    ).firstMatch(raw.trim());
    if (match == null) return null;
    final ujianId = int.tryParse(match.group(1) ?? '');
    final kode = match.group(2)?.trim();
    if (ujianId == null || kode == null || kode.isEmpty) return null;
    return {'ujianId': ujianId, 'kode': kode};
  }

  Future<void> _processQrData(String raw) async {
    if (_processing) return;
    final parsed = _parsePayload(raw);
    if (parsed == null) {
      showErrorSnackBar(context, 'QR tidak dikenali sebagai kode ujian.');
      return;
    }
    _processing = true;
    await _scannerController.stop();
    if (!mounted) return;
    Navigator.pop(context, parsed);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan QR Kode Ujian'),
        backgroundColor: colorScheme.primary,
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
            errorBuilder: (context, error) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.videocam, size: 64, color: colorScheme.error),
                      const SizedBox(height: 16),
                      Text(
                        'Gagal Membuka Kamera: ${error.errorCode}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Pastikan izin kamera/webcam di browser sudah diaktifkan, atau pastikan menggunakan koneksi HTTPS.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(CupertinoIcons.keyboard),
                        label: const Text('Masukkan Kode Manual'),
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
          const Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Text(
              'Arahkan kamera ke QR kode akses ujian\nyang tampil di halaman Bank Soal & Ujian (web).',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}