import 'package:freezed_annotation/freezed_annotation.dart';
import 'music.dart';

part 'home_feed.freezed.dart';
part 'home_feed.g.dart';

@freezed
class HomeSection with _$HomeSection {
  const factory HomeSection({
    required String title,
    required String slug,
    required List<int> items,
  }) = _HomeSection;

  factory HomeSection.fromJson(Map<String, dynamic> json) => _$HomeSectionFromJson(json);
}

@freezed
class HomeFeed with _$HomeFeed {
  const factory HomeFeed({
    required List<HomeSection> sections,
    @JsonKey(name: 'music_map') required Map<String, Music> musicMap,
  }) = _HomeFeed;

  factory HomeFeed.fromJson(Map<String, dynamic> json) => _$HomeFeedFromJson(json);
}
