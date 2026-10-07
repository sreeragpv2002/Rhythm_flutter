// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:collection/collection.dart';
import 'package:rhythm_flutter/features/home/data/models/tag.dart';

part 'music.freezed.dart';
part 'music.g.dart';

final Map<int, String> musicRawIdMap = {};
final Map<int, String> musicYoutubeUrlMap = {};
final Map<int, String> musicDurationFormattedMap = {};
final Map<int, List<Music>> musicSuggestedSongsMap = {};

extension MusicRawIdExtension on Music {
  String get rawStringId => musicRawIdMap[id] ?? id.toString();
  String? get youtubeUrl => musicYoutubeUrlMap[id];
  String? get durationFormatted => musicDurationFormattedMap[id];
  List<Music>? get suggestedSongs => musicSuggestedSongsMap[id];
  bool get isYouTubeSong {
    final yUrl = youtubeUrl;
    if (yUrl != null && (yUrl.contains('youtube.com') || yUrl.contains('youtu.be'))) {
      return true;
    }
    final rawId = rawStringId;
    return RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(rawId);
  }
}

@freezed
class Music with _$Music {
  const Music._();

  const factory Music({
    required int id,
    required Map<String, String> titles,
    @JsonKey(name: 'artist_names') required List<Map<String, String>> artistNames,
    @JsonKey(name: 'album_titles') Map<String, String>? albumTitles,
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

    // 0. Handle safe ID (convert alphanumeric string ID if needed)
    int resolvedNumeric = 0;
    if (data['id'] != null) {
      final rawId = data['id'].toString();
      final numericId = int.tryParse(rawId);
      resolvedNumeric = numericId ?? rawId.hashCode.abs();
      data['id'] = resolvedNumeric;
      data['raw_id'] = rawId;
      musicRawIdMap[resolvedNumeric] = rawId;
    }

    // Handle language and languageDisplay
    final lang = data['language']?.toString() ?? 'en';
    data['language'] = lang;
    if (data['language_display'] == null) {
      data['language_display'] = lang.isNotEmpty
          ? '${lang[0].toUpperCase()}${lang.substring(1)}'
          : 'English';
    }

    // 1. Handle titles mapping
    if (data['titles'] == null || (data['titles'] is Map && (data['titles'] as Map).isEmpty)) {
      final nameOrTitle = data['name'] ?? data['title'];
      if (nameOrTitle is Map) {
        data['titles'] = Map<String, String>.from(nameOrTitle);
      } else if (nameOrTitle != null) {
        data['titles'] = {lang: nameOrTitle.toString()};
      } else {
        data['titles'] = {'en': ''};
      }
    } else if (data['titles'] is Map) {
      data['titles'] = Map<String, String>.from(
        (data['titles'] as Map).map((k, v) => MapEntry(k.toString(), v.toString())),
      );
    }

    // 2. Handle artists mapping (Normalize to List of Maps)
    if (data['artist_names'] == null) {
      if (data['artists'] is Map) {
        final artistsMap = data['artists'] as Map;
        final rawPrimary = artistsMap['primary'] as List? ?? artistsMap['all'] as List? ?? [];
        data['artist_names'] = rawPrimary.map((e) {
          if (e is Map && e['name'] != null) {
            return {'en': e['name'].toString()};
          }
          return {'en': e.toString()};
        }).toList();
      } else if (data['artists'] is List) {
        final rawArtists = data['artists'] as List;
        data['artist_names'] = rawArtists.map((e) {
          if (e is Map && e['name'] != null) {
            if (e['name'] is Map) return Map<String, String>.from(e['name']);
            return {'en': e['name'].toString()};
          }
          return {'en': e.toString()};
        }).toList();
      } else if (data['artist'] != null && data['artist'] is List) {
        final rawArtists = data['artist'] as List;
        data['artist_names'] = rawArtists.map((e) {
          if (e is Map && e['name'] != null) {
            if (e['name'] is Map) return Map<String, String>.from(e['name']);
            return {'en': e['name'].toString()};
          }
          return {'en': e.toString()};
        }).toList();
      } else if (data['artist'] is String && (data['artist'] as String).isNotEmpty) {
        final artistStr = data['artist'] as String;
        final names = artistStr.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty);
        data['artist_names'] = names.map((n) => {'en': n}).toList();
      } else if (data['subtitle'] is String && (data['subtitle'] as String).isNotEmpty) {
        final subtitleStr = data['subtitle'] as String;
        final names = subtitleStr.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty);
        data['artist_names'] = names.map((n) => {'en': n}).toList();
      } else if (data['artist'] != null) {
        final e = data['artist'];
        if (e is Map && e['name'] != null) {
          final name = e['name'] is Map
              ? Map<String, String>.from(e['name'])
              : {'en': e['name'].toString()};
          data['artist_names'] = [name];
        }
      }
    }

