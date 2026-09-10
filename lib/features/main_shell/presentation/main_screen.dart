import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rhythm_flutter/core/extensions/context_extensions.dart';
import 'package:rhythm_flutter/core/theme/app_colors.dart';
import 'package:rhythm_flutter/core/theme/glass_decoration.dart';
import 'package:rhythm_flutter/core/theme/spacing.dart';
import 'package:rhythm_flutter/features/main_shell/presentation/widgets/desktop_nav_sidebar.dart';
import 'package:rhythm_flutter/features/player/presentation/desktop_player_sidebar.dart';
import 'package:rhythm_flutter/features/player/presentation/mini_player.dart';

/// Main shell supporting desktop 3-column architecture (left nav, center content, right player)
/// and mobile layout with glassmorphic bottom navigation & mini-player.
class MainScreen extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;
  const MainScreen({super.key, required this.navigationShell});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 960;

    // ── Desktop Layout (>= 960px) ──
    if (isDesktop) {
      return Scaffold(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        body: Row(
          children: [
            // Left Navigation Sidebar
            DesktopNavSidebar(
              currentIndex: widget.navigationShell.currentIndex,
              onTabSelected: _onTabTapped,
            ),

            // Center Content Shell (Home, Search, Settings)
            Expanded(
              child: widget.navigationShell,
            ),

            // Right Desktop Player Sidebar (Now Playing)
            const DesktopPlayerSidebar(),
          ],
        ),
        // On desktop, no bottom bar and no bottom mini-player
        bottomNavigationBar: null,
      );
    }

    // ── Mobile / Tablet Layout (< 960px) ──
    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: widget.navigationShell,
      bottomNavigationBar: Container(
        color: Colors.transparent,
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Floating Mini Player ──
              const MiniPlayer(),

              // ── Glassmorphism Nav Bar ──
              ClipRect(
                child: BackdropFilter(
                  filter: GlassDecoration.blur(),
                  child: Container(
                    height: AppSpacing.bottomNavHeight,
                    decoration: GlassDecoration.surface(context),
                    child: BottomNavigationBar(
                      currentIndex: widget.navigationShell.currentIndex,
                      onTap: _onTabTapped,
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      iconSize: 22,
                      type: BottomNavigationBarType.fixed,
                      selectedFontSize: 10.5,
                      unselectedFontSize: 10.5,
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
        ),
      ),
    );
  }

  void _onTabTapped(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }
}
