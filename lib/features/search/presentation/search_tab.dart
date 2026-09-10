import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rhythm_flutter/core/extensions/context_extensions.dart';
import 'package:rhythm_flutter/core/theme/app_colors.dart';
import 'package:rhythm_flutter/core/theme/spacing.dart';
import 'package:rhythm_flutter/core/widgets/music_list_tile.dart';
import 'package:rhythm_flutter/core/widgets/shimmer_loading.dart';
import 'package:rhythm_flutter/features/home/data/models/home_feed.dart';
import 'package:rhythm_flutter/features/home/presentation/widgets/home_item_card.dart';
import 'package:rhythm_flutter/features/home/providers/favorites_provider.dart';
import 'package:rhythm_flutter/features/player/providers/audio_provider.dart';
import 'package:rhythm_flutter/features/playlist/presentation/widgets/add_to_playlist_sheet.dart';
import 'package:rhythm_flutter/features/search/data/models/search_result.dart';
import 'package:rhythm_flutter/features/search/providers/search_provider.dart';

class SearchTab extends ConsumerStatefulWidget {
  const SearchTab({super.key});

  @override
  ConsumerState<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends ConsumerState<SearchTab> {
  final _searchController = TextEditingController();

  static const List<Map<String, dynamic>> _categories = [
    {
      'title': 'Top Hits',
      'colors': [Color(0xFFE02875), Color(0xFFFA8E5B)],
      'icon': Icons.trending_up_rounded,
    },
    {
      'title': 'Malayalam',
      'colors': [Color(0xFF5B247A), Color(0xFF1BCEDF)],
      'icon': Icons.music_note_rounded,
    },
    {
      'title': 'Tamil Melodies',
      'colors': [Color(0xFFF857A6), Color(0xFFFF5858)],
      'icon': Icons.favorite_rounded,
    },
    {
      'title': 'Bollywood',
      'colors': [Color(0xFFFF512F), Color(0xFFDD2476)],
      'icon': Icons.star_rounded,
    },
    {
      'title': 'Chill & Lo-Fi',
      'colors': [Color(0xFF4A0E4E), Color(0xFF8E2DE2)],
      'icon': Icons.nightlight_round,
    },
    {
      'title': 'Dance & EDM',
      'colors': [Color(0xFF0072FF), Color(0xFF00C6FF)],
      'icon': Icons.electric_bolt_rounded,
    },
    {
      'title': 'Acoustic & Unplugged',
      'colors': [Color(0xFFF7971E), Color(0xFFFFD200)],
      'icon': Icons.album_rounded,
    },
    {
      'title': 'Classical & Instrumental',
      'colors': [Color(0xFF11998E), Color(0xFF38EF7D)],
      'icon': Icons.piano_rounded,
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _triggerSearch(String query) {
    _searchController.text = query;
    ref.read(searchQueryProvider.notifier).updateQuery(query);
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(searchQueryProvider);
    final searchResults = ref.watch(searchResultsProvider);
    final activeFilter = ref.watch(searchCategoryFilterProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 960;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Search Field ──
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: context.l10n.search,
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: isDark
                        ? AppColors.primaryDark
                        : AppColors.primaryLight,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF1C1C30)
                      : const Color(0xFFFFFFFF),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.06),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.06),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: isDark
                          ? AppColors.primaryDark
                          : AppColors.primaryLight,
                      width: 1.5,
                    ),
                  ),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            ref
                                .read(searchQueryProvider.notifier)
                                .updateQuery('');
                          },
                        )
                      : null,
                ),
                onChanged: (value) {
                  ref.read(searchQueryProvider.notifier).updateQuery(value);
                },
              ),
            ),
          ),

          // ── Category Filter Pills (Visible when searching) ──
          if (searchQuery.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: SearchCategoryFilter.values.map((filter) {
                    final isSelected = activeFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(filter.label),
                        selected: isSelected,
                        onSelected: (_) {
                          ref.read(searchCategoryFilterProvider.notifier).state =
                              filter;
                        },
                        labelStyle: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white70 : Colors.black87),
                        ),
                        backgroundColor: isDark
                            ? const Color(0xFF1E1B2E)
                            : const Color(0xFFF0EFF6),
                        selectedColor: isDark
                            ? AppColors.primaryDark
                            : AppColors.primaryLight,
                        checkmarkColor: Colors.white,
                        showCheckmark: false,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected
                                ? Colors.transparent
                                : (isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : Colors.black.withValues(alpha: 0.06)),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

          // ── Search Body ──
          Expanded(
            child: searchQuery.isEmpty
                ? _buildBrowseCategories(isDark, isDesktop)
                : searchResults.when(
                    loading: () => _buildLoadingShimmer(isDark),
                    error: (err, _) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              size: 48,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              err.toString(),
                              textAlign: TextAlign.center,
                              style: context.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () => ref.refresh(searchResultsProvider),
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    data: (searchData) {
                      if (searchData.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.search_off_rounded,
                                  size: 64,
                                  color: isDark ? Colors.white30 : Colors.black26,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No results found for "$searchQuery"',
                                  textAlign: TextAlign.center,
                                  style: context.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.textPrimaryLight,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Try searching for another artist, song, album, or genre.',
                                  textAlign: TextAlign.center,
                                  style: context.textTheme.bodyMedium?.copyWith(
                                    color: isDark
                                        ? Colors.white54
                                        : AppColors.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return _buildSearchResultsContent(
                        searchData: searchData,
                        activeFilter: activeFilter,
                        isDark: isDark,
                        isDesktop: isDesktop,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// Builds search results based on the active category filter
  Widget _buildSearchResultsContent({
    required SearchResult searchData,
    required SearchCategoryFilter activeFilter,
    required bool isDark,
    required bool isDesktop,
  }) {
    final bottomPadding = isDesktop
        ? 24.0
        : (AppSpacing.xxl + AppSpacing.miniPlayerHeight);

    switch (activeFilter) {
      case SearchCategoryFilter.songs:
        // Use dedicated song-only search API (GET /api/v1/search/songs?query=...&limit=50)
        final songsOnlyAsync = ref.watch(songsSearchResultsProvider);
        return songsOnlyAsync.when(
          loading: () => _buildLoadingShimmer(isDark),
          error: (err, _) => _buildSongsList(searchData.songs, bottomPadding, isDark),
          data: (songsOnly) {
            final listToDisplay = songsOnly.isNotEmpty ? songsOnly : searchData.songs;
            return _buildSongsList(listToDisplay, bottomPadding, isDark);
          },
        );

      case SearchCategoryFilter.albums:
        return _buildAlbumsGrid(searchData.albums, bottomPadding, isDark, isDesktop);

      case SearchCategoryFilter.artists:
        return _buildArtistsGrid(searchData.artists, bottomPadding, isDark, isDesktop);

      case SearchCategoryFilter.playlists:
        return _buildPlaylistsGrid(searchData.playlists, bottomPadding, isDark, isDesktop);

      case SearchCategoryFilter.all:
        return _buildAllResults(searchData, bottomPadding, isDark, isDesktop);
    }
  }

  /// Builds "All" tab combining Top Result, Songs, Albums, Artists, and Playlists
  Widget _buildAllResults(
    SearchResult searchData,
    double bottomPadding,
    bool isDark,
    bool isDesktop,
  ) {
    final handler = ref.read(audioHandlerProvider);

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        bottomPadding,
      ),
      children: [
        // ── Top Result ──
        if (searchData.topQuery.isNotEmpty) ...[
          _buildSectionHeader('Top Result', isDark),
          const SizedBox(height: 8),
          _TopResultCard(
            item: searchData.topQuery.first,
            isDark: isDark,
            onTap: () => _handleItemTap(searchData.topQuery.first, searchData),
          ),
          const SizedBox(height: 20),
        ],

        // ── Songs ── (Has "See all" -> triggers dedicated songs search API)
        if (searchData.songs.isNotEmpty) ...[
          _buildSectionHeader(
            'Songs',
            isDark,
            onViewAll: () {
              ref.read(searchCategoryFilterProvider.notifier).state =
                  SearchCategoryFilter.songs;
            },
          ),
          const SizedBox(height: 6),
          ...searchData.songs.take(5).map((song) {
            final numericId = song.numericId;
            return MusicListTile(
              title: song.displayTitle,
              subtitle: song.displaySubtitle,
              imageUrl: song.displayImage,
              isFavorite: ref.watch(favoritesProvider).contains(numericId),
              onFavoriteToggle: () async {
                await ref
                    .read(favoritesProvider.notifier)
                    .toggleFavorite(song.id);
                final currentMedia =
                    ref.read(audioHandlerProvider).mediaItem.value;
                if (currentMedia?.id == song.id ||
                    currentMedia?.id == numericId.toString()) {
                  final isLiked =
                      ref.read(favoritesProvider).contains(numericId);
                  ref
                      .read(audioHandlerProvider)
                      .updateMediaItemFavorite(currentMedia!.id, isLiked);
                }
              },
              trailing: song.language != null && song.language!.isNotEmpty
                  ? song.language!.toUpperCase()
                  : null,
              onAddToPlaylist: () {
                AddToPlaylistSheet.show(
                  context,
                  songId: song.id,
                  songTitle: song.displayTitle,
                  songSubtitle: song.displaySubtitle,
                  imageUrl: song.displayImage,
                );
              },
              onTap: () {
                final songItems = searchData.songs;
                final songIndex = songItems.indexOf(song);
                final mediaItems =
                    songItems.map((s) => homeItemToMediaItem(s)).toList();
                handler.loadPlaylist(
                  mediaItems,
                  initialIndex: songIndex >= 0 ? songIndex : 0,
                );
              },
            );
          }),
          const SizedBox(height: 20),
        ],

        // ── Albums Carousel ── (No "See all")
        if (searchData.albums.isNotEmpty) ...[
          _buildSectionHeader(
            'Albums',
            isDark,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 215,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: searchData.albums.length,
              itemBuilder: (context, index) {
                final album = searchData.albums[index];
                return Padding(
                  padding: EdgeInsets.only(
                    right: index != searchData.albums.length - 1 ? 14 : 0,
                  ),
                  child: HomeItemCard(
                    item: album,
                    onTap: () => context.push('/album/${album.id}'),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],

        // ── Artists Carousel ── (No "See all")
        if (searchData.artists.isNotEmpty) ...[
          _buildSectionHeader(
            'Artists',
            isDark,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 195,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: searchData.artists.length,
              itemBuilder: (context, index) {
                final artist = searchData.artists[index];
                return Padding(
                  padding: EdgeInsets.only(
                    right: index != searchData.artists.length - 1 ? 16 : 0,
                  ),
                  child: HomeItemCard(
                    item: artist,
                    onTap: () => _triggerSearch(artist.name),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],

        // ── Playlists Carousel ── (No "See all")
        if (searchData.playlists.isNotEmpty) ...[
          _buildSectionHeader(
            'Playlists',
            isDark,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 215,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: searchData.playlists.length,
              itemBuilder: (context, index) {
                final playlist = searchData.playlists[index];
                return Padding(
                  padding: EdgeInsets.only(
                    right: index != searchData.playlists.length - 1 ? 14 : 0,
                  ),
                  child: HomeItemCard(
                    item: playlist,
                    onTap: () => _handleItemTap(playlist, searchData),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  /// Builds dedicated vertical songs list
  Widget _buildSongsList(
    List<HomeItem> songs,
    double bottomPadding,
    bool isDark,
  ) {
    if (songs.isEmpty) {
      return _buildEmptyCategoryState('No songs found', isDark);
    }

    final handler = ref.read(audioHandlerProvider);

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.sm,
        bottomPadding,
      ),
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        final numericId = song.numericId;

        return MusicListTile(
          title: song.displayTitle,
          subtitle: song.displaySubtitle,
          imageUrl: song.displayImage,
          isFavorite: ref.watch(favoritesProvider).contains(numericId),
          onFavoriteToggle: () async {
            await ref
                .read(favoritesProvider.notifier)
                .toggleFavorite(song.id);
            final currentMedia =
                ref.read(audioHandlerProvider).mediaItem.value;
            if (currentMedia?.id == song.id ||
                currentMedia?.id == numericId.toString()) {
              final isLiked =
                  ref.read(favoritesProvider).contains(numericId);
              ref
                  .read(audioHandlerProvider)
                  .updateMediaItemFavorite(currentMedia!.id, isLiked);
            }
          },
          trailing: song.language != null && song.language!.isNotEmpty
              ? song.language!.toUpperCase()
              : null,
          onAddToPlaylist: () {
            AddToPlaylistSheet.show(
              context,
              songId: song.id,
              songTitle: song.displayTitle,
              songSubtitle: song.displaySubtitle,
              imageUrl: song.displayImage,
            );
          },
          onTap: () {
            final mediaItems =
                songs.map((s) => homeItemToMediaItem(s)).toList();
            handler.loadPlaylist(
              mediaItems,
              initialIndex: index,
            );
          },
        );
      },
    );
  }

  /// Builds dedicated albums grid
  Widget _buildAlbumsGrid(
    List<HomeItem> albums,
    double bottomPadding,
    bool isDark,
    bool isDesktop,
  ) {
    if (albums.isEmpty) {
      return _buildEmptyCategoryState('No albums found', isDark);
    }

    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        bottomPadding,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 5 : 2,
        mainAxisExtent: 220,
        crossAxisSpacing: 14,
        mainAxisSpacing: 16,
      ),
      itemCount: albums.length,
      itemBuilder: (context, index) {
        final album = albums[index];
        return HomeItemCard(
          item: album,
          onTap: () => context.push('/album/${album.id}'),
        );
      },
    );
  }

  /// Builds dedicated artists grid
  Widget _buildArtistsGrid(
    List<HomeItem> artists,
    double bottomPadding,
    bool isDark,
    bool isDesktop,
  ) {
    if (artists.isEmpty) {
      return _buildEmptyCategoryState('No artists found', isDark);
    }

    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        bottomPadding,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 6 : 3,
        mainAxisExtent: 180,
        crossAxisSpacing: 14,
        mainAxisSpacing: 16,
      ),
      itemCount: artists.length,
      itemBuilder: (context, index) {
        final artist = artists[index];
        return HomeItemCard(
          item: artist,
          onTap: () => context.push('/artist/${artist.id}'),
        );
      },
    );
  }

  /// Builds dedicated playlists grid
  Widget _buildPlaylistsGrid(
    List<HomeItem> playlists,
    double bottomPadding,
    bool isDark,
    bool isDesktop,
  ) {
    if (playlists.isEmpty) {
      return _buildEmptyCategoryState('No playlists found', isDark);
    }

    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        bottomPadding,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 5 : 2,
        mainAxisExtent: 220,
        crossAxisSpacing: 14,
        mainAxisSpacing: 16,
      ),
      itemCount: playlists.length,
      itemBuilder: (context, index) {
        final playlist = playlists[index];
        return HomeItemCard(
          item: playlist,
          onTap: () => context.push('/playlist/${playlist.id}'),
        );
      },
    );
  }

  Widget _buildSectionHeader(
    String title,
    bool isDark, {
    VoidCallback? onViewAll,
  }) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: isDark ? Colors.white : AppColors.textPrimaryLight,
            ),
          ),
        ),
        if (onViewAll != null)
          InkWell(
            onTap: onViewAll,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'See all',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.primaryDark
                          : AppColors.primaryLight,
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
    );
  }

  void _handleItemTap(HomeItem item, SearchResult searchData) {
    if (item.isSong) {
      final handler = ref.read(audioHandlerProvider);
      final songItems = searchData.songs.isNotEmpty ? searchData.songs : [item];
      final songIndex = songItems.indexOf(item);
      final mediaItems = songItems.map((s) => homeItemToMediaItem(s)).toList();
      handler.loadPlaylist(
        mediaItems,
        initialIndex: songIndex >= 0 ? songIndex : 0,
      );
    } else if (item.isAlbum) {
      context.push('/album/${item.id}');
    } else if (item.isArtist) {
      context.push('/artist/${item.id}');
    } else if (item.isPlaylist) {
      context.push('/playlist/${item.id}');
    }
  }

  Widget _buildEmptyCategoryState(String message, bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.music_off_rounded,
            size: 48,
            color: isDark ? Colors.white24 : Colors.black26,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingShimmer(bool isDark) {
    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      children: [
        // Top result shimmer
        Container(
          height: 100,
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1B2E) : const Color(0xFFF3F0FC),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        ShimmerLoading.listTile(),
        ShimmerLoading.listTile(),
        ShimmerLoading.listTile(),
        ShimmerLoading.listTile(),
      ],
    );
  }

  /// Browse categories shown when search field is empty
  Widget _buildBrowseCategories(bool isDark, bool isDesktop) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        isDesktop ? 24 : (AppSpacing.xxl + AppSpacing.miniPlayerHeight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Browse Categories',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.textPrimaryLight,
              ),
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _categories.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isDesktop ? 4 : 2,
              mainAxisExtent: 96,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (context, index) {
              final cat = _categories[index];
              return _CategoryCard(
                title: cat['title'] as String,
                colors: cat['colors'] as List<Color>,
                icon: cat['icon'] as IconData,
                onTap: () => _triggerSearch(cat['title'] as String),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Highlighted Top Result Card
class _TopResultCard extends StatelessWidget {
  final HomeItem item;
  final bool isDark;
  final VoidCallback onTap;

  const _TopResultCard({
    required this.item,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isArtist = item.isArtist;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1B192A) : const Color(0xFFF7F5FC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // ── Artwork ──
            ClipRRect(
              borderRadius: BorderRadius.circular(isArtist ? 40 : 12),
              child: SizedBox(
                width: 76,
                height: 76,
                child: item.displayImage != null
                    ? CachedNetworkImage(
                        imageUrl: item.displayImage!,
                        fit: BoxFit.cover,
                        memCacheWidth: 152,
                        placeholder: (_, __) => _placeholder(),
                        errorWidget: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
            ),
            const SizedBox(width: 14),

            // ── Info ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Type badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: (isDark
                              ? AppColors.primaryDark
                              : AppColors.primaryLight)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.type.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: isDark
                            ? AppColors.primaryDark
                            : AppColors.primaryLight,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Title
                  Text(
                    item.displayTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 2),

                  // Subtitle
                  Text(
                    item.displaySubtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: (isDark ? Colors.white : Colors.black)
                          .withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),

            // ── Play / Action Icon ──
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryDark.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                item.isSong
                    ? Icons.play_arrow_rounded
                    : Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: Colors.grey.withValues(alpha: 0.2),
      child: const Icon(Icons.music_note_rounded, color: Colors.grey),
    );
  }
}

class _CategoryCard extends StatefulWidget {
  final String title;
  final List<Color> colors;
  final IconData icon;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.title,
    required this.colors,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
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
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: widget.colors.first
                    .withValues(alpha: _isHovered ? 0.45 : 0.25),
                blurRadius: _isHovered ? 14 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
              ),
              Positioned(
                bottom: -4,
                right: -4,
                child: Transform.rotate(
                  angle: 0.2,
                  child: Icon(
                    widget.icon,
                    size: 42,
                    color: Colors.white.withValues(alpha: 0.3),
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
