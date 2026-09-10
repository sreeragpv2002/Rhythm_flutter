import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rhythm_flutter/features/artist/data/models/artist_detail.dart';
import 'package:rhythm_flutter/features/home/data/repositories/music_repository.dart';
import 'package:rhythm_flutter/features/home/providers/favorites_provider.dart';

/// Provider to fetch and cache Artist Details by Artist ID
final artistDetailProvider = FutureProvider.family<ArtistDetail, String>((ref, artistId) async {
  final repository = ref.read(musicRepositoryProvider);
  final artist = await repository.getArtistDetails(artistId, songCount: 50, albumCount: 50);

  if (artist == null) {
    throw Exception('Failed to load artist details for id: $artistId');
  }

  // Pre-seed favorites state with artist's top songs
  if (artist.topSongs.isNotEmpty) {
    ref.read(favoritesProvider.notifier).initFromList(artist.topSongs);
  }

  return artist;
});
