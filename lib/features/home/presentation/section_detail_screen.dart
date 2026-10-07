import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rhythm_flutter/core/animations/app_animations.dart';
import 'package:rhythm_flutter/core/theme/spacing.dart';
import 'package:rhythm_flutter/core/theme/scroll_physics.dart';
import 'package:rhythm_flutter/core/widgets/shimmer_loading.dart';
import 'package:rhythm_flutter/features/home/data/models/home_feed.dart';
import 'package:rhythm_flutter/features/home/presentation/widgets/home_item_card.dart';
import 'package:rhythm_flutter/features/home/providers/favorites_provider.dart';
import 'package:rhythm_flutter/features/home/providers/home_provider.dart';
import 'package:rhythm_flutter/features/player/providers/audio_provider.dart';

/// Modern, responsive Section View-All Screen for home feed sections (e.g. Trending Songs 50-list).
/// Supports Grid & List layouts, instant Play All / Shuffle, live in-section search,
/// and responsive desktop/mobile optimization.
class SectionDetailScreen extends ConsumerStatefulWidget {
  final String slug;
  final String title;

  const SectionDetailScreen({
    super.key,
    required this.slug,
    required this.title,
  });

  @override
  ConsumerState<SectionDetailScreen> createState() => _SectionDetailScreenState();
}

class _SectionDetailScreenState extends ConsumerState<SectionDetailScreen> {
  bool _isGridView = true;
  String _searchFilter = '';
  final _searchController = TextEditingController();
  bool _showSearchBar = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _playAll(List<HomeItem> items, {bool shuffle = false, int initialIndex = 0}) {
    if (items.isEmpty) return;
    HapticFeedback.mediumImpact();

    final handler = ref.read(audioHandlerProvider);
    final songItems = items.where((i) => i.isSong).toList();
    final targetList = songItems.isNotEmpty ? songItems : items;

    final playlistToLoad = List<HomeItem>.from(targetList);
    int startIndex = initialIndex;

    if (shuffle) {
      playlistToLoad.shuffle();
      startIndex = 0;
    }

    final mediaItems = playlistToLoad.map((i) => homeItemToMediaItem(i)).toList();
    handler.loadPlaylist(
      mediaItems,
      initialIndex: (startIndex >= 0 && startIndex < mediaItems.length) ? startIndex : 0,
      source: QueueSource.playlist,
    );
  }

