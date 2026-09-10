import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rhythm_flutter/core/animations/app_animations.dart';
import 'package:rhythm_flutter/core/extensions/context_extensions.dart';
import 'package:rhythm_flutter/core/theme/app_colors.dart';
import 'package:rhythm_flutter/core/theme/spacing.dart';
import 'package:rhythm_flutter/core/widgets/shimmer_loading.dart';
import 'package:rhythm_flutter/features/auth/providers/auth_provider.dart';
import 'package:rhythm_flutter/features/home/data/models/home_feed.dart';
import 'package:rhythm_flutter/features/home/presentation/widgets/home_item_card.dart';
import 'package:rhythm_flutter/features/home/providers/home_provider.dart';
import 'package:rhythm_flutter/features/player/providers/audio_provider.dart';

/// Senior-styled, responsive Home tab with hero greeting, quick-play 6-grid,
/// section filter pills, elevated cards, and adaptive desktop/mobile spacing.
class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({super.key});

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab> {
  String _selectedFilter = 'All';

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final homeAsync = ref.watch(homeProvider);
    final handler = ref.read(audioHandlerProvider);
    final locale = context.l10n.localeName;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 960;

    final authState = ref.watch(authProvider);
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final email = authState.email ?? firebaseUser?.email;
    final displayName = firebaseUser?.displayName ??
        (email?.isNotEmpty == true ? email!.split('@').first : 'Listener');

    return homeAsync.when(
      loading: () => _buildShimmer(isDark),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: AppSpacing.iconXl,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: context.textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton.icon(
                onPressed: () =>
                    ref.read(homeProvider.notifier).fetchHomeFeed(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (feed) {
        if (feed.sections.isEmpty) {
          return Center(child: Text(context.l10n.noResults));
        }

        // Filter sections based on selected chip
        final filteredSections = feed.sections.where((s) {
          if (_selectedFilter == 'All') return true;
          if (_selectedFilter == 'Music') {
            return s.items.any((i) => i.isSong);
          }
          if (_selectedFilter == 'Playlists') {
            return s.items.any((i) => i.isPlaylist);
          }
          if (_selectedFilter == 'Albums') {
            return s.items.any((i) => i.isAlbum);
          }
          if (_selectedFilter == 'Artists') {
            return s.items.any((i) => i.isArtist);
          }
          return true;
        }).toList();

        // Extract up to 6 quick-play items from first song-heavy section
        final quickPlayItems = feed.sections
            .expand((s) => s.items)
            .where((i) => i.isSong || i.isPlaylist || i.isAlbum)
            .take(6)
            .toList();

        return RefreshIndicator(
          onRefresh: () => ref.read(homeProvider.notifier).fetchHomeFeed(),
          displacement: AppSpacing.xl,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // ── Hero Ambient Glow & Greeting Header ──
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        (isDark
                                ? const Color(0xFF2B1855)
                                : const Color(0xFFE9E4FA))
                            .withValues(alpha: isDark ? 0.45 : 0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md + 4,
                    AppSpacing.lg,
                    AppSpacing.md + 4,
                    AppSpacing.sm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Greeting title
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_getGreeting()}, $displayName 👋',
                                  style: TextStyle(
                                    fontSize: isDesktop ? 26 : 22,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.textPrimaryLight,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'What do you want to listen to today?',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark
                                        ? Colors.white54
                                        : AppColors.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // ── Filter Pills ──
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _FilterPill(
                              label: 'All',
                              isSelected: _selectedFilter == 'All',
                              isDark: isDark,
                              onTap: () =>
                                  setState(() => _selectedFilter = 'All'),
                            ),
                            _FilterPill(
                              label: 'Music',
                              isSelected: _selectedFilter == 'Music',
                              isDark: isDark,
                              onTap: () =>
                                  setState(() => _selectedFilter = 'Music'),
                            ),
                            _FilterPill(
                              label: 'Playlists',
                              isSelected: _selectedFilter == 'Playlists',
                              isDark: isDark,
                              onTap: () => setState(
                                  () => _selectedFilter = 'Playlists'),
                            ),
                            _FilterPill(
                              label: 'Albums',
                              isSelected: _selectedFilter == 'Albums',
                              isDark: isDark,
                              onTap: () =>
                                  setState(() => _selectedFilter = 'Albums'),
                            ),
                            _FilterPill(
                              label: 'Artists',
                              isSelected: _selectedFilter == 'Artists',
                              isDark: isDark,
                              onTap: () =>
                                  setState(() => _selectedFilter = 'Artists'),
                            ),
                          ],
                        ),
                      ),

                      // ── Quick-Play 6-Item Grid ──
                      if (quickPlayItems.isNotEmpty &&
                          _selectedFilter == 'All') ...[
                        const SizedBox(height: 20),
                        _QuickPlayGrid(
                          items: quickPlayItems,
                          isDark: isDark,
                          onItemTap: (item) {
                            if (item.isSong) {
                              final mediaItems = quickPlayItems
                                  .map((i) => homeItemToMediaItem(i))
                                  .toList();
                              final index = quickPlayItems.indexOf(item);
                              handler.loadPlaylist(mediaItems,
                                  initialIndex: index >= 0 ? index : 0);
                            } else if (item.isAlbum) {
                              context.push('/album/${item.id}');
                            } else if (item.isPlaylist) {
                              context.push('/playlist/${item.id}');
                            } else if (item.isArtist) {
                              context.push('/artist/${item.id}');
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.sm),
              ),

              // ── Feed Sections ──
              ...filteredSections.asMap().entries.map((entry) {
                final sectionIndex = entry.key;
                final section = entry.value;

                final items = section.items;
                if (items.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

                final itemCount = items.length;
                final bool hideViewAll = section.slug == 'recent_plays' ||
                    section.slug == 'trending_albums' ||
                    section.slug == 'top_artists' ||
                    section.slug.contains('album') ||
                    section.slug.contains('artist') ||
                    section.slug.contains('recent');
                final bool showViewAll = !hideViewAll;

                return SliverMainAxisGroup(
                  slivers: [
                    SliverToBoxAdapter(
                      child: SlideUpFadeIn(
                        delay: AppAnimations.stagger(sectionIndex),
                        duration: AppAnimations.normal,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            AppSpacing.md,
                            AppSpacing.md,
                            AppSpacing.sm,
                          ),
                          child: Row(
                            children: [
                              // Accent gradient vertical indicator
                              Container(
                                width: 4,
                                height: 18,
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Section title
                              Expanded(
                                child: Text(
                                  section.getDisplayTitle(locale),
                                  style: context.textTheme.titleLarge?.copyWith(
                                    color: isDark ? Colors.white : null,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                              ),

                              // View All Button (Shown only for Trending Songs and Playlists)
                              if (showViewAll)
                                InkWell(
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: () {
                                    context.push(
                                      '/section/${section.slug}',
                                      extra: section.getDisplayTitle(locale),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          context.l10n.viewAll,
                                          style: TextStyle(
                                            color: isDark
                                                ? AppColors.primaryDark
                                                : AppColors.primaryLight,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          size: 10,
                                          color: isDark
                                              ? AppColors.primaryDark
                                              : AppColors.primaryLight,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Horizontal Card Carousel (Dynamic height: 150 for artists, 205 for albums/songs/playlists)
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: (section.slug == 'top_artists' || (items.isNotEmpty && items.first.isArtist)) ? 150 : 205,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          itemCount: itemCount,
                          itemBuilder: (context, index) {
                            final item = items[index];

                            return FadeScaleIn(
                              delay: AppAnimations.stagger(index, baseMs: 35),
                              duration: AppAnimations.normal,
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: index != itemCount - 1
                                      ? AppSpacing.sm + 6
                                      : 0,
                                ),
                                child: HomeItemCard(
                                  item: item,
                                  onTap: () {
                                    if (item.isSong) {
                                      final songItems =
                                          items.where((i) => i.isSong).toList();
                                      final songIndex =
                                          songItems.indexOf(item);
                                      final mediaItems = (songItems.isNotEmpty
                                              ? songItems
                                              : items)
                                          .map((i) => homeItemToMediaItem(i))
                                          .toList();
                                      handler.loadPlaylist(
                                        mediaItems,
                                        initialIndex: songIndex >= 0
                                            ? songIndex
                                            : index,
                                      );
                                    } else if (item.isAlbum) {
                                      context.push('/album/${item.id}');
                                    } else if (item.isPlaylist) {
                                      context.push('/playlist/${item.id}');
                                    } else if (item.isArtist) {
                                      context.push('/artist/${item.id}');
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(
                      child: SizedBox(height: AppSpacing.sm),
                    ),
                  ],
                );
              }),

              // ── Bottom Adaptive Padding ──
              // Desktop has NO bottom bar, so standard spacing.
              // Mobile leaves tight, proportional space for floating mini-player & nav bar.
              SliverToBoxAdapter(
                child: SizedBox(
                  height: isDesktop
                      ? 32
                      : (AppSpacing.md + AppSpacing.miniPlayerHeight + AppSpacing.bottomNavHeight + 10),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Shimmer skeleton while loading
  Widget _buildShimmer(bool isDark) {
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(AppSpacing.md, 24, AppSpacing.md, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(
                  width: 220,
                  height: 28,
                  borderRadius: AppSpacing.radiusSm,
                ),
                SizedBox(height: 8),
                ShimmerBox(
                  width: 160,
                  height: 16,
                  borderRadius: AppSpacing.radiusSm,
                ),
              ],
            ),
          ),
        ),
        ...List.generate(3, (sectionIdx) {
          return SliverMainAxisGroup(
            slivers: [
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.sm + 4,
                  ),
                  child: ShimmerBox(
                    width: 140,
                    height: 20,
                    borderRadius: AppSpacing.radiusSm,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 220,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    itemCount: 4,
                    itemBuilder: (_, idx) => Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm + 6),
                      child: ShimmerLoading.musicCard(),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),
            ],
          );
        }),
      ],
    );
  }
}

/// Filter pill button for category navigation
class _FilterPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark ? Colors.white : AppColors.primaryLight)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.07)
                      : Colors.black.withValues(alpha: 0.05)),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? Colors.transparent
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.08)),
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? (isDark ? Colors.black : Colors.white)
                    : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Spotify-style 6-item Quick-Play Grid
class _QuickPlayGrid extends StatelessWidget {
  final List<HomeItem> items;
  final bool isDark;
  final ValueChanged<HomeItem> onItemTap;

  const _QuickPlayGrid({
    required this.items,
    required this.isDark,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 650 ? 3 : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisExtent: 56,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return _QuickPlayTile(
              item: item,
              isDark: isDark,
              onTap: () => onItemTap(item),
            );
          },
        );
      },
    );
  }
}

class _QuickPlayTile extends StatefulWidget {
  final HomeItem item;
  final bool isDark;
  final VoidCallback onTap;

  const _QuickPlayTile({
    required this.item,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_QuickPlayTile> createState() => _QuickPlayTileState();
}

class _QuickPlayTileState extends State<_QuickPlayTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        if (mounted) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (mounted) setState(() => _isHovered = false);
      },
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: widget.isDark
                ? (_isHovered
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.06))
                : (_isHovered
                    ? Colors.black.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.04)),
            borderRadius: BorderRadius.circular(8),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              // 56x56 Album Thumbnail
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(8),
                ),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: widget.item.displayImage != null
                      ? CachedNetworkImage(
                          imageUrl: widget.item.displayImage!,
                          fit: BoxFit.cover,
                          memCacheWidth: 112,
                          errorWidget: (_, __, ___) => _tilePlaceholder(),
                          placeholder: (_, __) => _tilePlaceholder(),
                        )
                      : _tilePlaceholder(),
                ),
              ),

              const SizedBox(width: 10),

              // Title
              Expanded(
                child: Text(
                  widget.item.displayTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    color: widget.isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),

              // Play Icon Button
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: AnimatedScale(
                  scale: _isHovered ? 1.0 : 0.85,
                  duration: const Duration(milliseconds: 150),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.primaryGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryLight.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 20,
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

  Widget _tilePlaceholder() {
    return Container(
      color: widget.isDark ? const Color(0xFF252538) : const Color(0xFFE8E5F0),
      child: const Center(
        child: Icon(Icons.music_note_rounded, size: 20, color: Colors.white38),
      ),
    );
  }
}
