import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rhythm_flutter/core/extensions/context_extensions.dart';
import 'package:rhythm_flutter/core/services/audio_quality_service.dart';
import 'package:rhythm_flutter/core/theme/app_colors.dart';
import 'package:rhythm_flutter/core/theme/spacing.dart';
import 'package:rhythm_flutter/core/theme/scroll_physics.dart';
import 'package:rhythm_flutter/core/widgets/glass_card.dart';
import 'package:rhythm_flutter/features/auth/providers/auth_provider.dart';
import 'package:rhythm_flutter/features/home/providers/favorites_provider.dart';
import 'package:rhythm_flutter/features/language/providers/language_provider.dart';
import 'package:rhythm_flutter/features/playlist/providers/user_playlist_provider.dart';
import 'package:rhythm_flutter/shared/providers/theme_provider.dart';

class SettingsTab extends ConsumerWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);
    final langState = ref.watch(languageProvider);
    final favoritesCount = ref.watch(favoritesProvider).length;
    final playlists = ref.watch(userPlaylistsProvider).valueOrNull ?? [];
    final customPlaylistsCount = playlists.where((p) => !p.isFavorite).length;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 960;

    final selectedLangs = langState.selectedLanguages;
    final langsSummary = selectedLangs.isNotEmpty
        ? selectedLangs
            .map((e) => e.isNotEmpty ? '${e[0].toUpperCase()}${e.substring(1)}' : e)
            .join(', ')
        : 'None selected';

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 750),
          child: ListView(
            physics: AppScrollPhysics.adaptive,
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              isDesktop ? 32 : (AppSpacing.xxl + AppSpacing.miniPlayerHeight),
            ),
            children: [
              const SizedBox(height: AppSpacing.sm),

              Text(
                context.l10n.settings,
                style: context.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : null,
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // ── Library & Favorites section ──
              _SectionTitle(title: 'Library & Collection', isDark: isDark),
              const SizedBox(height: AppSpacing.sm),

              GlassCard(
                child: Column(
                  children: [
                    _SettingsTile(
                      icon: Icons.favorite_rounded,
                      iconColor: const Color(0xFFFF4B6E),
                      title: 'Favorite Songs',
                      subtitle: '$favoritesCount ${favoritesCount == 1 ? "track" : "tracks"} in your favorites collection',
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF4B6E).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$favoritesCount ${favoritesCount == 1 ? "song" : "songs"}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFFF4B6E),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: isDark ? Colors.white38 : Colors.black26,
                          ),
                        ],
                      ),
                      isDark: isDark,
                      onTap: () => context.push('/settings/favorites'),
                    ),
                    Divider(
                      height: 1,
                      indent: 52,
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
                    ),
                    _SettingsTile(
                      icon: Icons.queue_music_rounded,
                      iconColor: const Color(0xFF6C5CE7),
                      title: 'Your Playlists',
                      subtitle: '$customPlaylistsCount ${customPlaylistsCount == 1 ? "playlist" : "playlists"} created by you',
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6C5CE7).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$customPlaylistsCount ${customPlaylistsCount == 1 ? "playlist" : "playlists"}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF6C5CE7),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: isDark ? Colors.white38 : Colors.black26,
                          ),
                        ],
                      ),
                      isDark: isDark,
                      onTap: () => context.push('/settings/playlists'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // ── Music Preferences section ──
              _SectionTitle(title: 'Music Preferences', isDark: isDark),
              const SizedBox(height: AppSpacing.sm),

              GlassCard(
                child: Column(
                  children: [
                    _SettingsTile(
                      icon: Icons.language_rounded,
                      title: 'Music Languages',
                      subtitle: langsSummary,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: (isDark
                                      ? AppColors.primaryDark
                                      : AppColors.primaryLight)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${selectedLangs.length} active',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.primaryDark
                                    : AppColors.primaryLight,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: isDark ? Colors.white38 : Colors.black26,
                          ),
                        ],
                      ),
                      isDark: isDark,
                      onTap: () => context.push('/settings/languages'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // ── Audio & Streaming Quality section ──
              _SectionTitle(title: 'Audio & Streaming Quality', isDark: isDark),
              const SizedBox(height: AppSpacing.sm),

              Consumer(
                builder: (context, ref, _) {
                  final qualityPref = ref.watch(audioQualityPreferenceProvider);
                  final speedService = ref.watch(networkSpeedServiceProvider);
                  final grade = ref.watch(networkSpeedGradeProvider).valueOrNull ?? speedService.currentGrade;
                  final speedKbps = ref.watch(networkSpeedKbpsProvider).valueOrNull ?? speedService.currentSpeedKbps;

                  return GlassCard(
                    child: Column(
                      children: [
                        _SettingsTile(
                          icon: Icons.graphic_eq_rounded,
                          title: 'Streaming Quality',
                          subtitle: qualityPref.title,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (isDark
                                          ? AppColors.primaryDark
                                          : AppColors.primaryLight)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  qualityPref == AudioQualityPreference.auto ? 'AUTO' : qualityPref.code.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? AppColors.primaryDark
                                        : AppColors.primaryLight,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: isDark ? Colors.white38 : Colors.black26,
                              ),
                            ],
                          ),
                          isDark: isDark,
                          onTap: () => _showQualitySelectionDialog(context, ref),
                        ),
                        Divider(
                          height: 1,
                          indent: 52,
                          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
                        ),
                        _SettingsTile(
                          icon: Icons.speed_rounded,
                          title: 'Network Bandwidth',
                          subtitle: '${(speedKbps / 1000.0).toStringAsFixed(1)} Mbps • ${grade.label}',
                          trailing: TextButton(
                            onPressed: () => speedService.runSpeedProbe(),
                            child: const Text('Test Speed', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                          isDark: isDark,
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: AppSpacing.lg),

              // ── Appearance section ──
              _SectionTitle(title: context.l10n.appearance, isDark: isDark),
              const SizedBox(height: AppSpacing.sm),

              GlassCard(
                child: _SettingsTile(
                  icon: Icons.palette_rounded,
                  title: context.l10n.theme,
                  trailing: _ThemeModeSelector(
                    themeMode: themeMode,
                    onChanged: themeNotifier.setThemeMode,
                    isDark: isDark,
                  ),
                  isDark: isDark,
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
        ),
      ),
    );
  }

  Future<void> _showQualitySelectionDialog(BuildContext context, WidgetRef ref) async {
    final currentPref = ref.read(audioQualityPreferenceProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF16162C) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.graphic_eq_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              const Text('Streaming Quality', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose your preferred sound quality. Auto will dynamically adjust based on your real-time network connection.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.black54,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                ...AudioQualityPreference.values.map((pref) {
                  final isSelected = currentPref == pref;

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: isSelected ? AppColors.primaryLight : (isDark ? Colors.white38 : Colors.black38),
                      size: 20,
                    ),
                    title: Text(
                      pref.title,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    subtitle: Text(
                      pref.subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                    onTap: () async {
                      await ref.read(audioQualityPreferenceProvider.notifier).setPreference(pref);
                      if (context.mounted) Navigator.pop(context);
                    },
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
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
  final String? subtitle;
  final Widget trailing;
  final Color? iconColor;
  final bool isDark;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black45,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
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
