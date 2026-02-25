import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rhythm_flutter/core/extensions/context_extensions.dart';
import 'package:rhythm_flutter/core/theme/app_colors.dart';
import 'package:rhythm_flutter/core/theme/glass_decoration.dart';
import 'package:rhythm_flutter/core/theme/spacing.dart';
import 'package:rhythm_flutter/features/player/presentation/mini_player.dart';

/// Main shell with bottom navigation and glassmorphism mini-player.
class MainScreen extends ConsumerStatefulWidget {
  final Widget child;
  const MainScreen({super.key, required this.child});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: widget.child,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Mini Player ──
          const MiniPlayer(),

          // ── Glassmorphism Nav Bar ──
          ClipRect(
            child: BackdropFilter(
              filter: GlassDecoration.blur(),
              child: Container(
                height: AppSpacing.bottomNavHeight,
                decoration: GlassDecoration.surface(context),
                child: BottomNavigationBar(
                  currentIndex: _currentIndex,
                  onTap: _onTabTapped,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  type: BottomNavigationBarType.fixed,
                  selectedFontSize: 11,
                  unselectedFontSize: 11,
                  selectedItemColor: isDark
                      ? AppColors.primaryDark
                      : AppColors.primaryLight,
                  unselectedItemColor: isDark
                      ? Colors.white.withValues(alpha: 0.4)
                      : Colors.black.withValues(alpha: 0.35),
                  items: [
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.home_rounded),
                      activeIcon: const Icon(Icons.home_rounded),
                      label: context.l10n.home,
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.search_rounded),
                      activeIcon: const Icon(Icons.search_rounded),
                      label: context.l10n.search,
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.settings_rounded),
                      activeIcon: const Icon(Icons.settings_rounded),
                      label: context.l10n.settings,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);

    switch (index) {
      case 0:
        context.go('/');
      case 1:
        context.go('/search');
      case 2:
        context.go('/settings');
    }
  }
}
