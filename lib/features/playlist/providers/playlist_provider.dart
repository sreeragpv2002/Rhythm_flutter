import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rhythm_flutter/features/home/data/repositories/music_repository.dart';
import 'package:rhythm_flutter/features/home/providers/favorites_provider.dart';
import 'package:rhythm_flutter/features/playlist/data/models/playlist_detail.dart';

/// Provider to fetch and cache Playlist Details by Playlist ID
final playlistDetailProvider = FutureProvider.family<PlaylistDetail, String>((ref, playlistId) async {
  final repository = ref.read(musicRepositoryProvider);
  final playlist = await repository.getPlaylistDetails(playlistId);

  if (playlist == null) {
    throw Exception('Failed to load playlist details for id: $playlistId');
  }

  // Pre-seed favorites state with the playlist's songs
  if (playlist.songs.isNotEmpty) {
    ref.read(favoritesProvider.notifier).initFromList(playlist.songs);
  }

  return playlist;
});
