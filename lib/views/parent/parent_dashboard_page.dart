import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/auth_provider.dart';
import '../../providers/parent_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/theme_selector_dialog.dart';
import '../../utils/foto_helper.dart';
import 'parent_child_detail_page.dart';

class ParentDashboardPage extends StatefulWidget {
  const ParentDashboardPage({super.key});

  @override
  State<ParentDashboardPage> createState() => _ParentDashboardPageState();
}

class _ParentDashboardPageState extends State<ParentDashboardPage> {
  DateTime? _lastBackPressed;

  void _processLogout() async {
    final colorScheme = Theme.of(context).colorScheme;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Logout', style: TextStyle(color: colorScheme.onError)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await context.read<AuthProvider>().logout();
    }
  }

  void _openThemeSelector() {
    final themeProvider = context.read<ThemeProvider>();
    showDialog(
      context: context,
      builder: (_) => ThemeSelectorDialog(themeProvider: themeProvider),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final topPadding = MediaQuery.of(context).padding.top;

    return ChangeNotifierProvider(
      create: (_) => ParentProvider()
        ..fetchParentProfile()
        ..fetchChildren(),
      child: Consumer<ParentProvider>(
        builder: (context, parent, _) {
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) async {
              if (didPop) return;
              final now = DateTime.now();
              if (_lastBackPressed != null &&
                  now.difference(_lastBackPressed!) <
                      const Duration(seconds: 2)) {
                return;
              }
              _lastBackPressed = now;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tekan kembali sekali lagi untuk keluar'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: Scaffold(
              backgroundColor: colorScheme.surfaceContainerLowest,
              body: parent.isLoading
                  ? _buildShimmerLoading(context)
                  : RefreshIndicator(
                      onRefresh: () async {
                        await parent.fetchParentProfile();
                        await parent.fetchChildren();
                      },
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          // --- 1. Modern Curved Collapsible AppBar ---
                          SliverPersistentHeader(
                            pinned: true,
                            delegate: _CurvedAppBarDelegate(
                              colorScheme: colorScheme,
                              topPadding: topPadding,
                              onThemeTap: _openThemeSelector,
                              onLogoutTap: _processLogout,
                              profile: _buildProfileCard(parent, colorScheme),
                              maxExtentHeight: 180.0 + topPadding,
                              minExtentHeight: kToolbarHeight + topPadding,
                            ),
                          ),

                          // --- 2. Main Content Section ---
                          SliverPadding(
                            padding: const EdgeInsets.all(16.0),
                            sliver: SliverList(
                              delegate: SliverChildListDelegate([
                                _buildHeaderTitle(parent, colorScheme),
                                const SizedBox(height: 12),
                                if (parent.children.isEmpty)
                                  _buildEmptyChildrenState(colorScheme),
                              ]),
                            ),
                          ),

                          // --- 3. Dynamic Grid Children Section ---
                          if (parent.children.isNotEmpty)
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                              ),
                              sliver: _buildDynamicChildrenGrid(
                                parent,
                                colorScheme,
                              ),
                            ),

                          // --- 4. Footer ---
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 24.0,
                              ),
                              child: Center(
                                child: Text(
                                  'MMU A-44 \u2022 Portal Orang Tua',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }

  // --- Profile Card Component ---
  Widget _buildProfileCard(ParentProvider parent, ColorScheme cs) {
    final name = parent.parentProfile?['name'] ?? 'Orang Tua';
    final phone = parent.parentProfile?['phone'] ?? '-';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: cs.onPrimary,
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              backgroundColor: cs.primaryContainer,
              radius: 24,
              child: Icon(
                Icons.family_restroom,
                color: cs.onPrimaryContainer,
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.toString().toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: cs.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.phone,
                      size: 14,
                      color: cs.onPrimary..withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      phone,
                      style: TextStyle(
                        color: cs.onPrimary..withValues(alpha: 0.85),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderTitle(ParentProvider parent, ColorScheme cs) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Anak Saya (${parent.children.length})',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyChildrenState(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest..withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant..withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.child_care_outlined,
            size: 48,
            color: cs.onSurface..withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            'Belum ada anak terhubung',
            style: TextStyle(
              color: cs.onSurface..withValues(alpha: 0.6),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Hubungi admin untuk menghubungkan akun anak Anda.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: cs.onSurface..withValues(alpha: 0.4),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicChildrenGrid(ParentProvider parent, ColorScheme cs) {
    final int count = parent.children.length;
    final int crossAxisCount = count == 1 ? 1 : 2;
    final double childAspectRatio = count == 1 ? 2.6 : 0.95;

    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 12.0,
        crossAxisSpacing: 12.0,
        childAspectRatio: childAspectRatio,
      ),
      delegate: SliverChildBuilderDelegate((context, index) {
        final child = parent.children[index];
        return _buildGridChildCard(child, cs, isFullWidth: count == 1);
      }, childCount: count),
    );
  }

  Widget _buildGridChildCard(
    dynamic child,
    ColorScheme cs, {
    required bool isFullWidth,
  }) {
    final nim = child['student_nim'] ?? child['nim'] ?? '';
    final name = child['student_name'] ?? child['name'] ?? 'Tanpa Nama';
    final className = child['class_name'] ?? '-';
    final namaRombel = child['nama_rombel']?.toString() ?? '';
    final rombelSuffix = namaRombel.trim().isNotEmpty ? ' • Rombel: $namaRombel' : '';
    final sumber = (child['sumber'] ?? 'madrasah').toString().toUpperCase();
    final hubungan = child['hubungan'] ?? '';
    final String? fotoUrl = child['foto']?.toString();
    final bool hasFoto = fotoUrl != null && fotoUrl.trim().isNotEmpty;
    final String initialName = name.toString().trim().isNotEmpty
        ? name.toString().trim().substring(0, 1).toUpperCase()
        : '?';
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shadowColor: cs.shadow..withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ParentChildDetailPage(
                nim: nim.toString(),
                childName: name.toString(),
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: isFullWidth
              ? Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: cs.primaryContainer,
                      radius: 20,
                      // Hanya masukkan provider jika foto benar-benar ada
                      backgroundImage: hasFoto
                          ? cachedFotoProvider(fotoUrl)
                          : null,
                      onBackgroundImageError: hasFoto ? (_, _) {} : null,
                      // Tampilkan inisial jika foto tidak ada
                      child: !hasFoto
                          ? Text(
                              initialName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: cs.onPrimaryContainer,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name.toString().toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'NIM: $nim \u2022 Kelas: $className$rombelSuffix',
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurface..withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildTagsColumn(sumber, hubungan, cs),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: cs.onSurface..withValues(alpha: 0.4),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor: cs.primaryContainer,
                          radius: 20,
                          // Hanya masukkan provider jika foto benar-benar ada
                          backgroundImage: hasFoto
                              ? cachedFotoProvider(fotoUrl)
                              : null,
                          onBackgroundImageError: hasFoto ? (_, _) {} : null,
                          // Tampilkan inisial jika foto tidak ada
                          child: !hasFoto
                              ? Text(
                                  initialName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: cs.onPrimaryContainer,
                                  ),
                                )
                              : null,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: sumber == 'TPQ'
                                ? cs.secondaryContainer
                                : cs.primaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            sumber,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: sumber == 'TPQ'
                                  ? cs.onSecondaryContainer
                                  : cs.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      name.toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Kelas: $className$rombelSuffix',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurface..withValues(alpha: 0.6),
                      ),
                    ),
                    Text(
                      'NIM: $nim',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        color: cs.onSurface..withValues(alpha: 0.5),
                      ),
                    ),
                    const Spacer(),
                    if (hubungan.toString().isNotEmpty)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: cs.tertiaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            hubungan.toString(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: cs.onTertiaryContainer,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildTagsColumn(String sumber, String hubungan, ColorScheme cs) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (hubungan.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: cs.tertiaryContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              hubungan,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: cs.onTertiaryContainer,
              ),
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: sumber == 'TPQ'
                ? cs.secondaryContainer
                : cs.primaryContainer,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            sumber,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: sumber == 'TPQ'
                  ? cs.onSecondaryContainer
                  : cs.onPrimaryContainer,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerLoading(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Shimmer.fromColors(
      baseColor: cs.surfaceContainerHighest..withValues(alpha: 0.5),
      highlightColor: cs.surfaceContainerHighest..withValues(alpha: 0.2),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: List.generate(
              4,
              (_) => Container(
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// --- Fixed Curved AppBar Delegate Class ---
// ==========================================
class _CurvedAppBarDelegate extends SliverPersistentHeaderDelegate {
  final ColorScheme colorScheme;
  final double topPadding;
  final VoidCallback onThemeTap;
  final VoidCallback onLogoutTap;
  final Widget profile;
  final double maxExtentHeight;
  final double minExtentHeight;

  _CurvedAppBarDelegate({
    required this.colorScheme,
    required this.topPadding,
    required this.onThemeTap,
    required this.onLogoutTap,
    required this.profile,
    required this.maxExtentHeight,
    required this.minExtentHeight,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final double delta = maxExtentHeight - minExtentHeight;
    final double percent = delta > 0
        ? (shrinkOffset / delta).clamp(0.0, 1.0)
        : 0.0;
    final double currentRadius = 28.0 * (1.0 - percent);

    return Material(
      elevation: percent > 0.8 ? 2 : 0,
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.primary,
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(currentRadius),
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow..withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 4.0,
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    Text(
                      'Wali Murid / Santri',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        Icons.palette_outlined,
                        color: colorScheme.onPrimary,
                      ),
                      onPressed: onThemeTap,
                      tooltip: 'Pengaturan Tema',
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.logout_rounded,
                        color: colorScheme.onPrimary,
                      ),
                      onPressed: onLogoutTap,
                      tooltip: 'Logout',
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Opacity(
                  opacity: (1.0 - (percent * 1.5)).clamp(0.0, 1.0),
                  child: percent > 0.6 ? const SizedBox.shrink() : profile,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  double get maxExtent => maxExtentHeight;

  @override
  double get minExtent => minExtentHeight;

  @override
  bool shouldRebuild(covariant _CurvedAppBarDelegate oldDelegate) {
    return oldDelegate.colorScheme != colorScheme ||
        oldDelegate.topPadding != topPadding ||
        oldDelegate.maxExtentHeight != maxExtentHeight ||
        oldDelegate.minExtentHeight != minExtentHeight;
  }
}
