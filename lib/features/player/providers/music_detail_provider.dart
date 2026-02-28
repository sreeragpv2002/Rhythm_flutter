import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rhythm_flutter/features/home/data/models/music.dart';
import 'package:rhythm_flutter/features/home/data/repositories/music_repository.dart';
import 'package:rhythm_flutter/features/home/providers/favorites_provider.dart';


/// Fetch single music details
final musicDetailsProvider =
FutureProvider.family<Music, int>((ref, id) async {
  final repository = ref.read(musicRepositoryProvider);
  final music = await repository.getMusicDetails(id);
  
  // Sync favorites state
  ref.read(favoritesProvider.notifier).initFromList([music]);
  
  return music;
});

/// Fetch related songs
final relatedSongsProvider =
FutureProvider.family<List<Music>, int>((ref, id) async {
  final repository = ref.read(musicRepositoryProvider);
  final related = await repository.getRelatedSongs(id);
  
  // Sync favorites state for related songs
  if (related.isNotEmpty) {
    ref.read(favoritesProvider.notifier).initFromList(related);
  }
  
  return related;
});