  @override
  Widget build(BuildContext context) {
    final songsAsync = ref.watch(sectionSongsProvider(widget.slug));
    final currentMediaItem = ref.watch(currentMediaItemProvider).valueOrNull;
    final playbackState = ref.watch(playbackStateProvider).valueOrNull;
    final isPlaying = playbackState?.playing ?? false;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive thresholds
    final bool isDesktop = screenWidth >= 960;
    final bool isTablet = screenWidth >= 600 && screenWidth < 960;
    final int crossAxisCount = isDesktop ? 5 : (isTablet ? 3 : 2);
    final double horizontalPadding = isDesktop ? AppSpacing.xl * 2 : AppSpacing.md;

    final displayTitle = widget.title.isNotEmpty
        ? widget.title
        : widget.slug.replaceAll('_', ' ').toUpperCase();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0C0B14) : const Color(0xFFF6F5FA),
      body: songsAsync.when(
        loading: () => _buildShimmer(context, isDark, horizontalPadding, crossAxisCount),
        error: (err, stack) => _buildErrorState(context, err, isDark),
        data: (rawItems) {
          // Filter items based on in-page search
          final items = _searchFilter.trim().isEmpty
              ? rawItems
              : rawItems.where((item) {
                  final q = _searchFilter.toLowerCase();
                  return item.displayTitle.toLowerCase().contains(q) ||
                      item.displaySubtitle.toLowerCase().contains(q) ||
                      (item.language?.toLowerCase().contains(q) ?? false);
                }).toList();

          final bool hasSongs = items.any((i) => i.isSong);

          return CustomScrollView(
            physics: AppScrollPhysics.adaptive,
            slivers: [
              // ── Modern Sliver App Bar with Ambient Header ──
              SliverAppBar(
                expandedHeight: isDesktop ? 220 : 170,
                pinned: true,
                elevation: 0,
                scrolledUnderElevation: 3,
                backgroundColor: (isDark ? const Color(0xFF100E1C) : Colors.white)
                    .withValues(alpha: isDark ? 0.92 : 0.96),
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
                  ),
                  onPressed: () => context.pop(),
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      _showSearchBar ? Icons.close_rounded : Icons.search_rounded,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    onPressed: () {
                      setState(() {
                        _showSearchBar = !_showSearchBar;
                        if (!_showSearchBar) {
                          _searchFilter = '';
                          _searchController.clear();
                        }
                      });
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    onPressed: () {
                      setState(() => _isGridView = !_isGridView);
                    },
                  ),
                  const SizedBox(width: 8),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Ambient gradient background
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              (isDark ? const Color(0xFF6C5CE7) : const Color(0xFFA29BFE))
                                  .withValues(alpha: isDark ? 0.35 : 0.45),
                              (isDark ? const Color(0xFF2D1457) : const Color(0xFFE9E4FA))
                                  .withValues(alpha: isDark ? 0.2 : 0.4),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      // Title & Count Info
                      Positioned(
                        bottom: 16,
                        left: horizontalPadding,
                        right: horizontalPadding,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6C5CE7).withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(0xFF6C5CE7).withValues(alpha: 0.4),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Text(
                                    '${rawItems.length} ITEMS',
                                    style: const TextStyle(
                                      color: Color(0xFF9D84FF),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              displayTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: isDesktop ? 28 : 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── In-Page Search Bar (When Toggled) ──
              if (_showSearchBar)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      AppSpacing.sm,
                      horizontalPadding,
                      AppSpacing.sm,
                    ),
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Filter in this section...',
                          hintStyle: TextStyle(
                            color: isDark ? Colors.white38 : Colors.black38,
                            fontSize: 13,
                          ),
                          prefixIcon: const Icon(Icons.search_rounded, size: 18),
                          suffixIcon: _searchFilter.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 16),
                                  onPressed: () {
                                    setState(() {
                                      _searchFilter = '';
                                      _searchController.clear();
                                    });
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onChanged: (val) {
                          setState(() => _searchFilter = val);
                        },
                      ),
                    ),
                  ),
                ),

              // ── Action Bar (Play All / Shuffle / Info) ──
              if (hasSongs && items.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: AppSpacing.md,
                    ),
                    child: Row(
                      children: [
                        // Play All Button
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _playAll(items, shuffle: false),
                            icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                            label: const Text(
                              'Play All',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6C5CE7),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 4,
                              shadowColor: const Color(0xFF6C5CE7).withValues(alpha: 0.4),
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Shuffle Button
                        Container(
                          decoration: BoxDecoration(
                            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                            ),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.shuffle_rounded),
                            color: isDark ? Colors.white : Colors.black87,
                            tooltip: 'Shuffle Play',
                            onPressed: () => _playAll(items, shuffle: true),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // ── Empty Results State ──
              if (items.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.music_off_rounded,
                            size: 48,
                            color: isDark ? Colors.white24 : Colors.black26,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _searchFilter.isNotEmpty
                                ? 'No songs matching "$_searchFilter"'
                                : 'No items found in this section',
                            style: TextStyle(
                              color: isDark ? Colors.white54 : Colors.black54,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // ── Responsive Content: Grid Mode ──
              if (items.isNotEmpty && _isGridView)
                SliverPadding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: AppSpacing.sm,
                  ),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: isDesktop ? AppSpacing.lg : AppSpacing.md,
                      crossAxisSpacing: isDesktop ? AppSpacing.lg : AppSpacing.md,
                      childAspectRatio: isDesktop ? 0.8 : 0.72,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = items[index];

                        return FadeScaleIn(
                          delay: AppAnimations.stagger(index, baseMs: 25),
                          child: HomeItemCard(
                            item: item,
                            onTap: () {
                              if (item.isSong) {
                                _playAll(items, initialIndex: index);
                              } else if (item.isAlbum) {
                                context.push('/album/${item.id}');
                              } else if (item.isPlaylist) {
                                context.push('/playlist/${item.id}');
                              } else if (item.isArtist) {
                                context.push('/artist/${item.id}');
                              }
                            },
                          ),
                        );
                      },
                      childCount: items.length,
                    ),
                  ),
                ),

              // ── Responsive Content: List Mode ──
              if (items.isNotEmpty && !_isGridView)
                SliverPadding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: AppSpacing.sm,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = items[index];
                        final isThisPlaying = currentMediaItem?.id == item.id && isPlaying;

