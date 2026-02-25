import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rhythm_flutter/core/extensions/context_extensions.dart';
import 'package:rhythm_flutter/core/theme/spacing.dart';
import 'package:rhythm_flutter/core/widgets/glass_card.dart';
import 'package:rhythm_flutter/features/auth/providers/auth_provider.dart';
import 'package:rhythm_flutter/shared/providers/locale_provider.dart';
import 'package:rhythm_flutter/shared/providers/theme_provider.dart';

class SettingsTab extends ConsumerWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);
    final locale = ref.watch(localeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          const SizedBox(height: AppSpacing.sm),

          Text(
            context.l10n.settings,
            style: context.textTheme.headlineMedium?.copyWith(
              color: isDark ? Colors.white : null,
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // ── Appearance section ──
          _SectionTitle(title: context.l10n.appearance, isDark: isDark),
          const SizedBox(height: AppSpacing.sm),

          GlassCard(
            child: Column(
              children: [
                // Theme mode selector (3-way)
                _SettingsTile(
                  icon: Icons.palette_rounded,
                  title: context.l10n.theme,
                  trailing: _ThemeModeSelector(
                    themeMode: themeMode,
                    onChanged: themeNotifier.setThemeMode,
                    isDark: isDark,
                  ),
                  isDark: isDark,
                ),
                Divider(
                  height: 1,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.06),
                ),
                // Language toggle
                _SettingsTile(
                  icon: Icons.language_rounded,
                  title: context.l10n.language,
                  trailing: DropdownButton<String>(
                    value: locale.languageCode,
                    underline: const SizedBox.shrink(),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    dropdownColor: isDark
                        ? const Color(0xFF252542)
                        : Colors.white,
                    items: const [
                      DropdownMenuItem(value: 'en', child: Text('English')),
                      DropdownMenuItem(value: 'ar', child: Text('العربية')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        ref.read(localeProvider.notifier).setLocale(Locale(value));
                      }
                    },
                  ),
                  isDark: isDark,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // ── Account section ──
          _SectionTitle(title: context.l10n.account, isDark: isDark),
          const SizedBox(height: AppSpacing.sm),

          GlassCard(
            child: _SettingsTile(
              icon: Icons.logout_rounded,
              title: context.l10n.logout,
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: isDark ? Colors.white38 : Colors.black26,
              ),
              iconColor: Colors.redAccent,
              isDark: isDark,
              onTap: () => _showLogoutDialog(context, ref),
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Future<void> _showLogoutDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.logout),
        content: Text(context.l10n.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              context.l10n.logout,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(authProvider.notifier).logout();
    }
  }
}

// ── Sub-widgets ──

class _SectionTitle extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SectionTitle({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.xs),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: isDark
              ? Colors.white.withValues(alpha: 0.4)
              : Colors.black.withValues(alpha: 0.4),
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget trailing;
  final Color? iconColor;
  final bool isDark;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.trailing,
    this.iconColor,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm + 4,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: (iconColor ?? Theme.of(context).colorScheme.primary)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Icon(
                icon,
                size: 20,
                color: iconColor ?? Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm + 4),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

/// 3-way theme mode selector (Light / Dark / System).
class _ThemeModeSelector extends StatelessWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onChanged;
  final bool isDark;

  const _ThemeModeSelector({
    required this.themeMode,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ModeChip(
            icon: Icons.light_mode_rounded,
            selected: themeMode == ThemeMode.light,
            onTap: () => onChanged(ThemeMode.light),
            isDark: isDark,
          ),
          _ModeChip(
            icon: Icons.dark_mode_rounded,
            selected: themeMode == ThemeMode.dark,
            onTap: () => onChanged(ThemeMode.dark),
            isDark: isDark,
          ),
          _ModeChip(
            icon: Icons.settings_brightness_rounded,
            selected: themeMode == ThemeMode.system,
            onTap: () => onChanged(ThemeMode.system),
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;

  const _ModeChip({
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs + 2,
        ),
        decoration: BoxDecoration(
          color: selected ? primaryColor.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm - 2),
        ),
        child: Icon(
          icon,
          size: 18,
          color: selected
              ? primaryColor
              : isDark
                  ? Colors.white38
                  : Colors.black38,
        ),
      ),
    );
  }
}
