import 'package:freezed_annotation/freezed_annotation.dart';

part 'tag.freezed.dart';
part 'tag.g.dart';

@freezed
class Tag with _$Tag {
  const factory Tag({
    required int id,
    required String name,
    required String category,
    required String description,
    @JsonKey(name: 'color_code') required String colorCode,
    @Default('') String icon,
    @JsonKey(name: 'created_at') required String createdAt,
  }) = _Tag;

  factory Tag.fromJson(Map<String, dynamic> json) => _$TagFromJson(json);
}