                        return FadeScaleIn(
                          delay: AppAnimations.stagger(index, baseMs: 20),
                          child: _SectionSongListTile(
                            index: index + 1,
                            item: item,
                            isPlaying: isThisPlaying,
                            isDark: isDark,
                            onTap: () {
                              if (item.isSong) {
                                _playAll(items, initialIndex: index);
                              } else if (item.isAlbum) {
                                context.push('/album/${item.id}');
                              } else if (item.isPlaylist) {
                                context.push('/playlist/${item.id}');
                              } else if (item.isArtist) {
                                context.push('/artist/${item.id}');
                              }
                            },
                          ),
                        );
                      },
                      childCount: items.length,
                    ),
                  ),
                ),

              // ── Bottom Spacing for Floating Mini Player ──
              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.miniPlayerHeight + AppSpacing.xxl),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildShimmer(BuildContext context, bool isDark, double horizontalPadding, int crossAxisCount) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 180,
          pinned: true,
          backgroundColor: isDark ? const Color(0xFF100E1C) : Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => context.pop(),
          ),
          flexibleSpace: const FlexibleSpaceBar(
            title: ShimmerBox(width: 140, height: 20, borderRadius: AppSpacing.radiusSm),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: AppSpacing.lg),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              childAspectRatio: 0.75,
            ),
            delegate: SliverChildBuilderDelegate(
              (_, __) => ShimmerLoading.musicCard(),
              childCount: 10,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, Object error, bool isDark) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 52,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load songs',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  ref.invalidate(sectionSongsProvider(widget.slug));
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C5CE7),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 🎵 SECTION SONG LIST TILE (SPOTIFY/APPLE STYLE)
// ─────────────────────────────────────────────────────────────────────────────

class _SectionSongListTile extends ConsumerWidget {
  final int index;
  final HomeItem item;
  final bool isPlaying;
  final bool isDark;
  final VoidCallback onTap;

  const _SectionSongListTile({
    required this.index,
    required this.item,
    required this.isPlaying,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final numericFavId = int.tryParse(item.id) ?? item.id.hashCode.abs();
    final isFav = ref.watch(favoritesProvider).contains(numericFavId);
    final handler = ref.read(audioHandlerProvider);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isPlaying
                  ? const Color(0xFF6C5CE7).withValues(alpha: isDark ? 0.18 : 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isPlaying
                  ? Border.all(
                      color: const Color(0xFF6C5CE7).withValues(alpha: 0.35),
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              children: [
                // Index number or Playing Indicator
                SizedBox(
                  width: 28,
                  child: isPlaying
                      ? const Icon(
                          Icons.equalizer_rounded,
                          color: Color(0xFF6C5CE7),
                          size: 18,
                        )
                      : Text(
                          '$index',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                ),

                const SizedBox(width: 6),

                // Artwork Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 46,
                    height: 46,
                    child: item.displayImage != null
                        ? CachedNetworkImage(
                            imageUrl: item.displayImage!,
                            fit: BoxFit.cover,
                            memCacheWidth: 92,
                            placeholder: (_, __) => Container(
                              color: isDark ? const Color(0xFF1E1C2E) : const Color(0xFFE5E2F0),
                              child: const Icon(Icons.music_note_rounded, size: 20, color: Colors.white38),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: isDark ? const Color(0xFF1E1C2E) : const Color(0xFFE5E2F0),
                              child: const Icon(Icons.music_note_rounded, size: 20, color: Colors.white38),
                            ),
                          )
                        : Container(
                            color: isDark ? const Color(0xFF1E1C2E) : const Color(0xFFE5E2F0),
                            child: const Icon(Icons.music_note_rounded, size: 20, color: Colors.white38),
                          ),
                  ),
                ),

                const SizedBox(width: 12),

                // Song Title & Language / Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.displayTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isPlaying
                              ? const Color(0xFF9D84FF)
                              : (isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          if (item.language != null && item.language!.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item.language!.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white60 : Colors.black54,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Expanded(
                            child: Text(
                              item.displaySubtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white54 : Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Trailing Action (Favorite for song, Chevron for playlist/album/artist)
                if (item.isSong)
                  IconButton(
                    icon: Icon(
                      isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: isFav
                          ? const Color(0xFFFF4B6E)
                          : (isDark ? Colors.white30 : Colors.black26),
                      size: 20,
                    ),
                    onPressed: () async {
                      HapticFeedback.selectionClick();
                      await ref.read(favoritesProvider.notifier).toggleFavorite(item.id);
                      final isLiked = ref.read(favoritesProvider).contains(numericFavId);
                      handler.updateMediaItemFavorite(item.id, isLiked);
                    },
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: isDark ? Colors.white30 : Colors.black26,
                      size: 14,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}