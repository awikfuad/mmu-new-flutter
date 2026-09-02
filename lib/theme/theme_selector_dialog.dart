import 'package:flutter/material.dart';

import '../providers/theme_provider.dart';


class ThemeSelectorDialog extends StatelessWidget {
  final ThemeProvider themeProvider;

  const ThemeSelectorDialog({
    super.key,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: 400,
        ),
        color: theme.dialogTheme.backgroundColor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. HEADER (STICKY ATAS)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha:0.5),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.palette_outlined, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Pengaturan Tema',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // 2. KONTEN (SCROLLABLE AREA)
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Opsi Mode Tema (Sistem, Terang, Gelap)
                    Text(
                      'Mode Tampilan',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SegmentedButton<ThemeMode>(
  style: const ButtonStyle(
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    visualDensity: VisualDensity.compact,
  ),
  segments: const [
    ButtonSegment(
      value: ThemeMode.system,
      icon: Icon(Icons.brightness_auto, size: 16),
      label: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text('Sistem', style: TextStyle(fontSize: 12)),
      ),
    ),
    ButtonSegment(
      value: ThemeMode.light,
      icon: Icon(Icons.light_mode, size: 16),
      label: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text('Terang', style: TextStyle(fontSize: 12)),
      ),
    ),
    ButtonSegment(
      value: ThemeMode.dark,
      icon: Icon(Icons.dark_mode, size: 16),
      label: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text('Gelap', style: TextStyle(fontSize: 12)),
      ),
    ),
  ],
  selected: {themeProvider.themeMode},
  onSelectionChanged: (Set<ThemeMode> newSelection) {
    themeProvider.setThemeMode(newSelection.first);
  },
),
                    const SizedBox(height: 20),

                    // Warna Aksen Utama (Presets Color)
                    Text(
                      'Warna Utama Aplikasi',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: ThemeProvider.colorPresets.map((color) {
                        // ignore: deprecated_member_use
                        final isSelected = themeProvider.seedColor.value == color.value;
                        return InkWell(
                          onTap: () => themeProvider.setSeedColor(color),
                          borderRadius: BorderRadius.circular(24),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? colorScheme.onSurface
                                    : Colors.transparent,
                                width: 2.5,
                              ),
                              boxShadow: [
                                if (isSelected)
                                  BoxShadow(
                                    color: color.withValues(alpha:0.4),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                              ],
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  )
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            // 3. ACTION FOOTER (STICKY BAWAH)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha:0.5),
                  ),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Selesai'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}