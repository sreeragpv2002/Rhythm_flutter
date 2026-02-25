import 'package:flutter/material.dart';

/// Brand color tokens for the Rhythm app.
///
/// Organized into semantic groups: brand, surface, text, border, status,
/// glassmorphism, and gradient presets.
class AppColors {
  AppColors._();

  // ── Brand / Primary ──
  static const Color primaryLight = Color(0xFF6C5CE7);
  static const Color primaryDark = Color(0xFF9B8DFF);

  // ── Brand / Accent ──
  static const Color accentLight = Color(0xFFFF6B6B);
  static const Color accentDark = Color(0xFFFF8A8A);

  // ── Tertiary (used for tags, badges, highlights) ──
  static const Color tertiaryLight = Color(0xFF00B4D8);
  static const Color tertiaryDark = Color(0xFF48CAE4);

  // ── Background ──
  static const Color backgroundLight = Color(0xFFF8F9FE);
  static const Color backgroundDark = Color(0xFF0D0D1A);

  // ── Surface ──
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1A1A2E);

  // ── Elevated surface (cards, modals) ──
  static const Color surfaceElevatedLight = Color(0xFFF3F0FF);
  static const Color surfaceElevatedDark = Color(0xFF252542);

  // ── Text ──
  static const Color textPrimaryLight = Color(0xFF1A1A2E);
  static const Color textSecondaryLight = Color(0xFF6B7280);
  static const Color textPrimaryDark = Color(0xFFF1F1F6);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);

  // ── Border ──
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color borderDark = Color(0xFF2D2D44);

  // ── Status ──
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // ── Glassmorphism-specific ──
  static const Color glassFillDark = Color(0x1AFFFFFF);   // white 10%
  static const Color glassFillLight = Color(0xBFFFFFFF);   // white 75%
  static const Color glassBorderDark = Color(0x14FFFFFF);  // white 8%
  static const Color glassBorderLight = Color(0x80FFFFFF); // white 50%
  static const Color glassOverlayDark = Color(0x8C000000); // black 55%
  static const Color glassOverlayLight = Color(0xBFFFFFFF); // white 75%

  // ── Gradients ──
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6C5CE7), Color(0xFF9B59B6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient splashGradient = LinearGradient(
    colors: [Color(0xFF0D0D1A), Color(0xFF1A1A3E), Color(0xFF2D1B69)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF6C5CE7), Color(0xFFa855f7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient playerGradient = LinearGradient(
    colors: [Color(0xFF1A0533), Color(0xFF0D0D1A), Color(0xFF0D0D1A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient playerGradientLight = LinearGradient(
    colors: [Color(0xFFF3F0FF), Color(0xFFF8F9FE), Color(0xFFF8F9FE)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient backgroundGradientDark = LinearGradient(
    colors: [backgroundDark, Color(0xFF121228)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient backgroundGradientLight = LinearGradient(
    colors: [backgroundLight, Color(0xFFEDE9FE)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
