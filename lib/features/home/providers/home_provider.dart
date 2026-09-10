import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rhythm_flutter/features/home/data/models/home_feed.dart';
import 'package:rhythm_flutter/features/home/data/repositories/home_repository.dart';
import 'package:rhythm_flutter/features/home/data/repositories/music_repository.dart';

part 'home_provider.g.dart';

@riverpod
class Home extends _$Home {
  @override
  Future<HomeFeed> build() async {
    final repository = ref.watch(homeRepositoryProvider);
    final feed = await repository.getHomeFeed();
    return feed;
  }

  Future<void> fetchHomeFeed() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(homeRepositoryProvider);
      final feed = await repository.getHomeFeed();
      return feed;
    });
  }
}

/// Provider to fetch up to 50 items (songs or playlists) for a section or query
final sectionSongsProvider = FutureProvider.autoDispose.family<List<HomeItem>, String>((ref, slugOrTitle) async {
  final musicRepo = ref.watch(musicRepositoryProvider);
  final normalized = slugOrTitle.toLowerCase().trim();

  // 1. Playlist Section: GET /api/v1/search/playlists?query=trending&limit=50
  if (normalized == 'featured_playlists' ||
      normalized == 'playlists' ||
      normalized.contains('playlist')) {
    final query = normalized == 'featured_playlists' ? 'trending' : slugOrTitle.replaceAll('_', ' ');
    final playlists = await musicRepo.getPlaylistsByQuery(query: query, limit: 50);
    if (playlists.isNotEmpty) {
      return playlists;
    }
  }

  // 2. Songs Section: GET /api/v1/search/songs?query=top%20trending&limit=50
  String songQuery = 'top trending';
  if (normalized.isEmpty ||
      normalized == 'trending_songs' ||
      normalized.contains('trending') ||
      normalized == 'top trending') {
    songQuery = 'top trending';
  } else if (!normalized.contains('recent')) {
    songQuery = slugOrTitle.replaceAll('_', ' ');
  }

  final songs = await musicRepo.getSongsByQuery(query: songQuery, limit: 50);
  if (songs.isNotEmpty) {
    return songs;
  }

  // 3. Fallback to home feed items if API returns empty
  final homeFeed = ref.read(homeProvider).valueOrNull;
  if (homeFeed != null) {
    final section = homeFeed.sections.firstWhere(
      (s) => s.slug == slugOrTitle || s.title.toLowerCase() == normalized,
      orElse: () => HomeSection(title: slugOrTitle, slug: slugOrTitle, items: []),
    );
    return section.items;
  }
  return [];
});
