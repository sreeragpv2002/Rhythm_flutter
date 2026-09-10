import 'package:audio_service/audio_service.dart';
import 'package:collection/collection.dart';
import 'package:rhythm_flutter/core/services/media_item_mapper.dart';
import 'package:rhythm_flutter/features/home/data/models/music.dart';

class AlbumArtist {
  final String id;
  final String name;
  final String role;
  final String? avatarUrl;
  final String type;
  final String? url;

  const AlbumArtist({
    required this.id,
    required this.name,
    this.role = '',
    this.avatarUrl,
    this.type = 'artist',
    this.url,
  });

  factory AlbumArtist.fromJson(Map<String, dynamic> json) {
    String? resolvedAvatar;
    if (json['image'] is List) {
      final imgList = json['image'] as List;
      final hq = imgList.firstWhereOrNull(
        (e) => e is Map && (e['quality']?.toString() == '500x500' || e['quality']?.toString() == '150x150'),
      ) ?? imgList.lastOrNull;
      if (hq is Map && hq['url'] != null) {
        resolvedAvatar = hq['url'].toString();
      }
    } else if (json['image'] is String) {
      resolvedAvatar = json['image'];
    } else if (json['image_url'] is String) {
      resolvedAvatar = json['image_url'];
    }

    return AlbumArtist(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      avatarUrl: resolvedAvatar,
      type: json['type']?.toString() ?? 'artist',
      url: json['url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'role': role,
    'avatar_url': avatarUrl,
    'type': type,
    'url': url,
  };
}

class AlbumDetail {
  final String id;
  final String name;
  final String? description;
  final String type;
  final String year;
  final int? playCount;
  final String language;
  final bool explicitContent;
  final String? url;
  final int songCount;
  final List<AlbumArtist> primaryArtists;
  final List<AlbumArtist> featuredArtists;
  final List<AlbumArtist> allArtists;
  final String? imageUrl;
  final List<Music> songs;
  final List<Map<String, dynamic>> rawSongs;

  const AlbumDetail({
    required this.id,
    required this.name,
    this.description,
    this.type = 'album',
    required this.year,
    this.playCount,
    required this.language,
    this.explicitContent = false,
    this.url,
    required this.songCount,
    this.primaryArtists = const [],
    this.featuredArtists = const [],
    this.allArtists = const [],
    this.imageUrl,
    this.songs = const [],
    this.rawSongs = const [],
  });

  factory AlbumDetail.fromJson(Map<String, dynamic> json) {
    // 1. Resolve High-Res Artwork
    String? resolvedImg;
    if (json['image'] is List) {
      final imgList = json['image'] as List;
      final hq = imgList.firstWhereOrNull(
        (e) => e is Map && (e['quality']?.toString() == '500x500' || e['quality']?.toString() == '150x150'),
      ) ?? imgList.lastOrNull;
      if (hq is Map && hq['url'] != null) {
        resolvedImg = hq['url'].toString();
      }
    } else if (json['image_url'] is String) {
      resolvedImg = json['image_url'];
    } else if (json['image'] is String) {
      resolvedImg = json['image'];
    }

    // 2. Parse Artists Maps
    final primary = <AlbumArtist>[];
    final featured = <AlbumArtist>[];
    final all = <AlbumArtist>[];

    if (json['artists'] is Map) {
      final artistsMap = json['artists'] as Map;
      if (artistsMap['primary'] is List) {
        for (final item in artistsMap['primary']) {
          if (item is Map<String, dynamic>) {
            primary.add(AlbumArtist.fromJson(item));
          }
        }
      }
      if (artistsMap['featured'] is List) {
        for (final item in artistsMap['featured']) {
          if (item is Map<String, dynamic>) {
            featured.add(AlbumArtist.fromJson(item));
          }
        }
      }
      if (artistsMap['all'] is List) {
        for (final item in artistsMap['all']) {
          if (item is Map<String, dynamic>) {
            all.add(AlbumArtist.fromJson(item));
          }
        }
      }
    }

    // 3. Parse Songs
    final songList = <Music>[];
    final rawSongList = <Map<String, dynamic>>[];

    if (json['songs'] is List) {
      for (final raw in json['songs']) {
        if (raw is Map) {
          final rawMap = Map<String, dynamic>.from(raw);
          rawSongList.add(rawMap);
          try {
            songList.add(Music.fromJson(rawMap));
          } catch (_) {}
        }
      }
    }

    final rawYear = json['year']?.toString() ?? '';
    final rawLanguage = json['language']?.toString() ?? 'en';
    final parsedSongCount = json['songCount'] is int
        ? json['songCount'] as int
        : (int.tryParse(json['songCount']?.toString() ?? '') ?? songList.length);

    return AlbumDetail(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? json['title']?.toString() ?? 'Unknown Album',
      description: json['description']?.toString(),
      type: json['type']?.toString() ?? 'album',
      year: rawYear,
      playCount: json['playCount'] is num ? (json['playCount'] as num).toInt() : null,
      language: rawLanguage,
      explicitContent: json['explicitContent'] == true,
      url: json['url']?.toString(),
      songCount: parsedSongCount,
      primaryArtists: primary.isNotEmpty ? primary : all,
      featuredArtists: featured,
      allArtists: all.isNotEmpty ? all : primary,
      imageUrl: resolvedImg,
      songs: songList,
      rawSongs: rawSongList,
    );
  }

  // ── Display & Audio Helpers ──

  String get displayTitle => name;

  String get displayYear => year;

  String get displayArtists {
    if (primaryArtists.isNotEmpty) {
      return primaryArtists.map((a) => a.name).join(', ');
    }
    if (allArtists.isNotEmpty) {
      return allArtists.map((a) => a.name).join(', ');
    }
    return '';
  }

  String get displayLanguage {
    if (language.isEmpty) return 'English';
    return '${language[0].toUpperCase()}${language.substring(1)}';
  }

  int get totalDurationSeconds => songs.fold(0, (sum, s) => sum + s.duration);

  String get formattedTotalDuration {
    final totalSec = totalDurationSeconds;
    if (totalSec <= 0) return '';
    final min = totalSec ~/ 60;
    final sec = totalSec % 60;
    if (min >= 60) {
      final hrs = min ~/ 60;
      final remMin = min % 60;
      return '$hrs hr $remMin min';
    }
    return '$min min $sec sec';
  }

  /// Converts the album tracklist into MediaItems with intact download URLs
  List<MediaItem> toMediaItems([String? locale]) {
    final items = <MediaItem>[];
    for (int i = 0; i < songs.length; i++) {
      final song = songs[i];
      final rawSong = i < rawSongs.length ? rawSongs[i] : null;
      final rawUrls = rawSong?['downloadUrl'] ?? rawSong?['download_url'] ?? rawSong?['download_urls'];
      items.add(musicToMediaItem(song, locale, rawUrls));
    }
    return items;
  }
}
