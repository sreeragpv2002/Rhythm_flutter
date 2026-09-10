import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rhythm_flutter/features/home/data/models/home_feed.dart';
import 'package:rhythm_flutter/features/home/data/models/music.dart';
import 'package:rhythm_flutter/features/home/data/repositories/music_repository.dart';

part 'favorites_provider.g.dart';

@riverpod
class Favorites extends _$Favorites {
  @override
  Set<int> build() {
    ref.keepAlive(); // Prevents disposal during navigation
    _fetchInitialFavorites();
    return {};
  }

  Future<void> _fetchInitialFavorites() async {
    try {
      final repository = ref.read(musicRepositoryProvider);
      final favList = await repository.getFavoritesList();
      if (favList.isNotEmpty) {
        final ids = <int>{};
        for (final item in favList) {
          final numId = item.numericId;
          musicRawIdMap[numId] = item.id;
          ids.add(numId);
        }
        state = {...state, ...ids};
        debugPrint('💚 FavoritesNotifier: Initial loaded ${ids.length} favorites');
      }
    } catch (e) {
      debugPrint('💚 FavoritesNotifier: Error loading initial favorites: $e');
    }
  }

  /// Initialize favorited IDs from a list of music items (e.g., from HomeFeed or Playback)
  void initFromList(List<Music> songs) {
    if (songs.isEmpty) return;
    
    final songIds = songs.map((s) => s.id).toSet();
    final newlyFavoritedIds = songs
        .where((s) => s.isFavorited || s.isFavorite)
        .map((s) => s.id)
        .toSet();

    for (final song in songs) {
      musicRawIdMap[song.id] = song.rawStringId;
    }

    final updatedState = Set<int>.from(state)
      ..removeAll(songIds.difference(newlyFavoritedIds))
      ..addAll(newlyFavoritedIds);

    state = updatedState;
  }

  /// Initialize favorited IDs from HomeItems
  void initFromHomeItems(List<HomeItem> items) {
    for (final item in items) {
      if (item.isSong) {
        musicRawIdMap[item.numericId] = item.id;
      }
    }
  }

  /// Toggle favorite status via API and update local state.
  /// Accepts song ID as int or String (e.g. 'UPJYO3v0').
  Future<void> toggleFavorite(dynamic id) async {
    final repository = ref.read(musicRepositoryProvider);
    
    final int numericId = id is int 
        ? id 
        : (int.tryParse(id.toString()) ?? id.toString().hashCode.abs());
    
    final String rawStringId = id is String 
        ? id 
        : (musicRawIdMap[numericId] ?? id.toString());

    musicRawIdMap[numericId] = rawStringId;

    // Optimistic UI update
    final set = Set<int>.from(state);
    final isCurrentlyLiked = set.contains(numericId);
    final targetState = !isCurrentlyLiked;
    
    debugPrint('💚 toggleFavorite: songId=$rawStringId, numericId=$numericId, isCurrentlyLiked=$isCurrentlyLiked -> targetState=$targetState');
    
    if (targetState) {
      set.add(numericId);
    } else {
      set.remove(numericId);
    }
    state = set;

    try {
      final isLiked = await repository.toggleFavorite(
        rawStringId,
        shouldFavorite: targetState,
      );
      debugPrint('💚 toggleFavorite: API returned isLiked=$isLiked');
      
      // Update state with actual response if different
      final finalSet = Set<int>.from(state);
      if (isLiked) {
        finalSet.add(numericId);
      } else {
        finalSet.remove(numericId);
      }
      state = finalSet;
      debugPrint('💚 toggleFavorite: final state=$state');
    } catch (e) {
      debugPrint('💚 toggleFavorite: API error=$e, reverting');
      // Revert on error
      final revertSet = Set<int>.from(state);
      if (isCurrentlyLiked) {
        revertSet.add(numericId);
      } else {
        revertSet.remove(numericId);
      }
      state = revertSet;
      rethrow;
    }
  }

  bool isFavorited(dynamic id) {
    final int numericId = id is int 
        ? id 
        : (int.tryParse(id.toString()) ?? id.toString().hashCode.abs());
    return state.contains(numericId);
  }
}

/// Provider for the full list of favorite songs from the backend
final favoritesListProvider = FutureProvider.autoDispose<List<HomeItem>>((ref) async {
  final repository = ref.watch(musicRepositoryProvider);
  final items = await repository.getFavoritesList();
  if (items.isNotEmpty) {
    ref.read(favoritesProvider.notifier).initFromHomeItems(items);
  }
  return items;
});

