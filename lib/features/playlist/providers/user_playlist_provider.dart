import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rhythm_flutter/features/home/data/repositories/music_repository.dart';
import 'package:rhythm_flutter/features/playlist/data/models/user_playlist.dart';

/// Provider to fetch and manage the user's custom playlists
final userPlaylistsProvider =
    AsyncNotifierProvider<UserPlaylistsNotifier, List<UserPlaylist>>(
  UserPlaylistsNotifier.new,
);

class UserPlaylistsNotifier extends AsyncNotifier<List<UserPlaylist>> {
  @override
  Future<List<UserPlaylist>> build() async {
    final repository = ref.watch(musicRepositoryProvider);
    return await repository.getUserPlaylists();
  }

  /// Create a new custom playlist and update state immediately
  Future<UserPlaylist?> createPlaylist({
    required String name,
    String? description,
    List<String>? songIds,
  }) async {
    final repository = ref.read(musicRepositoryProvider);
    final created = await repository.createUserPlaylist(
      name: name,
      description: description,
      songIds: songIds,
    );

    if (created != null) {
      final currentList = state.valueOrNull ?? [];
      state = AsyncValue.data([created, ...currentList.where((p) => p.id != created.id)]);
      ref.invalidateSelf();
    }
    return created;
  }

  /// Delete a custom playlist
  Future<bool> deletePlaylist(String playlistId) async {
    final repository = ref.read(musicRepositoryProvider);
    final success = await repository.deleteUserPlaylist(playlistId: playlistId);

    if (success) {
      final currentList = state.valueOrNull ?? [];
      state = AsyncValue.data(currentList.where((p) => p.id != playlistId).toList());
    }
    return success;
  }

  /// Add a song to a user playlist
  Future<bool> addSongToPlaylist({
    required String playlistId,
    required String songId,
  }) async {
    final repository = ref.read(musicRepositoryProvider);
    final success = await repository.addSongToUserPlaylist(
      playlistId: playlistId,
      songId: songId,
    );

    if (success) {
      ref.invalidate(userPlaylistDetailsProvider(playlistId));
      ref.invalidateSelf();
    }
    return success;
  }

  /// Remove a song from a user playlist
  Future<bool> removeSongFromPlaylist({
    required String playlistId,
    required String songId,
  }) async {
    final repository = ref.read(musicRepositoryProvider);
    final success = await repository.removeSongFromUserPlaylist(
      playlistId: playlistId,
      songId: songId,
    );

    if (success) {
      ref.invalidate(userPlaylistDetailsProvider(playlistId));
      ref.invalidateSelf();
    }
    return success;
  }

  /// Refresh playlists
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(musicRepositoryProvider);
      return await repository.getUserPlaylists();
    });
  }
}

/// Provider to fetch details & songs of a specific user playlist
final userPlaylistDetailsProvider =
    FutureProvider.family<UserPlaylist?, String>((ref, playlistId) async {
  final repository = ref.watch(musicRepositoryProvider);
  return await repository.getUserPlaylistDetails(playlistId: playlistId);
});
