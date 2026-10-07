import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rhythm_flutter/core/theme/scroll_physics.dart';
import 'package:rhythm_flutter/features/playlist/data/models/user_playlist.dart';
import 'package:rhythm_flutter/features/playlist/presentation/widgets/create_playlist_dialog.dart';
import 'package:rhythm_flutter/features/playlist/providers/user_playlist_provider.dart';

/// Bottom sheet modal to add a song into one or more user playlists
class AddToPlaylistSheet extends ConsumerStatefulWidget {
  final String songId;
  final String songTitle;
  final String? songSubtitle;
  final String? imageUrl;

  const AddToPlaylistSheet({
    super.key,
    required this.songId,
    required this.songTitle,
    this.songSubtitle,
    this.imageUrl,
  });

  static Future<void> show(
    BuildContext context, {
    required String songId,
    required String songTitle,
    String? songSubtitle,
    String? imageUrl,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddToPlaylistSheet(
        songId: songId,
        songTitle: songTitle,
        songSubtitle: songSubtitle,
        imageUrl: imageUrl,
      ),
    );
  }

  @override
  ConsumerState<AddToPlaylistSheet> createState() => _AddToPlaylistSheetState();
}

class _AddToPlaylistSheetState extends ConsumerState<AddToPlaylistSheet> {
  final Set<String> _addingIds = {};

  Future<void> _handleAddToPlaylist(UserPlaylist playlist) async {
    if (_addingIds.contains(playlist.id)) return;

    setState(() => _addingIds.add(playlist.id));
    HapticFeedback.mediumImpact();

    try {
      final success = await ref
          .read(userPlaylistsProvider.notifier)
          .addSongToPlaylist(
            playlistId: playlist.id,
            songId: widget.songId,
          );

      if (mounted) {
        setState(() => _addingIds.remove(playlist.id));
        if (success) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added "${widget.songTitle}" to "${playlist.name}"'),
              backgroundColor: const Color(0xFF6C5CE7),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not add to playlist. Please try again.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _addingIds.remove(playlist.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final playlistsAsync = ref.watch(userPlaylistsProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141422) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Drag Handle ──
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // ── Song Header Preview ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: widget.imageUrl != null && widget.imageUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: widget.imageUrl!,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            placeholder: (ctx, url) => Container(
                              width: 44,
                              height: 44,
                              color: isDark ? Colors.white10 : Colors.black12,
                              child: const Icon(Icons.music_note_rounded, size: 20),
                            ),
                          )
                        : Container(
                            width: 44,
                            height: 44,
                            color: isDark ? Colors.white10 : Colors.black12,
                            child: const Icon(Icons.music_note_rounded, size: 20),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add to Playlist',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF1E1E2E),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.songTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // ── Create New Playlist Tile ──
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
              ),
              title: const Text(
                'New Playlist',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
              ),
              subtitle: const Text(
                'Create a new playlist with this song',
                style: TextStyle(fontSize: 12),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () async {
                Navigator.of(context).pop();
                await CreatePlaylistDialog.show(context, initialSongId: widget.songId);
              },
            ),

            const Divider(height: 1, indent: 68),

            // ── Playlists List ──
            Flexible(
              child: playlistsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, _) => Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text('Error loading playlists: $err', style: const TextStyle(fontSize: 12)),
                  ),
                ),
                data: (playlists) {
                  // Filter out default Favorites playlist from custom add target, or keep all
                  final customPlaylists = playlists.where((p) => !p.isFavorite).toList();

                  if (customPlaylists.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                      child: Center(
                        child: Text(
                          'No custom playlists yet.\nTap "New Playlist" above to create your first one!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.45),
                            height: 1.4,
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: AppScrollPhysics.adaptive,
                    itemCount: customPlaylists.length,
                    itemBuilder: (context, index) {
                      final playlist = customPlaylists[index];
                      final isAdding = _addingIds.contains(playlist.id);

                      return ListTile(
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF6C5CE7).withValues(alpha: 0.7),
                                const Color(0xFFFF7675).withValues(alpha: 0.7),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.queue_music_rounded, color: Colors.white, size: 22),
                        ),
                        title: Text(
                          playlist.displayTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        subtitle: Text(
                          '${playlist.songCount} ${playlist.songCount == 1 ? "track" : "tracks"}',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5),
                          ),
                        ),
                        trailing: isAdding
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.add_circle_outline_rounded, size: 22),
                        onTap: () => _handleAddToPlaylist(playlist),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
