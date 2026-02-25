import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rhythm_flutter/core/extensions/context_extensions.dart';
import 'package:rhythm_flutter/core/widgets/gradient_background.dart';
import 'package:rhythm_flutter/shared/providers/locale_provider.dart';
import 'package:rhythm_flutter/shared/providers/theme_provider.dart';
import 'package:rhythm_flutter/features/auth/providers/auth_provider.dart';

class SettingsTab extends ConsumerWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeProvider);

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                context.l10n.settings,
                style: context.textTheme.headlineMedium,
              ),
              const SizedBox(height: 32),
              
              // Appearance Section
              Text(
                context.l10n.appearance,
                style: context.textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _buildSettingCard(
                context,
                title: context.l10n.darkMode,
                trailing: Switch(
                  value: themeMode == ThemeMode.dark,
                  onChanged: (value) => ref.read(themeProvider.notifier).toggleTheme(),
                ),
                icon: Icons.dark_mode_outlined,
              ),
              const SizedBox(height: 12),
              _buildSettingCard(
                context,
                title: context.l10n.language,
                subtitle: locale.languageCode == 'en' ? context.l10n.english : context.l10n.arabic,
                onTap: () => ref.read(localeProvider.notifier).toggleLocale(),
                icon: Icons.language,
              ),
              
              const SizedBox(height: 32),
              
              // Account Section
              Text(
                context.l10n.account,
                style: context.textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _buildSettingCard(
                context,
                title: context.l10n.logout,
                onTap: () => _showLogoutDialog(context, ref),
                icon: Icons.logout,
                color: context.colorScheme.error,
              ),
              
              const SizedBox(height: 48),
              Center(
                child: Text(
                  '${context.l10n.version} 1.0.0',
                  style: context.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingCard(
    BuildContext context, {
    required String title,
    String? subtitle,
    Widget? trailing,
    required IconData icon,
    VoidCallback? onTap,
    Color? color,
  }) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: color ?? context.colorScheme.primary),
        title: Text(
          title,
          style: TextStyle(color: color),
        ),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right) : null),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.logout),
        content: Text(context.l10n.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
            },
            child: Text(
              context.l10n.confirm,
              style: TextStyle(color: context.colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
