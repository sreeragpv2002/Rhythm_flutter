import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rhythm_flutter/features/home/data/models/music.dart';
import 'package:rhythm_flutter/features/home/data/repositories/music_repository.dart';


/// Fetch single music details
final musicDetailsProvider =
FutureProvider.family<Music, int>((ref, id) async {
  final repository = ref.read(musicRepositoryProvider);
  return repository.getMusicDetails(id);
});

/// Fetch related songs
final relatedSongsProvider =
FutureProvider.family<List<Music>, int>((ref, id) async {
  final repository = ref.read(musicRepositoryProvider);
  return repository.getRelatedSongs(id);
});