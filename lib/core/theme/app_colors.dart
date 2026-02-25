import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Primary ──
  static const Color primaryLight = Color(0xFF6C5CE7);
  static const Color primaryDark = Color(0xFF9B8DFF);

  // ── Accent ──
  static const Color accentLight = Color(0xFFFF6B6B);
  static const Color accentDark = Color(0xFFFF8A8A);

  // ── Background ──
  static const Color backgroundLight = Color(0xFFF8F9FE);
  static const Color backgroundDark = Color(0xFF0D0D1A);

  // ── Surface ──
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1A1A2E);

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
}
