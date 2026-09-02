import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../data/api/api_service.dart';

/// Helper terpusat untuk resolve URL foto santri/guru/admin.
/// Backend menyimpan foto sebagai:
/// - URL penuh `https://...` atau `data:...`
/// - Path `/uploads/...` atau `uploads/...`
/// - Nama file saja `foto.jpg`
/// Dikembalikan URL yang bisa langsung dipakai `Image.network` / `NetworkImage`.
String? resolveFotoUrl(String? foto) {
  if (foto == null) return null;
  final f = foto.trim();
  if (f.isEmpty) return null;

  // 1. Jika sudah berupa URL absolut atau Data URI (Base64)
  if (f.startsWith('http://') ||
      f.startsWith('https://') ||
      f.startsWith('data:')) {
    return f;
  }

  // 2. Ambil base host URL (hapus suffix /api atau /api/)
  final baseHost = ApiService.effectiveBaseUrl
      .replaceAll(RegExp(r'/api/?$'), '')
      .replaceAll(RegExp(r'/+$'), '');

  // 3. Normalisasi path relative
  if (f.startsWith('/uploads/')) {
    return '$baseHost$f';
  }
  if (f.startsWith('uploads/')) {
    return '$baseHost/$f';
  }
  
  // Jika hanya nama file (mis. "foto.jpg" atau "avatar.png")
  if (f.contains('.') && !f.contains('/')) {
    return '$baseHost/uploads/$f';
  }

  // Fallback: jika diawali slash lain
  if (f.startsWith('/')) {
    return '$baseHost$f';
  }

  return '$baseHost/$f';
}

/// Mengembalikan [ImageProvider] ter-cache (disk + memory) dari nilai foto
/// mentah. `null` bila tidak ada URL yang valid.
/// Memakai `CachedNetworkImageProvider` dari `cached_network_image` sehingga
/// avatar/foto yang sering dimuat (roster santri, profil) tidak di-download
/// ulang setiap kali widget di-build (hemat kuota & lebih cepat).
ImageProvider? cachedFotoProvider(String? foto) {
  final resolvedUrl = resolveFotoUrl(foto);
  if (resolvedUrl == null) return null;
  return CachedNetworkImageProvider(resolvedUrl);
}

/// Helper Widget untuk menampilkan CircleAvatar dengan penanganan error bawaan
class CustomAvatar extends StatelessWidget {
  final String? fotoUrl;
  final double radius;
  final IconData defaultIcon;
  final Color? backgroundColor;
  final Color? iconColor;

  const CustomAvatar({
    super.key,
    this.fotoUrl,
    this.radius = 20.0,
    this.defaultIcon = Icons.person,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final fotoProvider = cachedFotoProvider(fotoUrl);

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.primaryContainer,
      backgroundImage: fotoProvider,
      onBackgroundImageError: fotoProvider != null
          ? (exception, stackTrace) {
              debugPrint('Gagal memuat foto avatar: $exception');
            }
          : null,
      child: fotoProvider == null
          ? Icon(
              defaultIcon,
              size: radius * 1.1,
              color: iconColor ?? Theme.of(context).colorScheme.onPrimaryContainer,
            )
          : null,
    );
  }
}