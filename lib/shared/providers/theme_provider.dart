import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rhythm_flutter/core/constants/app_constants.dart';

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

/// Manages theme mode with 3-way support: light, dark, system.
///
/// Persists the mode as a string in SharedPreferences.
/// Handles migration from the legacy boolean storage format.
class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.dark) {
    _loadTheme();
  }

  static const _modeKey = AppConstants.themeKey;

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();

    // ── Migration: old boolean format → new string format ──
    final legacyBool = prefs.get(_modeKey);
    if (legacyBool is bool) {
      final migrated = legacyBool ? 'dark' : 'light';
      await prefs.setString(_modeKey, migrated);
      state = _fromString(migrated);
      return;
    }

    final stored = prefs.getString(_modeKey) ?? 'dark';
    state = _fromString(stored);
  }

  /// Set a specific theme mode.
  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modeKey, _toString(mode));
  }

  /// Toggle between dark and light (legacy convenience method).
  Future<void> toggleTheme() async {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(next);
  }

  /// Cycle through: dark → light → system → dark …
  Future<void> cycleTheme() async {
    final next = switch (state) {
      ThemeMode.dark => ThemeMode.light,
      ThemeMode.light => ThemeMode.system,
      ThemeMode.system => ThemeMode.dark,
    };
    await setThemeMode(next);
  }

  bool get isDark => state == ThemeMode.dark;
  bool get isSystem => state == ThemeMode.system;

  // ── Helpers ──

  static ThemeMode _fromString(String value) => switch (value) {
    'light' => ThemeMode.light,
    'system' => ThemeMode.system,
    _ => ThemeMode.dark,
  };

  static String _toString(ThemeMode mode) => switch (mode) {
    ThemeMode.light => 'light',
    ThemeMode.system => 'system',
    ThemeMode.dark => 'dark',
  };

  /// Human-readable label for UI display.
  String get label => switch (state) {
    ThemeMode.dark => 'Dark',
    ThemeMode.light => 'Light',
    ThemeMode.system => 'System',
  };
}
