// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_feed.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$HomeSectionImpl _$$HomeSectionImplFromJson(Map<String, dynamic> json) =>
    _$HomeSectionImpl(
      title: json['title'] as String,
      slug: json['slug'] as String,
      items: (json['items'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
    );

Map<String, dynamic> _$$HomeSectionImplToJson(_$HomeSectionImpl instance) =>
    <String, dynamic>{
      'title': instance.title,
      'slug': instance.slug,
      'items': instance.items,
    };

_$HomeFeedImpl _$$HomeFeedImplFromJson(Map<String, dynamic> json) =>
    _$HomeFeedImpl(
      sections: (json['sections'] as List<dynamic>)
          .map((e) => HomeSection.fromJson(e as Map<String, dynamic>))
          .toList(),
      musicMap: (json['music_map'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, Music.fromJson(e as Map<String, dynamic>)),
      ),
    );

Map<String, dynamic> _$$HomeFeedImplToJson(_$HomeFeedImpl instance) =>
    <String, dynamic>{
      'sections': instance.sections,
      'music_map': instance.musicMap,
    };
