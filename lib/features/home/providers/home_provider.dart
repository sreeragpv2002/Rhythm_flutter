import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rhythm_flutter/features/home/data/models/home_feed.dart';
import 'package:rhythm_flutter/features/home/data/repositories/home_repository.dart';
import 'package:rhythm_flutter/features/home/providers/favorites_provider.dart';

part 'home_provider.g.dart';

@riverpod
class Home extends _$Home {
  @override
  Future<HomeFeed> build() async {
    final repository = ref.watch(homeRepositoryProvider);
    final feed = await repository.getHomeFeed();
    
    // Initialize favorites from feed musicMap
    final songs = feed.musicMap.values.toList();
    ref.read(favoritesProvider.notifier).initFromList(songs);
    
    return feed;
  }

  Future<void> fetchHomeFeed() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(homeRepositoryProvider);
      final feed = await repository.getHomeFeed();
      
      // Initialize favorites from feed musicMap on manual refresh
      final songs = feed.musicMap.values.toList();
      ref.read(favoritesProvider.notifier).initFromList(songs);
      
      return feed;
    });
  }
}
