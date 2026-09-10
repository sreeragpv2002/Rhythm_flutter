import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rhythm_flutter/features/home/data/models/home_feed.dart';
import 'package:rhythm_flutter/features/home/data/models/music.dart';
import 'package:rhythm_flutter/features/home/data/repositories/music_repository.dart';
import 'package:rhythm_flutter/features/home/providers/favorites_provider.dart';
import 'package:rhythm_flutter/features/search/data/models/search_result.dart';

part 'search_provider.g.dart';

@riverpod
class SearchQuery extends _$SearchQuery {
  @override
  String build() => '';

  void updateQuery(String query) {
    state = query;
  }
}

enum SearchCategoryFilter {
  all('All'),
  songs('Songs'),
  albums('Albums'),
  artists('Artists'),
  playlists('Playlists');

  final String label;
  const SearchCategoryFilter(this.label);
}

final searchCategoryFilterProvider =
    StateProvider<SearchCategoryFilter>((ref) => SearchCategoryFilter.all);

@riverpod
Future<SearchResult> searchResults(Ref ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.trim().isEmpty || query.trim().length < 2) {
    return const SearchResult();
  }

  // Wait for 350ms debounce
  await Future.delayed(const Duration(milliseconds: 350));
  if (ref.read(searchQueryProvider) != query) {
    // If query changed while we were waiting, discard this request
    return const SearchResult();
  }

  final repository = ref.read(musicRepositoryProvider);
  final results = await repository.search(query: query.trim(), limit: 50);

  // Sync favorites state with search results songs
  if (results.songs.isNotEmpty) {
    final musicList = results.songs
        .map((s) => Music.fromJson(s.toJson()))
        .toList();
    ref.read(favoritesProvider.notifier).initFromList(musicList);
  }

  return results;
}

final songsSearchResultsProvider =
    FutureProvider.autoDispose<List<HomeItem>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.trim().isEmpty || query.trim().length < 2) {
    return [];
  }

  // Wait for 350ms debounce
  await Future.delayed(const Duration(milliseconds: 350));
  if (ref.read(searchQueryProvider) != query) {
    return [];
  }

  final repository = ref.read(musicRepositoryProvider);
  final songs = await repository.getSongsByQuery(query: query.trim(), limit: 50);

  // Sync favorites state
  if (songs.isNotEmpty) {
    ref.read(favoritesProvider.notifier).initFromHomeItems(songs);
  }

  return songs;
});

