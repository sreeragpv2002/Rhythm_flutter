import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:rhythm_flutter/core/theme/spacing.dart';

/// Reusable glassmorphism decoration factories.
///
/// Usage:
/// ```dart
/// ClipRRect(
///   borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
///   child: BackdropFilter(
///     filter: GlassDecoration.blur(),
///     child: Container(
///       decoration: GlassDecoration.card(context),
///       child: content,
///     ),
///   ),
/// )
/// ```
class GlassDecoration {
  GlassDecoration._();

  // ── Blur presets ──

  static ImageFilter blur({double sigma = 12}) =>
      ImageFilter.blur(sigmaX: sigma, sigmaY: sigma);

  static ImageFilter blurLight() => blur(sigma: 8);
  static ImageFilter blurHeavy() => blur(sigma: 20);

  // ── Card decoration ──

  static BoxDecoration card(BuildContext context, {
    double borderRadius = AppSpacing.radiusMd,
    double opacity = 0.12,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      color: isDark
          ? Colors.white.withValues(alpha: opacity)
          : Colors.white.withValues(alpha: 0.65),
      border: Border.all(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.5),
        width: 1,
      ),
    );
  }

  // ── Nav bar / Mini player surface ──

  static BoxDecoration surface(BuildContext context, {
    double opacity = 0.15,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark
          ? Colors.black.withValues(alpha: 0.55)
          : Colors.white.withValues(alpha: 0.75),
      border: Border(
        top: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.06),
          width: 0.5,
        ),
      ),
    );
  }

  // ── Elevated card (slightly more opaque for highlighted items) ──

  static BoxDecoration elevated(BuildContext context, {
    double borderRadius = AppSpacing.radiusLg,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      color: isDark
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.white.withValues(alpha: 0.8),
      border: Border.all(
        color: isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.black.withValues(alpha: 0.05),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  // ── Glow shadow for floating elements (play button, album art) ──

  static List<BoxShadow> glow(Color color, {double intensity = 0.4}) => [
    BoxShadow(
      color: color.withValues(alpha: intensity),
      blurRadius: 32,
      spreadRadius: 4,
    ),
  ];
}
