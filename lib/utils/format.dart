import 'package:flutter/material.dart';

String formatRp(num? value) {
  if (value == null) return 'Rp 0';
  final s = value.round().toString();
  final b = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return 'Rp $b';
}

String dateOnly(String? raw) {
  if (raw == null || raw.isEmpty) return '-';
  return raw.length >= 10 ? raw.substring(0, 10) : raw;
}

MaterialColor statusColor(String status) {
  switch (status.toUpperCase()) {
    case 'HADIR':
      return Colors.green;
    case 'SAKIT':
      return Colors.orange;
    case 'IZIN':
      return Colors.blue;
    default:
      return Colors.red;
  }
}
