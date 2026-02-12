/// Accent Color Picker Widget
/// Beautiful color selection widget for settings
library;

import 'dart:ui';

import 'package:cashpilot/core/theme/accent_colors.dart'
    show AccentColorOption, AccentColors, accentColorProvider;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_typography.dart';
import 'package:cashpilot/l10n/app_localizations.dart';

class AccentColorPicker extends ConsumerWidget {
  const AccentColorPicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentOption = ref.watch(accentColorProvider);
    final theme = Theme.of(context);
    final currentConfig = AccentColors.getConfig(currentOption);
    final options = AccentColors.allOptions;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.65),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: theme.brightness == Brightness.dark ? 0.18 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: currentConfig.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: currentConfig.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: Icon(
                  Icons.palette_rounded,
                  color: currentConfig.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.accentColorTheme,
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: currentConfig.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: currentConfig.primary.withValues(alpha: 0.35),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context)!.accentColorCurrently(currentConfig.displayName),
                            style: AppTypography.bodySmall.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Small divider to make it feel “settings-grade”
          Container(
            height: 1,
            width: double.infinity,
            color: theme.dividerColor.withValues(alpha: 0.55),
          ),

          const SizedBox(height: 18),

          // Color Selection Row
          Center(
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: options.map((config) {
                final isSelected = config.name == currentConfig.name;
                final optionEnum = AccentColorOption.values.firstWhere((e) => e.name == config.name);

                return _ColorDot(
                  keyId: config.name,
                  name: config.displayName,
                  color: config.primary,
                  selected: isSelected,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ref.read(accentColorProvider.notifier).setAccentColor(optionEnum);
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorDot extends StatefulWidget {
  final String keyId;
  final String name;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ColorDot({
    required this.keyId,
    required this.name,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_ColorDot> createState() => _ColorDotState();
}

class _ColorDotState extends State<_ColorDot> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final ringColor = widget.selected
        ? Colors.white
        : theme.colorScheme.surface.withValues(alpha: 0.0);

    final shadowBase = widget.selected
        ? widget.color.withValues(alpha: 0.45)
        : Colors.black.withValues(alpha: theme.brightness == Brightness.dark ? 0.22 : 0.10);

    final scale = widget.selected
        ? (_pressed ? 0.98 : 1.02)
        : (_pressed ? 0.96 : 1.0);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: Column(
        children: [
          AnimatedScale(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            scale: scale,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: ringColor,
                  width: widget.selected ? 3 : 0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: shadowBase,
                    blurRadius: widget.selected ? 14 : 8,
                    spreadRadius: widget.selected ? 2 : 0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: widget.selected
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 24)
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            style: AppTypography.labelSmall.copyWith(
              color: widget.selected
                  ? widget.color
                  : theme.colorScheme.onSurface.withValues(alpha: 0.62),
              fontWeight: widget.selected ? FontWeight.w800 : FontWeight.w600,
              letterSpacing: -0.1,
            ),
            child: Text(widget.name),
          ),
        ],
      ),
    );
  }
}

/// Compact color picker for quick access
class AccentColorPickerCompact extends ConsumerWidget {
  const AccentColorPickerCompact({super.key});

  // Curated 6 colors (2x3 grid layout)
  static const _supportedOptions = [
    AccentColorOption.emerald,
    AccentColorOption.ocean,
    AccentColorOption.coral,
    AccentColorOption.amber,
    AccentColorOption.violet,
    AccentColorOption.slate,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentOption = ref.watch(accentColorProvider);

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _supportedOptions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final option = _supportedOptions[index];
          final config = AccentColors.getConfig(option);
          final isSelected = option == currentOption;

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticFeedback.lightImpact();
              ref.read(accentColorProvider.notifier).setAccentColor(option);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: config.primary,
                border: Border.all(
                  color: isSelected
                      ? Colors.white
                      : theme.dividerColor.withValues(alpha: 0.0),
                  width: isSelected ? 2.8 : 0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? config.primary.withValues(alpha: 0.45)
                        : Colors.black.withValues(alpha: theme.brightness == Brightness.dark ? 0.18 : 0.10),
                    blurRadius: isSelected ? 12 : 8,
                    spreadRadius: isSelected ? 1 : 0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                  : null,
            ),
          );
        },
      ),
    );
  }
}

/// Sheet to pick accent color
Future<void> showAccentColorSheet(BuildContext context) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final primaryColor = theme.primaryColor;

  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.7),
    isScrollControlled: true,
    builder: (context) => ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? Colors.black.withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.85),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
            border: Border.all(
              color: isDark 
                  ? Colors.white.withValues(alpha: 0.25) 
                  : Colors.white.withValues(alpha: 0.5),
              width: 1,
            ),
             gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark ? [
                Colors.black.withValues(alpha: 0.8),
                Colors.black.withValues(alpha: 0.6),
              ] : [
                  Colors.white.withValues(alpha: 0.9),
                  Colors.white.withValues(alpha: 0.6),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.15),
                blurRadius: 30,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle + close
                Row(
                  children: [
                    Expanded(
                      child: Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: AppLocalizations.of(context)!.commonClose,
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close_rounded,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Title
                Text(
                  AppLocalizations.of(context)!.accentColorTitle.toUpperCase(),
                  style: AppTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: primaryColor,
                    shadows: [
                      Shadow(
                          color: primaryColor.withValues(alpha: 0.5),
                          blurRadius: 10,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  AppLocalizations.of(context)!.accentColorSubtitle,
                  style: AppTypography.bodyMedium.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
                  ),
                ),

                const SizedBox(height: 18),

                // Color Picker - Refactored to float on glass
                const AccentColorPicker(),

                const SizedBox(height: 18),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
