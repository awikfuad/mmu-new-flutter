import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

Color shimmerBaseColor(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? Colors.grey.shade800 : Colors.grey.shade300;
}

Color shimmerHighlightColor(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? Colors.grey.shade700 : Colors.grey.shade100;
}

/// Cincin bundar ber-shimmer — pengganti [CircularProgressIndicator] kecil
/// di dalam tombol, icon, atau field.
class ShimmerSpinner extends StatelessWidget {
  const ShimmerSpinner({
    super.key,
    this.size = 20,
    this.strokeWidth = 2,
    this.color,
  });

  final double size;
  final double strokeWidth;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ringColor = color ?? cs.primary;
    return Shimmer.fromColors(
      baseColor: ringColor.withValues(alpha: 0.35),
      highlightColor: ringColor,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: ringColor, width: strokeWidth),
        ),
      ),
    );
  }
}

/// Kotak skeleton ber-shimmer dengan warna menyesuaikan tema.
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    this.width,
    required this.height,
    this.radius = 12,
    this.color,
  });

  final double? width;
  final double height;
  final double radius;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Bungkus [Shimmer.fromColors] dengan warna base/highlight tema.
class ThemedShimmer extends StatelessWidget {
  const ThemedShimmer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: shimmerBaseColor(context),
      highlightColor: shimmerHighlightColor(context),
      child: child,
    );
  }
}

/// Skeleton daftar kartu generik ber-shimmer. Bentuk tiap kartu diatur
/// lewat [itemBuilder] agar menyesuaikan konten halaman.
class ShimmerListSkeleton extends StatelessWidget {
  const ShimmerListSkeleton({
    super.key,
    this.itemCount = 5,
    required this.itemBuilder,
    this.padding = const EdgeInsets.fromLTRB(12, 10, 12, 24),
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ThemedShimmer(
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: padding,
        itemCount: itemCount,
        itemBuilder: itemBuilder,
      ),
    );
  }
}

/// Kartu skeleton bergaris (radius 12) mengikuti kartu list pada umumnya.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({
    super.key,
    required this.child,
    this.margin = const EdgeInsets.symmetric(vertical: 4),
    this.padding = const EdgeInsets.all(12),
  });

  final Widget child;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: child,
    );
  }
}

