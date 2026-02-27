import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rhythm_flutter/features/home/data/models/music.dart';
import 'package:rhythm_flutter/features/home/data/repositories/music_repository.dart';

part 'favorites_provider.g.dart';

@riverpod
class Favorites extends _$Favorites {
  @override
  Set<int> build() {
    return {};
  }

  /// Initialize favorited IDs from a list of music items (e.g., from HomeFeed or Playback)
  void initFromList(List<Music> songs) {
    final favoritedIds = songs
        .where((s) => s.isFavorited || s.isFavorite)
        .map((s) => s.id)
        .toSet();
    state = {...state, ...favoritedIds};
  }

  /// Toggle favorite status via API and update local state.
  /// Accepts just the music ID \u2014 no need for the full Music object.
  Future<void> toggleFavorite(int id) async {
    final repository = ref.read(musicRepositoryProvider);
    
    // Optimistic UI update
    final set = Set<int>.from(state);
    final isCurrentlyLiked = set.contains(id);
    debugPrint('💚 toggleFavorite: id=$id, isCurrentlyLiked=$isCurrentlyLiked');
    
    if (isCurrentlyLiked) {
      set.remove(id);
    } else {
      set.add(id);
    }
    state = set;
    debugPrint('💚 toggleFavorite: optimistic state updated to $state');

    try {
      final isLiked = await repository.toggleFavorite(id);
      debugPrint('💚 toggleFavorite: API returned isLiked=$isLiked');
      
      // Update state with actual response if different
      final finalSet = Set<int>.from(state);
      if (isLiked) {
        finalSet.add(id);
      } else {
        finalSet.remove(id);
      }
      state = finalSet;
      debugPrint('💚 toggleFavorite: final state=$state');
    } catch (e) {
      debugPrint('💚 toggleFavorite: API error=$e, reverting');
      // Revert on error
      final revertSet = Set<int>.from(state);
      if (isCurrentlyLiked) {
        revertSet.add(id);
      } else {
        revertSet.remove(id);
      }
      state = revertSet;
      rethrow;
    }
  }

  bool isFavorited(int id) => state.contains(id);
}
