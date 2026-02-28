import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rhythm_flutter/features/home/data/models/music.dart';
import 'package:rhythm_flutter/features/home/data/repositories/music_repository.dart';
import 'package:rhythm_flutter/features/home/providers/favorites_provider.dart';

part 'search_provider.g.dart';

@riverpod
class SearchQuery extends _$SearchQuery {
  @override
  String build() => '';

  void updateQuery(String query) {
    state = query;
  }
}

@riverpod
Future<List<Music>> searchResults(Ref ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty || query.length < 2) return [];

  // Wait for 500ms debounce
  await Future.delayed(const Duration(milliseconds: 500));
  if (ref.read(searchQueryProvider) != query) {
    // If query changed while we were waiting, discard this request
    return [];
  }

  final repository = ref.read(musicRepositoryProvider);
  final results = await repository.searchMusic(query);
  
  // Sync favorites state with search results
  if (results.isNotEmpty) {
     ref.read(favoritesProvider.notifier).initFromList(results);
  }
  
  return results;
}
