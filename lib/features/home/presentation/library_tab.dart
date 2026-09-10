import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rhythm_flutter/core/animations/app_animations.dart';
import 'package:rhythm_flutter/core/extensions/context_extensions.dart';
import 'package:rhythm_flutter/core/theme/app_colors.dart';
import 'package:rhythm_flutter/core/theme/spacing.dart';
import 'package:rhythm_flutter/core/widgets/music_list_tile.dart';
import 'package:rhythm_flutter/features/home/data/models/home_feed.dart';
import 'package:rhythm_flutter/features/home/data/models/music.dart';
import 'package:rhythm_flutter/features/home/providers/home_provider.dart';
import 'package:rhythm_flutter/features/home/providers/favorites_provider.dart';
import 'package:rhythm_flutter/features/player/providers/audio_provider.dart';
import 'package:rhythm_flutter/features/playlist/presentation/widgets/add_to_playlist_sheet.dart';
import 'package:rhythm_flutter/features/playlist/presentation/widgets/create_playlist_dialog.dart';
import 'package:rhythm_flutter/features/playlist/providers/user_playlist_provider.dart';

class LibraryTab extends ConsumerStatefulWidget {
  const LibraryTab({super.key});

  @override
  ConsumerState<LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends ConsumerState<LibraryTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? Colors.black : Colors.white,
        elevation: 0,
        title: Text(
          context.l10n.library,
          style: context.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Create Playlist',
            icon: const Icon(Icons.playlist_add_rounded, size: 26),
            onPressed: () => CreatePlaylistDialog.show(context),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: isDark ? AppColors.primaryDark : AppColors.primaryLight,
          unselectedLabelColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5),
          indicatorColor: isDark ? AppColors.primaryDark : AppColors.primaryLight,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Liked Songs'),
            Tab(text: 'Custom Playlists'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Liked Songs
          _buildFavoritesTab(context, ref, isDark),

          // Tab 2: Custom Playlists
          _buildPlaylistsTab(context, ref, isDark),
        ],
      ),
    );
  }

  Widget _buildFavoritesTab(BuildContext context, WidgetRef ref, bool isDark) {
    final favorites = ref.watch(favoritesProvider);
    final homeAsync = ref.watch(homeProvider);
    final locale = context.l10n.localeName;

    if (favorites.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite_border_rounded,
              size: 64,
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.2),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              context.l10n.noSongsFound,
              style: context.textTheme.bodyLarge?.copyWith(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      );
    }

    return ref.watch(favoritesListProvider).when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) {
        final feed = homeAsync.valueOrNull;
        final favoriteSongs = favorites
            .map((id) => feed?.getMusicById(id))
            .whereType<dynamic>()
            .toList();

        if (favoriteSongs.isEmpty) {
          return Center(child: Text('${context.l10n.error}: $err'));
        }
        return _buildFavoriteListView(context, ref, favoriteSongs, locale);
      },
      data: (apiFavSongs) {
        final feed = homeAsync.valueOrNull;
        final Map<int, dynamic> songMap = {};

        for (final item in apiFavSongs) {
          songMap[item.numericId] = item;
        }

        for (final id in favorites) {
          if (!songMap.containsKey(id)) {
            final song = feed?.getMusicById(id);
            if (song != null) {
              songMap[id] = song;
            }
          }
        }

        final favoriteSongs = favorites
            .map((id) => songMap[id])
            .whereType<dynamic>()
            .toList();

        if (favoriteSongs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.favorite_border_rounded,
                  size: 64,
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.2),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  context.l10n.noSongsFound,
                  style: context.textTheme.bodyLarge?.copyWith(
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          );
        }

        return _buildFavoriteListView(context, ref, favoriteSongs, locale);
      },
    );
  }

  Widget _buildFavoriteListView(
    BuildContext context,
    WidgetRef ref,
    List<dynamic> favoriteSongs,
    String locale,
  ) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.sm, AppSpacing.sm, 100),
      itemCount: favoriteSongs.length,
      itemBuilder: (context, index) {
        final song = favoriteSongs[index];
        final title = song is HomeItem ? song.displayTitle : song.getDisplayTitle(locale);
        final subtitle = song is HomeItem ? song.displaySubtitle : song.getDisplayArtists(locale);
        final thumbUrl = song is HomeItem ? song.displayImage : song.thumbUrl;
        final dynamic songId = song is HomeItem ? song.id : song.id;

        return SlideUpFadeIn(
          delay: AppAnimations.stagger(index, baseMs: 30),
          child: MusicListTile(
            title: title,
            subtitle: subtitle,
            imageUrl: thumbUrl,
            isFavorite: true,
            onFavoriteToggle: () {
              ref.read(favoritesProvider.notifier).toggleFavorite(songId);
            },
            onAddToPlaylist: () {
              AddToPlaylistSheet.show(
                context,
                songId: songId.toString(),
                songTitle: title,
                songSubtitle: subtitle,
                imageUrl: thumbUrl,
              );
            },
            onTap: () {
              final handler = ref.read(audioHandlerProvider);
              final mediaItems = favoriteSongs.map<MediaItem>((m) {
                if (m is Music) return musicToMediaItem(m, locale);
                if (m is HomeItem) return homeItemToMediaItem(m);
                return MediaItem(
                  id: m.id.toString(),
                  title: m.getDisplayTitle(locale),
                  artist: m.getDisplayArtists(locale),
                  artUri: m.thumbUrl != null ? Uri.parse(m.thumbUrl!) : null,
                );
              }).toList();
              handler.loadPlaylist(mediaItems, initialIndex: index);
            },
          ),
        );
      },
    );
  }

  Widget _buildPlaylistsTab(BuildContext context, WidgetRef ref, bool isDark) {
    final playlistsAsync = ref.watch(userPlaylistsProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(userPlaylistsProvider.notifier).refresh(),
      child: playlistsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text('Error: $err'),
        ),
        data: (playlists) {
          final customPlaylists = playlists.where((p) => !p.isFavorite).toList();

          if (customPlaylists.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.queue_music_rounded,
                      size: 64,
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.2),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No custom playlists yet',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create custom playlists to organize your favorite songs',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => CreatePlaylistDialog.show(context),
                      icon: const Icon(Icons.add_rounded, color: Colors.white),
                      label: const Text('Create Playlist', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C5CE7),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: customPlaylists.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
                    ),
                    title: const Text('Create New Playlist', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Add your favorite tracks into a new playlist'),
                    onTap: () => CreatePlaylistDialog.show(context),
                  ),
                );
              }

              final playlist = customPlaylists[index - 1];

              return SlideUpFadeIn(
                delay: AppAnimations.stagger(index, baseMs: 30),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    onTap: () => context.push('/user-playlist/${playlist.id}'),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C5CE7), Color(0xFFFF7675)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.queue_music_rounded, color: Colors.white, size: 24),
                    ),
                    title: Text(
                      playlist.displayTitle,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    subtitle: Text(
                      '${playlist.songCount} ${playlist.songCount == 1 ? "track" : "tracks"}',
                      style: TextStyle(
                        fontSize: 12,
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5),
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
