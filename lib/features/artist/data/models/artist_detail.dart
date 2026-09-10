import 'package:audio_service/audio_service.dart';
import 'package:collection/collection.dart';
import 'package:rhythm_flutter/core/services/media_item_mapper.dart';
import 'package:rhythm_flutter/features/home/data/models/music.dart';
import 'package:rhythm_flutter/features/playlist/data/models/playlist_detail.dart';

class ArtistBioItem {
  final String title;
  final String text;
  final int sequence;

  const ArtistBioItem({
    required this.title,
    required this.text,
    this.sequence = 0,
  });

  factory ArtistBioItem.fromJson(Map<String, dynamic> json) {
    return ArtistBioItem(
      title: json['title']?.toString() ?? '',
      text: _cleanBioText(json['text']?.toString() ?? ''),
      sequence: json['sequence'] is int ? json['sequence'] as int : 0,
    );
  }

  static String _cleanBioText(String input) {
    return input
        .replaceAll(r'\r\n', '\n')
        .replaceAll(r'\n', '\n')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('â€˜', "'")
        .replaceAll('â€™', "'")
        .replaceAll('â€œ', '"')
        .replaceAll('â€\u009d', '"')
        .replaceAll('â€“', '–')
        .trim();
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'text': text,
    'sequence': sequence,
  };
}

class ArtistAlbum {
  final String id;
  final String name;
  final String? description;
  final String? year;
  final String language;
  final bool explicitContent;
  final String? url;
  final int songCount;
  final String? imageUrl;

  const ArtistAlbum({
    required this.id,
    required this.name,
    this.description,
    this.year,
    this.language = 'hindi',
    this.explicitContent = false,
    this.url,
    this.songCount = 0,
    this.imageUrl,
  });

  factory ArtistAlbum.fromJson(Map<String, dynamic> json) {
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

    return ArtistAlbum(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? json['title']?.toString() ?? 'Unknown Album',
      description: json['description']?.toString(),
      year: json['year']?.toString(),
      language: json['language']?.toString() ?? '',
      explicitContent: json['explicitContent'] == true,
      url: json['url']?.toString(),
      songCount: json['songCount'] is int
          ? json['songCount'] as int
          : (int.tryParse(json['songCount']?.toString() ?? '') ?? 0),
      imageUrl: resolvedImg,
    );
  }

  String get displaySubtitle {
    final parts = <String>[];
    if (year != null && year!.isNotEmpty) parts.add(year!);
    if (songCount > 0) parts.add('$songCount ${songCount == 1 ? "Song" : "Songs"}');
    if (language.isNotEmpty) parts.add(language[0].toUpperCase() + language.substring(1));
    return parts.join(' • ');
  }
}

class ArtistDetail {
  final String id;
  final String name;
  final String? url;
  final String type;
  final int? followerCount;
  final int? fanCount;
  final bool isVerified;
  final String? dominantLanguage;
  final String? dominantType;
  final List<ArtistBioItem> bio;
  final String? dob;
  final String? wiki;
  final List<String> availableLanguages;
  final bool isRadioPresent;
  final String? imageUrl;
  final List<Music> topSongs;
  final List<Map<String, dynamic>> rawTopSongs;
  final List<ArtistAlbum> topAlbums;
  final List<ArtistAlbum> singles;
  final List<PlaylistArtist> similarArtists;

  const ArtistDetail({
    required this.id,
    required this.name,
    this.url,
    this.type = 'artist',
    this.followerCount,
    this.fanCount,
    this.isVerified = false,
    this.dominantLanguage,
    this.dominantType,
    this.bio = const [],
    this.dob,
    this.wiki,
    this.availableLanguages = const [],
    this.isRadioPresent = false,
    this.imageUrl,
    this.topSongs = const [],
    this.rawTopSongs = const [],
    this.topAlbums = const [],
    this.singles = const [],
    this.similarArtists = const [],
  });

