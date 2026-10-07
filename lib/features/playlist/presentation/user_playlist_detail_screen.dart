import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rhythm_flutter/core/animations/app_animations.dart';
import 'package:rhythm_flutter/core/theme/app_colors.dart';
import 'package:rhythm_flutter/core/theme/scroll_physics.dart';
import 'package:rhythm_flutter/features/home/data/models/home_feed.dart';
import 'package:rhythm_flutter/features/home/providers/favorites_provider.dart';
import 'package:rhythm_flutter/features/player/providers/audio_provider.dart';
import 'package:rhythm_flutter/features/playlist/data/models/user_playlist.dart';
import 'package:rhythm_flutter/features/playlist/providers/user_playlist_provider.dart';

/// Screen displaying tracks and metadata of a custom user playlist.
/// Supports playing all songs, shuffling, removing tracks, and deleting the playlist.
class UserPlaylistDetailScreen extends ConsumerWidget {
  final String playlistId;

  const UserPlaylistDetailScreen({
    super.key,
    required this.playlistId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistAsync = ref.watch(userPlaylistDetailsProvider(playlistId));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 860;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0B14) : const Color(0xFFF7F7FC),
      body: playlistAsync.when(
        loading: () => _UserPlaylistLoadingSkeleton(isDesktop: isDesktop),
        error: (err, stack) => _UserPlaylistErrorView(
          errorMessage: err.toString(),
          onRetry: () => ref.refresh(userPlaylistDetailsProvider(playlistId)),
        ),
        data: (playlist) {
          if (playlist == null) {
            return _UserPlaylistErrorView(
              errorMessage: 'Playlist not found or has been deleted.',
              onRetry: () => context.pop(),
            );
          }
          if (isDesktop) {
            return _DesktopUserPlaylistView(playlist: playlist);
          }
          return _MobileUserPlaylistView(playlist: playlist);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 📱 Mobile View
// ─────────────────────────────────────────────────────────────────────────────

class _MobileUserPlaylistView extends ConsumerWidget {
  final UserPlaylist playlist;

  const _MobileUserPlaylistView({required this.playlist});

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).brightness == Brightness.dark
            ? const Color(0xFF1B1B2C)
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 24),
            SizedBox(width: 10),
            Text('Delete Playlist', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${playlist.name}"? This action cannot be undone.',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await ref
          .read(userPlaylistsProvider.notifier)
          .deletePlaylist(playlist.id);

      if (context.mounted) {
        if (success) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Playlist "${playlist.name}" deleted.'),
              backgroundColor: const Color(0xFF6C5CE7),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete playlist. Please try again.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final handler = ref.read(audioHandlerProvider);
    final currentMedia = ref.watch(currentMediaItemProvider).value;
    final isPlaying = ref.watch(playbackStateProvider).value?.playing ?? false;
    final favorites = ref.watch(favoritesProvider);
    final songs = playlist.songs;

    return CustomScrollView(
      physics: AppScrollPhysics.adaptive,
      slivers: [
        // ── Sliver App Bar with Artwork & Info ──
        SliverAppBar(
          expandedHeight: 380,
          pinned: true,
          stretch: true,
          elevation: 0,
          backgroundColor: isDark
              ? const Color(0xFF0E0E1B).withValues(alpha: 0.95)
              : Colors.white.withValues(alpha: 0.95),
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: _CircleIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onPressed: () => context.pop(),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: _CircleIconButton(
                icon: Icons.delete_outline_rounded,
                iconColor: Colors.redAccent,
                onPressed: () => _confirmDelete(context, ref),
              ),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            stretchModes: const [
              StretchMode.zoomBackground,
              StretchMode.blurBackground,
            ],
            background: Stack(
              fit: StackFit.expand,
              children: [
                // Ambient Background
                _UserPlaylistHeaderGlow(playlist: playlist),

                // Glass Gradient Overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        (isDark ? const Color(0xFF0B0B14) : const Color(0xFFF7F7FC))
                            .withValues(alpha: 0.8),
                        isDark ? const Color(0xFF0B0B14) : const Color(0xFFF7F7FC),
                      ],
                      stops: const [0.0, 0.65, 1.0],
                    ),
                  ),
                ),

                // Center Content: Artwork + Title + Stats
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Artwork Squircle
                      _UserPlaylistArtwork(playlist: playlist, size: 140),
                      const SizedBox(height: 14),

                      // Playlist Title
                      Text(
                        playlist.displayTitle,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                          color: isDark ? Colors.white : const Color(0xFF1E1E2E),
                        ),
                      ),

                      if (playlist.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          playlist.description,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
                          ),
                        ),
                      ],

                      const SizedBox(height: 6),
                      Text(
                        '${songs.length} ${songs.length == 1 ? "track" : "tracks"} • Custom Playlist',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Action Buttons Bar (Play All / Shuffle / Search) ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                // Play All Button
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    onPressed: songs.isEmpty
                        ? null
                        : () {
                            HapticFeedback.lightImpact();
                            final mediaItems = playlist.toMediaItems();
                            handler.loadPlaylist(
                              mediaItems,
                              initialIndex: 0,
                              source: QueueSource.playlist,
                            );
                          },
                    icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                    label: const Text(
                      'Play All',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C5CE7),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                      shadowColor: const Color(0xFF6C5CE7).withValues(alpha: 0.4),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Shuffle Button
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    onPressed: songs.isEmpty
                        ? null
                        : () {
                            HapticFeedback.lightImpact();
                            final mediaItems = playlist.toMediaItems();
                            handler.loadPlaylist(
                              mediaItems,
                              initialIndex: 0,
                              source: QueueSource.playlist,
                            );
                            handler.setShuffleEnabled(true);
                          },
                    icon: Icon(
                      Icons.shuffle_rounded,
                      size: 20,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    label: Text(
                      'Shuffle',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.15),
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Add Songs Shortcut
                IconButton(
                  tooltip: 'Search to Add Songs',
                  onPressed: () => context.go('/search'),
                  icon: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                      ),
                    ),
                    child: Icon(
                      Icons.add_rounded,
                      color: isDark ? Colors.white : Colors.black87,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Empty State or Song List ──
        if (songs.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.music_off_rounded,
                        size: 48,
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.3),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No tracks in this playlist yet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Search for your favorite songs and tap "+ Add to Playlist"',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => context.go('/search'),
                      icon: const Icon(Icons.search_rounded, size: 18, color: Colors.white),
                      label: const Text('Discover Music', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C5CE7),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final song = songs[index];
                  final isCurrent = currentMedia?.id == song.id;
                  final numericId = song.numericId;
                  final isFav = favorites.contains(numericId);

                  return SlideUpFadeIn(
                    delay: AppAnimations.stagger(index, baseMs: 30),
                    child: _UserPlaylistSongTile(
                      index: index,
                      song: song,
                      isCurrent: isCurrent,
                      isPlaying: isPlaying && isCurrent,
                      isFavorite: isFav,
                      onTap: () {
                        final mediaItems = playlist.toMediaItems();
                        handler.loadPlaylist(
                          mediaItems,
                          initialIndex: index,
                          source: QueueSource.playlist,
                        );
                      },
                      onFavoriteToggle: () {
                        ref.read(favoritesProvider.notifier).toggleFavorite(song.id);
                      },
                      onRemove: () async {
                        HapticFeedback.mediumImpact();
                        final success = await ref
                            .read(userPlaylistsProvider.notifier)
                            .removeSongFromPlaylist(
                              playlistId: playlist.id,
                              songId: song.id,
                            );
                        if (context.mounted && success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Removed "${song.displayTitle}" from playlist'),
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                    ),
                  );
                },
                childCount: songs.length,
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 🖥️ Desktop View
// ─────────────────────────────────────────────────────────────────────────────

class _DesktopUserPlaylistView extends ConsumerWidget {
  final UserPlaylist playlist;

  const _DesktopUserPlaylistView({required this.playlist});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final handler = ref.read(audioHandlerProvider);
    final currentMedia = ref.watch(currentMediaItemProvider).value;
    final isPlaying = ref.watch(playbackStateProvider).value?.playing ?? false;
    final favorites = ref.watch(favoritesProvider);
    final songs = playlist.songs;

    return Row(
      children: [
        // ── Left Sidebar Header (Artwork + Info + Actions) ──
        Container(
          width: 340,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF101022) : Colors.white,
            border: Border(
              right: BorderSide(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => context.pop(),
                ),
              ),
              const Spacer(),
              _UserPlaylistArtwork(playlist: playlist, size: 200),
              const SizedBox(height: 20),
              Text(
                playlist.displayTitle,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF1E1E2E),
                ),
              ),
              if (playlist.description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  playlist.description,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.55),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                '${songs.length} tracks • Custom Playlist',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6C5CE7)),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: songs.isEmpty
                          ? null
                          : () {
                              final mediaItems = playlist.toMediaItems();
                              handler.loadPlaylist(
                                mediaItems,
                                initialIndex: 0,
                                source: QueueSource.playlist,
                              );
                            },
                      icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                      label: const Text('Play All', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C5CE7),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Shuffle',
                    onPressed: songs.isEmpty
                        ? null
                        : () {
                            final mediaItems = playlist.toMediaItems();
                            handler.loadPlaylist(
                              mediaItems,
                              initialIndex: 0,
                              source: QueueSource.playlist,
                            );
                            handler.setShuffleEnabled(true);
                          },
                    icon: const Icon(Icons.shuffle_rounded),
                  ),
                ],
              ),
              const Spacer(),
            ],
          ),
        ),

        // ── Right Song List ──
        Expanded(
          child: songs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.queue_music_rounded, size: 64, color: isDark ? Colors.white24 : Colors.black26),
                      const SizedBox(height: 16),
                      Text(
                        'This playlist has no songs yet',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => context.go('/search'),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C5CE7)),
                        child: const Text('Find Songs', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: songs.length,
                  itemBuilder: (context, index) {
                    final song = songs[index];
                    final isCurrent = currentMedia?.id == song.id;
                    final isFav = favorites.contains(song.numericId);

                    return _UserPlaylistSongTile(
                      index: index,
                      song: song,
                      isCurrent: isCurrent,
                      isPlaying: isPlaying && isCurrent,
                      isFavorite: isFav,
                      onTap: () {
                        final mediaItems = playlist.toMediaItems();
                        handler.loadPlaylist(
                          mediaItems,
                          initialIndex: index,
                          source: QueueSource.playlist,
                        );
                      },
                      onFavoriteToggle: () {
                        ref.read(favoritesProvider.notifier).toggleFavorite(song.id);
                      },
                      onRemove: () async {
                        await ref.read(userPlaylistsProvider.notifier).removeSongFromPlaylist(
                              playlistId: playlist.id,
                              songId: song.id,
                            );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 🎵 Song List Tile
// ─────────────────────────────────────────────────────────────────────────────

class _UserPlaylistSongTile extends StatelessWidget {
  final int index;
  final HomeItem song;
  final bool isCurrent;
  final bool isPlaying;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onRemove;

  const _UserPlaylistSongTile({
    required this.index,
    required this.song,
    required this.isCurrent,
    required this.isPlaying,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoriteToggle,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isCurrent
            ? const Color(0xFF6C5CE7).withValues(alpha: isDark ? 0.15 : 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: isCurrent
            ? Border.all(color: const Color(0xFF6C5CE7).withValues(alpha: 0.3))
            : null,
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        leading: SizedBox(
          width: 50,
          child: Row(
            children: [
              // Index or Play Indicator
              SizedBox(
                width: 20,
                child: isPlaying
                    ? const Icon(Icons.graphic_eq_rounded, color: Color(0xFF6C5CE7), size: 18)
                    : Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                          color: isCurrent
                              ? const Color(0xFF6C5CE7)
                              : (isDark ? Colors.white38 : Colors.black38),
                        ),
                      ),
              ),
              const SizedBox(width: 6),
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: song.displayImage != null && song.displayImage!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: song.displayImage!,
                        width: 24,
                        height: 24,
                        fit: BoxFit.cover,
                        placeholder: (ctx, url) => Container(color: Colors.white10),
                      )
                    : Container(
                        width: 24,
                        height: 24,
                        color: Colors.white10,
                        child: const Icon(Icons.music_note_rounded, size: 14),
                      ),
              ),
            ],
          ),
        ),
        title: Text(
          song.displayTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
            color: isCurrent
                ? const Color(0xFF6C5CE7)
                : (isDark ? Colors.white : const Color(0xFF1E1E2E)),
          ),
        ),
        subtitle: Text(
          song.displaySubtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Favorite Button
            IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                size: 20,
                color: isFavorite
                    ? const Color(0xFFFF4B6E)
                    : (isDark ? Colors.white38 : Colors.black26),
              ),
              onPressed: onFavoriteToggle,
            ),
            // Remove from Playlist Button
            IconButton(
              tooltip: 'Remove from playlist',
              icon: Icon(
                Icons.remove_circle_outline_rounded,
                size: 20,
                color: (isDark ? Colors.white38 : Colors.black26),
              ),
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 🖼️ Artwork & Visual Helpers
// ─────────────────────────────────────────────────────────────────────────────

class _UserPlaylistArtwork extends StatelessWidget {
  final UserPlaylist playlist;
  final double size;

  const _UserPlaylistArtwork({required this.playlist, required this.size});

  @override
  Widget build(BuildContext context) {
    final image = playlist.displayImage;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C5CE7).withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.16),
        child: image != null && image.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: image,
                fit: BoxFit.cover,
                placeholder: (_, __) => _DefaultArtworkGradient(size: size),
              )
            : _DefaultArtworkGradient(size: size),
      ),
    );
  }
}

class _DefaultArtworkGradient extends StatelessWidget {
  final double size;
  const _DefaultArtworkGradient({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE), Color(0xFFFF7675)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.queue_music_rounded,
          size: size * 0.45,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _UserPlaylistHeaderGlow extends StatelessWidget {
  final UserPlaylist playlist;
  const _UserPlaylistHeaderGlow({required this.playlist});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.3),
          radius: 1.2,
          colors: [
            Color(0xFF6C5CE7),
            Color(0xFF2D3436),
            Colors.transparent,
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? iconColor;

  const _CircleIconButton({
    required this.icon,
    required this.onPressed,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.3),
            shape: BoxShape.circle,
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
            ),
          ),
          child: IconButton(
            icon: Icon(icon, size: 18, color: iconColor ?? (isDark ? Colors.white : Colors.black87)),
            onPressed: onPressed,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 💀 Loading & Error Skeletons
// ─────────────────────────────────────────────────────────────────────────────

class _UserPlaylistLoadingSkeleton extends StatelessWidget {
  final bool isDesktop;
  const _UserPlaylistLoadingSkeleton({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _UserPlaylistErrorView extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;

  const _UserPlaylistErrorView({
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.black54),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C5CE7)),
              child: const Text('Try Again', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
