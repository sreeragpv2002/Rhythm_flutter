import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rhythm_flutter/features/album/data/models/album_detail.dart';
import 'package:rhythm_flutter/features/home/data/repositories/music_repository.dart';
import 'package:rhythm_flutter/features/home/providers/favorites_provider.dart';

/// Provider to fetch and cache Album Details by Album ID
final albumDetailProvider = FutureProvider.family<AlbumDetail, String>((ref, albumId) async {
  final repository = ref.read(musicRepositoryProvider);
  final album = await repository.getAlbumDetails(albumId);
  
  if (album == null) {
    throw Exception('Failed to load album details for id: $albumId');
  }

  // Pre-seed favorites state with the album's songs
  if (album.songs.isNotEmpty) {
    ref.read(favoritesProvider.notifier).initFromList(album.songs);
  }

  return album;
});
