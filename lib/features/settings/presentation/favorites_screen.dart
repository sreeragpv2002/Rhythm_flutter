import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rhythm_flutter/core/animations/app_animations.dart';
import 'package:rhythm_flutter/core/theme/app_colors.dart';
import 'package:rhythm_flutter/core/theme/spacing.dart';
import 'package:rhythm_flutter/features/home/data/models/home_feed.dart';
import 'package:rhythm_flutter/features/home/data/models/music.dart';
import 'package:rhythm_flutter/features/home/providers/favorites_provider.dart';
import 'package:rhythm_flutter/features/home/providers/home_provider.dart';
import 'package:rhythm_flutter/features/player/providers/audio_provider.dart';

/// Comprehensive, modern Favorite Songs screen in Settings.
/// Allows searching, listening, shuffling, and toggling favorite tracks in real time.
class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final favoritesSet = ref.watch(favoritesProvider);
    final favListAsync = ref.watch(favoritesListProvider);
    final homeAsync = ref.watch(homeProvider);
    final mediaItemAsync = ref.watch(currentMediaItemProvider);
    final playbackAsync = ref.watch(playbackStateProvider);
    final handler = ref.read(audioHandlerProvider);

    final currentMedia = mediaItemAsync.valueOrNull;
    final isPlaying = playbackAsync.valueOrNull?.playing ?? false;

    // Aggregate songs from backend favorites list and home feed fallback
    final apiFavSongs = favListAsync.valueOrNull ?? [];
    final feed = homeAsync.valueOrNull;
    final Map<int, HomeItem> songMap = {};

    for (final item in apiFavSongs) {
      songMap[item.numericId] = item;
    }

    for (final id in favoritesSet) {
      if (!songMap.containsKey(id)) {
        final dynamic fallbackObj = feed?.getMusicById(id);
        if (fallbackObj is Music) {
          songMap[id] = HomeItem(
            id: fallbackObj.rawStringId,
            name: fallbackObj.titles['en'] ?? fallbackObj.titles.values.firstOrNull ?? 'Song',
            title: fallbackObj.titles['en'] ?? fallbackObj.titles.values.firstOrNull ?? 'Song',
            image: fallbackObj.thumbUrl,
            imageUrl: fallbackObj.thumbUrl,
            type: 'song',
            subtitle: fallbackObj.artistNames.map((a) => a['en'] ?? a.values.firstOrNull ?? '').join(', '),
            language: fallbackObj.language,
          );
        } else if (fallbackObj is HomeItem) {
          songMap[id] = fallbackObj;
        }
      }
    }

    // Filter by active favorited items
    final activeFavorites = favoritesSet
        .map((id) => songMap[id])
        .whereType<HomeItem>()
        .toList();

    // Filter by search query
    final filteredSongs = _searchQuery.isEmpty
        ? activeFavorites
        : activeFavorites.where((s) {
            final query = _searchQuery.toLowerCase();
            final title = s.displayTitle.toLowerCase();
            final subtitle = s.displaySubtitle.toLowerCase();
            return title.contains(query) || subtitle.contains(query);
          }).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D0D14) : const Color(0xFFF7F8FC),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(favoritesListProvider);
          await ref.read(favoritesListProvider.future);
        },
        color: AppColors.primaryLight,
        backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            // ── Modern Glassmorphic App Bar ──
            SliverAppBar(
              pinned: true,
              expandedHeight: 180,
              backgroundColor: (isDark ? const Color(0xFF0D0D14) : const Color(0xFFF7F8FC))
                  .withValues(alpha: 0.92),
              elevation: 0,
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 16,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
              flexibleSpace: FlexibleSpaceBar(
                expandedTitleScale: 1.0,
                background: Stack(
                  children: [
                    // Subtle glowing gradient backdrop
                    Positioned(
                      top: -60,
                      right: -30,
                      child: Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFF4B6E).withValues(alpha: isDark ? 0.18 : 0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 40,
                      left: -50,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF6C5CE7).withValues(alpha: isDark ? 0.15 : 0.08),
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFF4B6E), Color(0xFF6C5CE7)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF4B6E).withValues(alpha: 0.4),
                                    blurRadius: 18,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.favorite_rounded,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Favorite Songs',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? Colors.white : const Color(0xFF1E1E2E),
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${activeFavorites.length} ${activeFavorites.length == 1 ? "track" : "tracks"} saved',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: (isDark ? Colors.white : Colors.black)
                                          .withValues(alpha: 0.55),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Search Bar & Action Buttons (Play All / Shuffle) ──
            if (activeFavorites.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    children: [
                      // Search field
                      Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E1E2E).withValues(alpha: 0.7)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (v) => setState(() => _searchQuery = v.trim()),
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search favorite songs...',
                            hintStyle: TextStyle(
                              color: isDark ? Colors.white38 : Colors.black38,
                              fontSize: 14,
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: isDark ? Colors.white38 : Colors.black38,
                              size: 20,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Action Buttons: Play All & Shuffle
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                if (filteredSongs.isEmpty) return;
                                HapticFeedback.mediumImpact();
                                final mediaItems = filteredSongs
                                    .map((s) => homeItemToMediaItem(s))
                                    .toList();
                                handler.loadPlaylist(mediaItems, initialIndex: 0);
                              },
                              icon: const Icon(Icons.play_arrow_rounded, size: 22, color: Colors.white),
                              label: const Text(
                                'Play All',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6C5CE7),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 4,
                                shadowColor: const Color(0xFF6C5CE7).withValues(alpha: 0.4),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                if (filteredSongs.isEmpty) return;
                                HapticFeedback.mediumImpact();
                                final mediaItems = List<MediaItem>.from(
                                  filteredSongs.map((s) => homeItemToMediaItem(s)),
                                )..shuffle();
                                handler.loadPlaylist(mediaItems, initialIndex: 0);
                              },
                              icon: Icon(
                                Icons.shuffle_rounded,
                                size: 18,
                                color: isDark ? Colors.white : const Color(0xFF1E1E2E),
                              ),
                              label: Text(
                                'Shuffle',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: isDark ? Colors.white : const Color(0xFF1E1E2E),
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.15),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            // ── Favorites Track List or Empty State ──
            if (activeFavorites.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFF4B6E).withValues(alpha: isDark ? 0.12 : 0.08),
                        ),
                        child: const Icon(
                          Icons.favorite_border_rounded,
                          size: 64,
                          color: Color(0xFFFF4B6E),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No Favorite Songs Yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF1E1E2E),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap the heart icon on any song to save it here\nfor fast access anytime.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => context.go('/'),
                        icon: const Icon(Icons.explore_rounded, size: 18, color: Colors.white),
                        label: const Text('Explore Music', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryLight,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (filteredSongs.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 52,
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No matches for "$_searchQuery"',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = filteredSongs[index];
                      final isCurrent = currentMedia?.id == item.id ||
                          currentMedia?.id == item.numericId.toString();
                      final isCurrentPlaying = isCurrent && isPlaying;
                      final isLiked = favoritesSet.contains(item.numericId);

                      return SlideUpFadeIn(
                        delay: AppAnimations.stagger(index, baseMs: 30),
                        child: _FavoriteTrackTile(
                          index: index + 1,
                          item: item,
                          isCurrentSong: isCurrent,
                          isPlaying: isCurrentPlaying,
                          isLiked: isLiked,
                          isDark: isDark,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            final mediaItems = filteredSongs
                                .map((s) => homeItemToMediaItem(s))
                                .toList();
                            handler.loadPlaylist(mediaItems, initialIndex: index);
                          },
                          onLikeToggle: () async {
                            HapticFeedback.selectionClick();
                            await ref.read(favoritesProvider.notifier).toggleFavorite(item.id);
                            final updatedIsFav = ref.read(favoritesProvider).contains(item.numericId);
                            handler.updateMediaItemFavorite(item.id, updatedIsFav);
                          },
                        ),
                      );
                    },
                    childCount: filteredSongs.length,
                  ),
                ),
              ),

            // Bottom Spacing for MiniPlayer
            const SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.miniPlayerHeight + AppSpacing.xxl),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 🎵 FAVORITE TRACK TILE WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class _FavoriteTrackTile extends StatelessWidget {
  final int index;
  final HomeItem item;
  final bool isCurrentSong;
  final bool isPlaying;
  final bool isLiked;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onLikeToggle;

  const _FavoriteTrackTile({
    required this.index,
    required this.item,
    required this.isCurrentSong,
    required this.isPlaying,
    required this.isLiked,
    required this.isDark,
    required this.onTap,
    required this.onLikeToggle,
  });

  @override
  Widget build(BuildContext context) {
    final imageUri = item.displayImage;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: isCurrentSong
                  ? const Color(0xFF6C5CE7).withValues(alpha: isDark ? 0.2 : 0.1)
                  : (isDark
                      ? const Color(0xFF161626).withValues(alpha: 0.6)
                      : Colors.white),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isCurrentSong
                    ? const Color(0xFF6C5CE7).withValues(alpha: 0.4)
                    : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
              ),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Row(
              children: [
                // ── Thumbnail with Equalizer Overlay ──
                Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: imageUri != null && imageUri.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: imageUri,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              placeholder: (ctx, url) => Container(
                                width: 48,
                                height: 48,
                                color: isDark ? Colors.white10 : Colors.black12,
                                child: const Icon(Icons.music_note_rounded, size: 20),
                              ),
                              errorWidget: (ctx, url, err) => Container(
                                width: 48,
                                height: 48,
                                color: isDark ? Colors.white10 : Colors.black12,
                                child: const Icon(Icons.music_note_rounded, size: 20),
                              ),
                            )
                          : Container(
                              width: 48,
                              height: 48,
                              color: isDark ? Colors.white10 : Colors.black12,
                              child: const Icon(Icons.music_note_rounded, size: 20),
                            ),
                    ),
                    if (isCurrentSong)
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: isPlaying
                            ? const _AnimatedMiniEqualizer()
                            : const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                      ),
                  ],
                ),
                const SizedBox(width: 14),

                // ── Song Title & Artist Info ──
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
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: isCurrentSong
                              ? (isDark ? const Color(0xFFA29BFE) : const Color(0xFF6C5CE7))
                              : (isDark ? Colors.white : const Color(0xFF1E1E2E)),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          if (item.language != null && item.language!.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item.language!.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white70 : Colors.black54,
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
                                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Heart / Favorite Toggle Button ──
                IconButton(
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                    child: Icon(
                      isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      key: ValueKey(isLiked),
                      color: isLiked
                          ? const Color(0xFFFF4B6E)
                          : (isDark ? Colors.white30 : Colors.black26),
                      size: 22,
                    ),
                  ),
                  onPressed: onLikeToggle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 📊 MINI EQUALIZER ANIMATION FOR PLAYING STATE
// ─────────────────────────────────────────────────────────────────────────────

class _AnimatedMiniEqualizer extends StatefulWidget {
  const _AnimatedMiniEqualizer();

  @override
  State<_AnimatedMiniEqualizer> createState() => _AnimatedMiniEqualizerState();
}

class _AnimatedMiniEqualizerState extends State<_AnimatedMiniEqualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildBar(6 + 10 * t),
            const SizedBox(width: 2.5),
            _buildBar(16 - 10 * t),
            const SizedBox(width: 2.5),
            _buildBar(9 + 8 * (1 - t)),
          ],
        );
      },
    );
  }

  Widget _buildBar(double height) {
    return Container(
      width: 3,
      height: height.clamp(4.0, 18.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFF4B6E),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