  factory ArtistDetail.fromJson(Map<String, dynamic> json) {
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

    // 2. Parse Bios
    final bioList = <ArtistBioItem>[];
    if (json['bio'] is List) {
      for (final item in json['bio']) {
        if (item is Map<String, dynamic>) {
          bioList.add(ArtistBioItem.fromJson(item));
        }
      }
    }

    // 3. Parse Top Songs
    final songList = <Music>[];
    final rawSongList = <Map<String, dynamic>>[];
    final rawSongsSource = json['topSongs'] ?? json['songs'];
    if (rawSongsSource is List) {
      for (final raw in rawSongsSource) {
        if (raw is Map) {
          final rawMap = Map<String, dynamic>.from(raw);
          rawSongList.add(rawMap);
          try {
            songList.add(Music.fromJson(rawMap));
          } catch (_) {}
        }
      }
    }

    // 4. Parse Top Albums
    final albumList = <ArtistAlbum>[];
    final rawAlbumsSource = json['topAlbums'] ?? json['albums'];
    if (rawAlbumsSource is List) {
      for (final raw in rawAlbumsSource) {
        if (raw is Map<String, dynamic>) {
          albumList.add(ArtistAlbum.fromJson(raw));
        }
      }
    }

    // 5. Parse Singles
    final singlesList = <ArtistAlbum>[];
    if (json['singles'] is List) {
      for (final raw in json['singles']) {
        if (raw is Map<String, dynamic>) {
          singlesList.add(ArtistAlbum.fromJson(raw));
        }
      }
    }

    // 6. Parse Similar Artists
    final similarList = <PlaylistArtist>[];
    if (json['similarArtists'] is List) {
      for (final raw in json['similarArtists']) {
        if (raw is Map<String, dynamic>) {
          similarList.add(PlaylistArtist.fromJson(raw));
        }
      }
    }

    // Follower / Fan counts
    int? parsedFollowers;
    if (json['followerCount'] is num) {
      parsedFollowers = (json['followerCount'] as num).toInt();
    } else if (json['followerCount'] != null) {
      parsedFollowers = int.tryParse(json['followerCount'].toString());
    }

    int? parsedFans;
    if (json['fanCount'] is num) {
      parsedFans = (json['fanCount'] as num).toInt();
    } else if (json['fanCount'] != null) {
      parsedFans = int.tryParse(json['fanCount'].toString());
    }

    // Available Languages
    final languages = <String>[];
    if (json['availableLanguages'] is List) {
      for (final lang in json['availableLanguages']) {
        if (lang != null && lang.toString().isNotEmpty) {
          languages.add(lang.toString());
        }
      }
    }

    return ArtistDetail(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown Artist',
      url: json['url']?.toString(),
      type: json['type']?.toString() ?? 'artist',
      followerCount: parsedFollowers,
      fanCount: parsedFans,
      isVerified: json['isVerified'] == true,
      dominantLanguage: json['dominantLanguage']?.toString(),
      dominantType: json['dominantType']?.toString(),
      bio: bioList,
      dob: json['dob']?.toString(),
      wiki: json['wiki']?.toString(),
      availableLanguages: languages,
      isRadioPresent: json['isRadioPresent'] == true,
      imageUrl: resolvedImg,
      topSongs: songList,
      rawTopSongs: rawSongList,
      topAlbums: albumList,
      singles: singlesList,
      similarArtists: similarList,
    );
  }

  // ── Display & Audio Helpers ──

  String get displayTitle => name;

  String get formattedFollowers {
    final count = followerCount ?? fanCount;
    if (count == null || count <= 0) return '';
    if (count >= 1000000) {
      final millions = count / 1000000;
      return '${millions.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}M Followers';
    } else if (count >= 1000) {
      final thousands = count / 1000;
      return '${thousands.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}K Followers';
    }
    return '$count Followers';
  }

  String get displayDominantType {
    if (dominantType == null || dominantType!.isEmpty) return 'Artist';
    return '${dominantType![0].toUpperCase()}${dominantType!.substring(1)}';
  }

  String get displayDominantLanguage {
    if (dominantLanguage == null || dominantLanguage!.isEmpty) return '';
    return '${dominantLanguage![0].toUpperCase()}${dominantLanguage!.substring(1)}';
  }

  /// Converts top songs into MediaItems for playback
  List<MediaItem> toMediaItems([String? locale]) {
    final items = <MediaItem>[];
    for (int i = 0; i < topSongs.length; i++) {
      final song = topSongs[i];
      final rawSong = i < rawTopSongs.length ? rawTopSongs[i] : null;
      final rawUrls = rawSong?['downloadUrl'] ?? rawSong?['download_url'] ?? rawSong?['download_urls'];
      items.add(musicToMediaItem(song, locale, rawUrls));
    }
    return items;
  }
}