    if (data['artist_names'] != null && data['artist_names'] is List) {
      final rawList = data['artist_names'] as List;
      data['artist_names'] = rawList.map((e) {
        if (e is Map) {
          if (e['name'] != null) {
            if (e['name'] is Map) return Map<String, String>.from(e['name']);
            return {'en': e['name'].toString()};
          }
          return Map<String, String>.from(e.map((k, v) => MapEntry(k.toString(), v.toString())));
        }
        return {'en': e.toString()};
      }).toList();
    } else {
      data['artist_names'] = <Map<String, String>>[];
    }

    // Fallback to subtitle or artist string if artist_names ended up empty
    if ((data['artist_names'] as List).isEmpty) {
      final fallbackArtist = data['subtitle'] ?? data['artist'];
      if (fallbackArtist is String && fallbackArtist.isNotEmpty) {
        final names = fallbackArtist.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty);
        data['artist_names'] = names.map((n) => {'en': n}).toList();
      }
    }

    // 3. Handle album mapping (Normalize to Map)
    if (data['album_titles'] == null) {
      if (data['album'] != null && data['album'] is Map) {
        final album = data['album'] as Map;
        if (album['titles'] != null && album['titles'] is Map) {
          data['album_titles'] = Map<String, String>.from(album['titles']);
        } else if (album['name'] != null || album['title'] != null) {
          final albumName = (album['name'] ?? album['title']).toString();
          data['album_titles'] = {'en': albumName};
        }
      } else if (data['album_title'] != null) {
        if (data['album_title'] is Map) {
          data['album_titles'] = Map<String, String>.from(data['album_title']);
        } else {
          data['album_titles'] = {'en': data['album_title'].toString()};
        }
      }
    }

    if (data['album_titles'] != null && data['album_titles'] is Map) {
      data['album_titles'] = Map<String, String>.from(
        (data['album_titles'] as Map).map((k, v) => MapEntry(k.toString(), v.toString())),
      );
    }

    // 4. Handle Image / Thumbnail mapping
    if (data['thumb_url'] == null) {
      if (data['image'] is List) {
        final imgList = data['image'] as List;
        final hqImg = imgList.firstWhereOrNull(
          (e) => e is Map && (e['quality']?.toString() == '500x500' || e['quality']?.toString() == '150x150'),
        ) ?? imgList.lastOrNull;
        if (hqImg is Map && hqImg['url'] != null) {
          data['thumb_url'] = hqImg['url'].toString();
        }
      } else if (data['image'] is String) {
        data['thumb_url'] = data['image'];
      } else if (data['image_url'] is String) {
        data['thumb_url'] = data['image_url'];
      }
    }

    // 5. Handle Audio URLs & DownloadUrl quality list
    final rawUrls = data['downloadUrl'] ?? data['download_url'] ?? data['download_urls'];
    if (rawUrls is List && rawUrls.isNotEmpty) {
      if (data['audio_url'] == null) {
        // Pick best available quality as default audio_url
        final hq = (rawUrls as List).firstWhereOrNull(
          (e) => e is Map && (e['quality']?.toString() == '320kbps' || e['quality']?.toString() == '160kbps'),
        ) ?? (rawUrls as List).lastOrNull;
        if (hq is Map && hq['url'] != null) {
          data['audio_url'] = hq['url'].toString();
        }
      }
    }

    // 6. Handle Playback duration (supports duration_formatted like "4:49")
    if (data['duration_seconds'] != null) {
      data['duration'] = data['duration_seconds'];
    } else if (data['duration'] != null &&
        (data['duration'] is num || int.tryParse(data['duration'].toString()) != null)) {
      data['duration'] = data['duration'] is num
          ? (data['duration'] as num).toInt()
          : (int.tryParse(data['duration'].toString()) ?? 0);
    } else if (data['duration_formatted'] != null) {
      final formatted = data['duration_formatted'].toString().trim();
      final parts = formatted.split(':').map((p) => int.tryParse(p) ?? 0).toList();
      if (parts.length == 2) {
        data['duration'] = parts[0] * 60 + parts[1];
      } else if (parts.length == 3) {
        data['duration'] = parts[0] * 3600 + parts[1] * 60 + parts[2];
      } else if (parts.length == 1) {
        data['duration'] = parts[0];
      } else {
        data['duration'] = 0;
      }
    } else {
      data['duration'] = 0;
    }

    // Track YouTube URL and formatted duration in companion maps
    if (data['duration_formatted'] != null) {
      musicDurationFormattedMap[resolvedNumeric] = data['duration_formatted'].toString();
    }
    final ytUrl = data['url']?.toString() ?? data['youtube_url']?.toString();
    if (ytUrl != null && ytUrl.isNotEmpty) {
      musicYoutubeUrlMap[resolvedNumeric] = ytUrl;
      data['youtube_url'] = ytUrl;
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
