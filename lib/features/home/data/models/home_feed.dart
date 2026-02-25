import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:rhythm_flutter/features/home/data/models/music.dart';

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

extension HomeSectionX on HomeSection {
  String getDisplayTitle(String locale) => title;
  List<int> get musicIds => items;
}

@freezed
class HomeFeed with _$HomeFeed {
  const factory HomeFeed({
    required List<HomeSection> sections,
    @JsonKey(name: 'music_map') required Map<String, Music> musicMap,
  }) = _HomeFeed;

  factory HomeFeed.fromJson(Map<String, dynamic> json) => _$HomeFeedFromJson(json);
}

extension HomeFeedX on HomeFeed {
  Music? getMusicById(int id) => musicMap[id.toString()];
}
