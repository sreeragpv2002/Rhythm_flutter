// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:collection/collection.dart';
import 'package:rhythm_flutter/features/home/data/models/tag.dart';

part 'music.freezed.dart';
part 'music.g.dart';

@freezed
class Music with _$Music {
  const Music._();

  const factory Music({
    required int id,
    required Map<String, String> titles,
    @JsonKey(name: 'artist_names') required List<Map<String, String>> artistNames,
    @                                                                                                                                                     JsonKey(name: 'album_titles') Map<String, String>? albumTitles,
    @JsonKey(name: 'thumb_url') String? thumbUrl,
    @JsonKey(name: 'audio_url') String? audioUrl,
    required int duration,
    required String language,
    @JsonKey(name: 'language_display') required String languageDisplay,
    @Default([]) List<Tag> tags,
    @JsonKey(name: 'play_count') @Default(0) int playCount,
    @JsonKey(name: 'is_favorited') @Default(false) bool isFavorited,
    @JsonKey(name: 'is_favorite') @Default(false) bool isFavorite,
    @JsonKey(name: 'next_song_id') int? nextSongId,
    @JsonKey(name: 'previous_song_id') int? previousSongId,
    @JsonKey(name: 'related_by_album') List<Music>? relatedByAlbum,
    @JsonKey(name: 'related_by_artist') List<Music>? relatedByArtist,
    @JsonKey(name: 'related_by_tags') List<Music>? relatedByTags,
  }) = _Music;

  factory Music.fromJson(Map<String, dynamic> json) => 
      _$MusicFromJson(_normalizeJson(json));

  static Map<String, dynamic> _normalizeJson(Map<String, dynamic> json) {
    // Ensure we have a mutable map
    final data = Map<String, dynamic>.from(json);

    // 1. Handle titles mapping
    if (data['titles'] == null && data['title'] != null) {
      if (data['title'] is Map) {
        data['titles'] = Map<String, String>.from(data['title']);
      } else {
        final lang = data['language'] as String? ?? 'en';
        data['titles'] = {lang: data['title']};
      }
    } else if (data['titles'] == null) {
      data['titles'] = <String, String>{};
    }

    // 2. Handle artists mapping (Normalize to List of Maps)
    if (data['artist_names'] == null) {
      if (data['artist'] != null && data['artist'] is List) {
        final rawArtists = data['artist'] as List;
        data['artist_names'] = rawArtists.map((e) {
          if (e is Map && e['name'] != null) {
            // Check if name is already a map (localized) or a string
            if (e['name'] is Map) return Map<String, String>.from(e['name']);
            return {'en': e['name'].toString()};
          }
          return {'en': e.toString()};
        }).toList();
      } else if (data['artist'] != null) {
         // Handle single artist object if any
         final e = data['artist'];
         if (e is Map && e['name'] != null) {
            final name = e['name'] is Map ? Map<String, String>.from(e['name']) : {'en': e['name'].toString()};
            data['artist_names'] = [name];
         }
      }
    }

    if (data['artist_names'] != null && data['artist_names'] is List) {
      final rawList = data['artist_names'] as List;
      data['artist_names'] = rawList.map((e) {
        if (e is Map) {
          // If it's the new complex artist object with 'name' field
          if (e['name'] != null) {
            if (e['name'] is Map) return Map<String, String>.from(e['name']);
            return {'en': e['name'].toString()};
          }
          return Map<String, String>.from(e.map((k, v) => MapEntry(k.toString(), v.toString())));
        }
        return {'en': e.toString()};
      }).toList();
    } else if (data['artist_names'] == null) {
      data['artist_names'] = <Map<String, String>>[];
    }

    // 3. Handle album mapping (Normalize to Map)
    if (data['album_titles'] == null) {
      if (data['album'] != null && data['album'] is Map) {
         final album = data['album'] as Map;
         if (album['titles'] != null && album['titles'] is Map) {
            data['album_titles'] = Map<String, String>.from(album['titles']);
         } else if (album['title'] != null) {
            if (album['title'] is Map) {
              data['album_titles'] = Map<String, String>.from(album['title']);
            } else {
              data['album_titles'] = {'en': album['title'].toString()};
            }
         }
      } else if (data['album_title'] != null) {
         if (data['album_title'] is Map) {
           data['album_titles'] = Map<String, String>.from(data['album_title']);
         } else {
           data['album_titles'] = {'en': data['album_title'].toString()};
         }
      }
    }

    // 4. Handle Playback specific fields
    if (data['duration_seconds'] != null) {
      data['duration'] = data['duration_seconds'];
    }

    if (data['artists'] != null && data['artists'] is List && (data['artist_names'] == null || (data['artist_names'] as List).isEmpty)) {
      final rawArtists = data['artists'] as List;
      data['artist_names'] = rawArtists.map((e) {
        if (e is Map && e['name'] != null) {
          if (e['name'] is Map) return Map<String, String>.from(e['name']);
          return {'en': e['name'].toString()};
        }
        return {'en': e.toString()};
      }).toList();
    }

    if (data['album_titles'] != null && data['album_titles'] is Map) {
      data['album_titles'] = Map<String, String>.from(
          (data['album_titles'] as Map).map((k, v) => MapEntry(k.toString(), v.toString())));
    }

    // Unify favorite fields
    dynamic rawFav = data['is_favorite'] ?? data['is_favorited'] ?? data['favorited'];
    bool isFavValue = false;
    if (rawFav != null) {
      if (rawFav is bool) {
        isFavValue = rawFav;
      } else if (rawFav is int) {
        isFavValue = rawFav == 1;
      } else if (rawFav is String) {
        isFavValue = rawFav.toLowerCase() == 'true' || rawFav == '1';
      }
    }
    
    data['is_favorited'] = isFavValue;
    data['is_favorite'] = isFavValue;

    return data;
  }

  String getDisplayTitle(String locale) {
    return titles[locale] ?? titles['en'] ?? titles.values.firstOrNull ?? '';
  }

  String getDisplayArtists(String locale) {
    if (artistNames.isEmpty) return '';
    return artistNames.map((a) => a[locale] ?? a['en'] ?? a.values.firstOrNull ?? '').join(', ');
  }

  String? getDisplayAlbum(String locale) {
    if (albumTitles == null || albumTitles!.isEmpty) return null;
    return albumTitles![locale] ?? albumTitles!['en'] ?? albumTitles!.values.firstOrNull;
  }
}
