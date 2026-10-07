import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rhythm_flutter/core/animations/app_animations.dart';
import 'package:rhythm_flutter/features/playlist/data/models/user_playlist.dart';
import 'package:rhythm_flutter/features/playlist/presentation/widgets/create_playlist_dialog.dart';
import 'package:rhythm_flutter/features/playlist/providers/user_playlist_provider.dart';

/// Screen listing all custom user playlists with ability to create, delete, and open playlists
class UserPlaylistsScreen extends ConsumerWidget {
  const UserPlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final playlistsAsync = ref.watch(userPlaylistsProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0C0B16) : const Color(0xFFF7F7FD),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0C0B16) : Colors.white,
        elevation: 0,
        title: const Text(
          'Your Playlists',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        actions: [
          IconButton(
            tooltip: 'Create Playlist',
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
            ),
            onPressed: () => CreatePlaylistDialog.show(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => CreatePlaylistDialog.show(context),
        backgroundColor: const Color(0xFF6C5CE7),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'New Playlist',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: RefreshIndicator(
        onRefresh: () => ref.read(userPlaylistsProvider.notifier).refresh(),
        child: playlistsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                  const SizedBox(height: 12),
                  Text('Failed to load playlists: $err', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.read(userPlaylistsProvider.notifier).refresh(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
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
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.playlist_add_rounded,
                          size: 56,
                          color: const Color(0xFF6C5CE7).withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Create Your First Playlist',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Organize your favorite tracks into custom collections for every mood and moment.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => CreatePlaylistDialog.show(context),
                        icon: const Icon(Icons.add_rounded, color: Colors.white),
                        label: const Text(
                          'Create Playlist',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C5CE7),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: customPlaylists.length,
              itemBuilder: (context, index) {
                final playlist = customPlaylists[index];

                return SlideUpFadeIn(
                  delay: AppAnimations.stagger(index, baseMs: 40),
                  child: _UserPlaylistItemCard(
                    playlist: playlist,
                    isDark: isDark,
                    onTap: () => context.push('/user-playlist/${playlist.id}'),
                    onDelete: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Playlist'),
                          content: Text('Are you sure you want to delete "${playlist.name}"?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Delete', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true) {
                        await ref.read(userPlaylistsProvider.notifier).deletePlaylist(playlist.id);
                      }
                    },
                  ),
                );
              },
            );
          },
        ),
        ),
        ),
      ),
    );
  }
}

class _UserPlaylistItemCard extends StatelessWidget {
  final UserPlaylist playlist;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _UserPlaylistItemCard({
    required this.playlist,
    required this.isDark,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141324) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        onTap: onTap,
        leading: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Icon(Icons.queue_music_rounded, color: Colors.white, size: 26),
          ),
        ),
        title: Text(
          playlist.displayTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15.5,
            color: isDark ? Colors.white : const Color(0xFF1E1E2E),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (playlist.description.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                playlist.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5),
                ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              '${playlist.songCount} ${playlist.songCount == 1 ? "track" : "tracks"}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6C5CE7),
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert_rounded,
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.4),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          onSelected: (val) {
            if (val == 'delete') onDelete();
            if (val == 'open') onTap();
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'open',
              child: Row(
                children: [
                  Icon(Icons.folder_open_rounded, size: 18),
                  SizedBox(width: 10),
                  Text('Open Playlist'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                  SizedBox(width: 10),
                  Text('Delete', style: TextStyle(color: Colors.redAccent)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
