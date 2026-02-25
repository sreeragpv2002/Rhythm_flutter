// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'music.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MusicImpl _$$MusicImplFromJson(Map<String, dynamic> json) => _$MusicImpl(
      id: (json['id'] as num).toInt(),
      titles: Map<String, String>.from(json['titles'] as Map),
      artistNames: (json['artist_names'] as List<dynamic>)
          .map((e) => Map<String, String>.from(e as Map))
          .toList(),
      albumTitles: (json['album_titles'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
      thumbUrl: json['thumb_url'] as String?,
      audioUrl: json['audio_url'] as String?,
      duration: (json['duration'] as num).toInt(),
      language: json['language'] as String,
      languageDisplay: json['language_display'] as String,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => Tag.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      playCount: (json['play_count'] as num?)?.toInt() ?? 0,
      isFavorited: json['is_favorited'] as bool? ?? false,
      isFavorite: json['is_favorite'] as bool? ?? false,
      nextSongId: (json['next_song_id'] as num?)?.toInt(),
      previousSongId: (json['previous_song_id'] as num?)?.toInt(),
      relatedByAlbum: (json['related_by_album'] as List<dynamic>?)
          ?.map((e) => Music.fromJson(e as Map<String, dynamic>))
          .toList(),
      relatedByArtist: (json['related_by_artist'] as List<dynamic>?)
          ?.map((e) => Music.fromJson(e as Map<String, dynamic>))
          .toList(),
      relatedByTags: (json['related_by_tags'] as List<dynamic>?)
          ?.map((e) => Music.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$MusicImplToJson(_$MusicImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'titles': instance.titles,
      'artist_names': instance.artistNames,
      'album_titles': instance.albumTitles,
      'thumb_url': instance.thumbUrl,
      'audio_url': instance.audioUrl,
      'duration': instance.duration,
      'language': instance.language,
      'language_display': instance.languageDisplay,
      'tags': instance.tags,
      'play_count': instance.playCount,
      'is_favorited': instance.isFavorited,
      'is_favorite': instance.isFavorite,
      'next_song_id': instance.nextSongId,
      'previous_song_id': instance.previousSongId,
      'related_by_album': instance.relatedByAlbum,
      'related_by_artist': instance.relatedByArtist,
      'related_by_tags': instance.relatedByTags,
    };
