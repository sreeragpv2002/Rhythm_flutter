import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rhythm_flutter/features/home/data/models/home_feed.dart';
import 'package:rhythm_flutter/features/home/data/repositories/home_repository.dart';

part 'home_provider.g.dart';

@riverpod
class Home extends _$Home {
  @override
  Future<HomeFeed> build() async {
    final repository = ref.watch(homeRepositoryProvider);
    return repository.getHomeFeed();
  }

  Future<void> fetchHomeFeed() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(homeRepositoryProvider);
      return repository.getHomeFeed();
    });
  }
}
