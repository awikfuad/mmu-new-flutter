import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';

/// Judul bawaan untuk tiap varian pesan.
String _defaultTitle(ContentType type) {
  if (type == ContentType.success) return 'Berhasil';
  if (type == ContentType.failure) return 'Gagal';
  if (type == ContentType.warning) return 'Peringatan';
  return 'Informasi';
}

/// Tampilkan snackbar bergaya `awesome_snackbar_content`.
///
/// [contentType] menentukan varian visual:
/// * [ContentType.success] -> pesan sukses
/// * [ContentType.failure] -> pesan gagal / error
/// * [ContentType.warning] -> peringatan
/// * [ContentType.help]     -> informasi netral (default)
///
/// Snackbar lama otomatis disembunyikan lebih dulu (lihat [dismissCurrent]).
void showAppSnackBar(
  BuildContext context, {
  required String message,
  String? title,
  Duration duration = const Duration(seconds: 4),
  ContentType contentType = ContentType.help,
  bool dismissCurrent = true,
}) {
  if (!context.mounted) return;

  final snackBar = SnackBar(
    elevation: 0,
    behavior: SnackBarBehavior.floating,
    backgroundColor: Colors.transparent,
    duration: duration,
    content: AwesomeSnackbarContent(
      title: title ?? _defaultTitle(contentType),
      message: message,
      contentType: contentType,
    ),
  );

  final messenger = ScaffoldMessenger.of(context);
  if (dismissCurrent) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  } else {
    messenger.showSnackBar(snackBar);
  }
}

/// Snackbar sukses.
void showSuccessSnackBar(
  BuildContext context,
  String message, {
  String? title,
  Duration duration = const Duration(seconds: 4),
}) {
  showAppSnackBar(
    context,
    message: message,
    title: title,
    duration: duration,
    contentType: ContentType.success,
  );
}

/// Snackbar gagal / error.
void showErrorSnackBar(
  BuildContext context,
  String message, {
  String? title,
  Duration duration = const Duration(seconds: 4),
}) {
  showAppSnackBar(
    context,
    message: message,
    title: title,
    duration: duration,
    contentType: ContentType.failure,
  );
}

/// Snackbar peringatan.
void showWarningSnackBar(
  BuildContext context,
  String message, {
  String? title,
  Duration duration = const Duration(seconds: 4),
}) {
  showAppSnackBar(
    context,
    message: message,
    title: title,
    duration: duration,
    contentType: ContentType.warning,
  );
}

/// Snackbar informasi netral.
void showInfoSnackBar(
  BuildContext context,
  String message, {
  String? title,
  Duration duration = const Duration(seconds: 4),
}) {
  showAppSnackBar(
    context,
    message: message,
    title: title,
    duration: duration,
    contentType: ContentType.help,
  );
}
