import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:absesni_digital/utils/snackbar_helper.dart';

void main() {
  late BuildContext hostContext;

  Future<void> pumpHost(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            hostContext = context;
            return const Scaffold(body: SizedBox.shrink());
          },
        ),
      ),
    );
  }

  /// Jalankan timer + animasi SnackBar sampai benar-benar selesai,
  /// supaya tidak ada `Timer` tersisa saat test berakhir.
  Future<void> drainSnackBar(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 1));
  }

  AwesomeSnackbarContent readContent(WidgetTester tester) =>
      tester.widget<AwesomeSnackbarContent>(find.byType(AwesomeSnackbarContent));

  SnackBar readSnackBar(WidgetTester tester) =>
      tester.widget<SnackBar>(find.byType(SnackBar));

  group('judul default per varian pesan', () {
    testWidgets('success -> "Berhasil"', (tester) async {
      await pumpHost(tester);
      showSuccessSnackBar(hostContext, 'Tersimpan');

      await tester.pump();
      final content = readContent(tester);
      expect(content.contentType, ContentType.success);
      expect(content.title, 'Berhasil');
      expect(content.message, 'Tersimpan');

      await drainSnackBar(tester);
    });

    testWidgets('failure -> "Gagal"', (tester) async {
      await pumpHost(tester);
      showErrorSnackBar(hostContext, 'Terjadi kesalahan');

      await tester.pump();
      final content = readContent(tester);
      expect(content.contentType, ContentType.failure);
      expect(content.title, 'Gagal');
      expect(content.message, 'Terjadi kesalahan');

      await drainSnackBar(tester);
    });

    testWidgets('warning -> "Peringatan"', (tester) async {
      await pumpHost(tester);
      showWarningSnackBar(hostContext, 'Sisa waktu 5 detik');

      await tester.pump();
      final content = readContent(tester);
      expect(content.contentType, ContentType.warning);
      expect(content.title, 'Peringatan');
      expect(content.message, 'Sisa waktu 5 detik');

      await drainSnackBar(tester);
    });

    testWidgets('help -> "Informasi"', (tester) async {
      await pumpHost(tester);
      showInfoSnackBar(hostContext, 'Tekan kembali sekali lagi');

      await tester.pump();
      final content = readContent(tester);
      expect(content.contentType, ContentType.help);
      expect(content.title, 'Informasi');
      expect(content.message, 'Tekan kembali sekali lagi');

      await drainSnackBar(tester);
    });
  });

  testWidgets('title custom menimpa judul default', (tester) async {
    await pumpHost(tester);
    showSuccessSnackBar(hostContext, 'Oke', title: 'Login sukses');

    await tester.pump();
    expect(readContent(tester).title, 'Login sukses');

    await drainSnackBar(tester);
  });

  testWidgets('snackbar dibangun floating, transparan, tanpa elevasi', (tester) async {
    await pumpHost(tester);
    showErrorSnackBar(hostContext, 'Gagal menyimpan');

    await tester.pump();
    final snackBar = readSnackBar(tester);
    expect(snackBar.behavior, SnackBarBehavior.floating);
    expect(snackBar.backgroundColor, Colors.transparent);
    expect(snackBar.elevation, 0);

    await drainSnackBar(tester);
  });

  testWidgets('durasi default 4 detik', (tester) async {
    await pumpHost(tester);
    showInfoSnackBar(hostContext, 'Default');

    await tester.pump();
    expect(readSnackBar(tester).duration, const Duration(seconds: 4));

    await drainSnackBar(tester);
  });

  testWidgets('durasi custom diteruskan ke SnackBar', (tester) async {
    await pumpHost(tester);
    showSuccessSnackBar(
      hostContext,
      'Login sukses',
      duration: const Duration(seconds: 1),
    );

    await tester.pump();
    expect(readSnackBar(tester).duration, const Duration(seconds: 1));

    await drainSnackBar(tester);
  });

  testWidgets('showAppSnackBar bisa tanpa dismiss snackbar sebelumnya', (tester) async {
    await pumpHost(tester);
    showAppSnackBar(
      hostContext,
      message: 'Langsung tampil',
      title: 'Info',
      contentType: ContentType.help,
      dismissCurrent: false,
    );

    await tester.pump();
    final content = readContent(tester);
    expect(content.title, 'Info');
    expect(content.message, 'Langsung tampil');

    await drainSnackBar(tester);
  });

  testWidgets('snackbar lama digantikan ketika dismissCurrent aktif', (tester) async {
    await pumpHost(tester);

    showErrorSnackBar(hostContext, 'Pesan pertama');
    await tester.pump();
    expect(readContent(tester).message, 'Pesan pertama');

    showSuccessSnackBar(hostContext, 'Pesan kedua');
    await tester.pumpAndSettle();
    expect(readContent(tester).message, 'Pesan kedua');

    await drainSnackBar(tester);
  });
}
