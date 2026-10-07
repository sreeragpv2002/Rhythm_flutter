import 'package:rhythm_flutter/features/home/data/models/music.dart';

/// Home feed models representing the new Home API response.
class HomeItem {
  final String id;
  final String name;
  final String title;
  final String? image;
  final String? imageUrl;
  final String type; // 'song', 'playlist', 'album', 'artist', 'language'
  final String? subtitle;
  final String? language;
  final String? audioUrl;
  final dynamic downloadUrls;
  final String? youtubeUrl;
  final int? duration;

  const HomeItem({
    required this.id,
    required this.name,
    required this.title,
    this.image,
    this.imageUrl,
    required this.type,
    this.subtitle,
    this.language,
    this.audioUrl,
    this.downloadUrls,
    this.youtubeUrl,
    this.duration,
  });

  factory HomeItem.fromJson(Map<String, dynamic> json) {
    final rawDownload = json['download_urls'] ?? json['downloadUrl'] ?? json['download_url'];
    String? audio = json['audio_url']?.toString() ?? json['audioUrl']?.toString();
    if (audio == null && rawDownload is List && rawDownload.isNotEmpty) {
      final last = rawDownload.last;
      if (last is Map && last['url'] != null) {
        audio = last['url'].toString();
      }
    }

    int? dur;
    if (json['duration'] is num) {
      dur = (json['duration'] as num).toInt();
    } else if (json['duration'] != null) {
      dur = int.tryParse(json['duration'].toString());
    }

    return HomeItem(
      id: json['id']?.toString() ?? '',
      name: _unescapeHtml(json['name']?.toString() ?? ''),
      title: _unescapeHtml(json['title']?.toString() ?? json['name']?.toString() ?? ''),
      image: json['image']?.toString(),
      imageUrl: json['image_url']?.toString(),
      type: json['type']?.toString() ?? 'song',
      subtitle: json['subtitle'] != null ? _unescapeHtml(json['subtitle'].toString()) : null,
      language: json['language']?.toString(),
      audioUrl: audio,
      downloadUrls: rawDownload,
      youtubeUrl: json['youtube_url']?.toString() ?? json['url']?.toString(),
      duration: dur,
    );
  }

  static String _unescapeHtml(String text) {
    return text
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&#039;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .trim();
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'title': title,
    'image': image,
    'image_url': imageUrl,
    'type': type,
    'subtitle': subtitle,
    'language': language,
    if (audioUrl != null) 'audio_url': audioUrl,
    if (downloadUrls != null) 'download_urls': downloadUrls,
    if (youtubeUrl != null) 'youtube_url': youtubeUrl,
    if (duration != null) 'duration': duration,
  };

  String get displayTitle => title.isNotEmpty ? title : name;
  String? get displayImage => imageUrl ?? image;
  String get displaySubtitle {
    if (subtitle != null && subtitle!.isNotEmpty) return subtitle!;
    switch (type) {
      case 'artist':
        return 'Artist';
      case 'playlist':
        return 'Playlist';
      case 'album':
        return 'Album';
      case 'song':
        return language != null && language!.isNotEmpty ? language!.toUpperCase() : 'Song';
      default:
        return '';
    }
  }

  bool get isSong => type == 'song';
  bool get isArtist => type == 'artist';
  bool get isAlbum => type == 'album';
  bool get isPlaylist => type == 'playlist';
  bool get isLanguage => type == 'language';

  bool get isYouTubeItem {
    final yUrl = youtubeUrl;
    if (yUrl != null &&
        (yUrl.contains('youtube.com') ||
            yUrl.contains('youtu.be') ||
            yUrl.contains('music.youtube.com'))) {
      return true;
    }
    final cleanId = id.trim();
    return RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(cleanId) || cleanId.startsWith('yt_');
  }

  // Compatibility helpers with legacy Music interface
  int get numericId {
    final parsed = int.tryParse(id);
    final res = parsed ?? id.hashCode.abs();
    musicRawIdMap[res] = id;
    return res;
  }

  String getDisplayTitle([String? locale]) => displayTitle;
  String getDisplayArtists([String? locale]) => displaySubtitle;
  String? get thumbUrl => displayImage;
}

class HomeSection {
  final String title;
  final String slug;
  final List<HomeItem> items;

  const HomeSection({
    required this.title,
    required this.slug,
    required this.items,
  });

  factory HomeSection.fromJson(Map<String, dynamic> json) {
    return HomeSection(
      title: json['title']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => HomeItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'slug': slug,
    'items': items.map((e) => e.toJson()).toList(),
  };

  String getDisplayTitle(String locale) => title;
}

class HomeFeed {
  final List<String> userLanguages;
  final List<HomeItem> languages;
  final List<HomeItem> recentPlays;
  final List<HomeItem> trendingSongs;
  final List<HomeItem> featuredPlaylists;
  final List<HomeItem> trendingAlbums;
  final List<HomeItem> topArtists;

  const HomeFeed({
    this.userLanguages = const [],
    this.languages = const [],
    this.recentPlays = const [],
    this.trendingSongs = const [],
    this.featuredPlaylists = const [],
    this.trendingAlbums = const [],
    this.topArtists = const [],
  });

  factory HomeFeed.fromJson(Map<String, dynamic> json) {
    final data = json.containsKey('data') && json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    return HomeFeed(
      userLanguages: (data['user_languages'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      languages: (data['languages'] as List<dynamic>?)
              ?.map((e) => HomeItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      recentPlays: (data['recent_plays'] as List<dynamic>?)
              ?.map((e) => HomeItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      trendingSongs: (data['trending_songs'] as List<dynamic>?)
              ?.map((e) => HomeItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      featuredPlaylists: (data['featured_playlists'] as List<dynamic>?)
              ?.map((e) => HomeItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      trendingAlbums: (data['trending_albums'] as List<dynamic>?)
              ?.map((e) => HomeItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      topArtists: (data['top_artists'] as List<dynamic>?)
              ?.map((e) => HomeItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'user_languages': userLanguages,
    'languages': languages.map((e) => e.toJson()).toList(),
    'recent_plays': recentPlays.map((e) => e.toJson()).toList(),
    'trending_songs': trendingSongs.map((e) => e.toJson()).toList(),
    'featured_playlists': featuredPlaylists.map((e) => e.toJson()).toList(),
    'trending_albums': trendingAlbums.map((e) => e.toJson()).toList(),
    'top_artists': topArtists.map((e) => e.toJson()).toList(),
  };

  /// Returns the sections to be displayed on the Home screen in order.
  /// Per requirements:
  /// - Language section is omitted for now ("no need to implement language section now").
  /// - "Recently Played" is only included if data is available ("set recent play if data availabele").
  List<HomeSection> get sections {
    final list = <HomeSection>[];

    if (recentPlays.isNotEmpty) {
      list.add(HomeSection(
        title: 'Recently Played',
        slug: 'recent_plays',
        items: recentPlays,
      ));
    }

    if (trendingSongs.isNotEmpty) {
      list.add(HomeSection(
        title: 'Trending Songs',
        slug: 'trending_songs',
        items: trendingSongs,
      ));
    }

    if (featuredPlaylists.isNotEmpty) {
      list.add(HomeSection(
        title: 'Featured Playlists',
        slug: 'featured_playlists',
        items: featuredPlaylists,
      ));
    }

    if (trendingAlbums.isNotEmpty) {
      list.add(HomeSection(
        title: 'Trending Albums',
        slug: 'trending_albums',
        items: trendingAlbums,
      ));
    }

    if (topArtists.isNotEmpty) {
      list.add(HomeSection(
        title: 'Top Artists',
        slug: 'top_artists',
        items: topArtists,
      ));
    }

    return list;
  }

  Map<String, HomeItem> get itemMap {
    final map = <String, HomeItem>{};
    for (final item in [
      ...recentPlays,
      ...trendingSongs,
      ...featuredPlaylists,
      ...trendingAlbums,
      ...topArtists,
    ]) {
      map[item.id] = item;
    }
    return map;
  }

  HomeItem? getItemById(dynamic id) => itemMap[id.toString()];
  dynamic getMusicById(dynamic id) => getItemById(id);

  static HomeFeed initialFallback() {
    return const HomeFeed(
      userLanguages: ['malayalam', 'tamil', 'english'],
      recentPlays: [],
      trendingSongs: [
        HomeItem(
          id: 'zAiIgYOH4Ys',
          name: 'KALYANI (Remix)',
          title: 'KALYANI (Remix)',
          image: 'https://yt3.googleusercontent.com/naKgO_9vvIczuf7Vq1llQyRAQOOW898kBZN3pio-Bkbfcmdu3Gv14_ivEBZiHAow8VbPEq1bhO0j2DU=w544-h544-l90-rj',
          imageUrl: 'https://yt3.googleusercontent.com/naKgO_9vvIczuf7Vq1llQyRAQOOW898kBZN3pio-Bkbfcmdu3Gv14_ivEBZiHAow8VbPEq1bhO0j2DU=w544-h544-l90-rj',
          type: 'song',
          subtitle: 'ARJN, KDS, FIFTY4, Shreya Ghoshal',
          language: 'malayalam',
          youtubeUrl: 'https://music.youtube.com/watch?v=zAiIgYOH4Ys',
        ),
        HomeItem(
          id: 'BmRX2g6-iQI',
          name: 'Radhimaa [From "Think Indie"] (feat. Sai Smriti)',
          title: 'Radhimaa [From "Think Indie"] (feat. Sai Smriti)',
          image: 'https://yt3.googleusercontent.com/YpHZO1DBcGPbgywaeckHbkkiI-b4OetQDJnQtCM--usqBrKljB-9uXax23i3hHI-PiTlyyHLBdYScSeGRQ=w544-h544-l90-rj',
          imageUrl: 'https://yt3.googleusercontent.com/YpHZO1DBcGPbgywaeckHbkkiI-b4OetQDJnQtCM--usqBrKljB-9uXax23i3hHI-PiTlyyHLBdYScSeGRQ=w544-h544-l90-rj',
          type: 'song',
          subtitle: 'Sai Abhyankkar, Nargis Teji, Asma Teji, Vivek',
          language: 'tamil',
          youtubeUrl: 'https://music.youtube.com/watch?v=BmRX2g6-iQI',
        ),
        HomeItem(
          id: 'NAkQVL61BRI',
          name: 'Raga of Revenge (From "DC")',
          title: 'Raga of Revenge (From "DC")',
          image: 'https://yt3.googleusercontent.com/rfk664Pl2AHH44a0Du2czXg-EhFwgKw_R3K-DEPmSz9zvM-rf4r5izHzB1cqqYuLuVUnszM464q0nml-=w544-h544-l90-rj',
          imageUrl: 'https://yt3.googleusercontent.com/rfk664Pl2AHH44a0Du2czXg-EhFwgKw_R3K-DEPmSz9zvM-rf4r5izHzB1cqqYuLuVUnszM464q0nml-=w544-h544-l90-rj',
          type: 'song',
          subtitle: 'Anirudh Ravichander',
          language: 'tamil',
          youtubeUrl: 'https://music.youtube.com/watch?v=NAkQVL61BRI',
        ),
        HomeItem(
          id: 'S1jo8K4kDJc',
          name: 'Illuminati (From "Aavesham")',
          title: 'Illuminati (From "Aavesham")',
          image: 'https://yt3.googleusercontent.com/RjRPztjAVR2sxLUV-pIK5n0TVvzQcousWmlxLZYJMxTEoJDS7YiB0u0CuJ4qYWSarxqzaOQPoyrmF8Yh4g=w544-h544-l90-rj',
          imageUrl: 'https://yt3.googleusercontent.com/RjRPztjAVR2sxLUV-pIK5n0TVvzQcousWmlxLZYJMxTEoJDS7YiB0u0CuJ4qYWSarxqzaOQPoyrmF8Yh4g=w544-h544-l90-rj',
          type: 'song',
          subtitle: 'Sushin Shyam, Dabzee, Vinayak Sasikumar',
          language: 'malayalam',
          youtubeUrl: 'https://music.youtube.com/watch?v=S1jo8K4kDJc',
        ),
        HomeItem(
          id: '0MQwuGR_tr0',
          name: 'Singari (From "Dude")',
          title: 'Singari (From "Dude")',
          image: 'https://yt3.googleusercontent.com/29o3mo_-5Jn1XP_4cqH4Gmy2OqjBIB3BA2ttjzH7XDqQYjO4F_48nC-IwpN0JKy4bH4csI2y6Dj1Qus=w544-h544-l90-rj',
          imageUrl: 'https://yt3.googleusercontent.com/29o3mo_-5Jn1XP_4cqH4Gmy2OqjBIB3BA2ttjzH7XDqQYjO4F_48nC-IwpN0JKy4bH4csI2y6Dj1Qus=w544-h544-l90-rj',
          type: 'song',
          subtitle: 'Sai Abhyankkar, Pradeep Ranganathan, Sai Smriti',
          language: 'tamil',
          youtubeUrl: 'https://music.youtube.com/watch?v=0MQwuGR_tr0',
        ),
        HomeItem(
          id: 'sVgnd4w315g',
          name: 'Alaakaa Loova (From "OM Chapter 1")',
          title: 'Alaakaa Loova (From "OM Chapter 1")',
          image: 'https://yt3.googleusercontent.com/F_zOOpQrlMOrIT50KDXGX54temlvXtXhWM-9e6TBAxCSP-F_Tt8bxONr5jBN7UwvoCwUifR0xph_QQeX=w544-h544-l90-rj',
          imageUrl: 'https://yt3.googleusercontent.com/F_zOOpQrlMOrIT50KDXGX54temlvXtXhWM-9e6TBAxCSP-F_Tt8bxONr5jBN7UwvoCwUifR0xph_QQeX=w544-h544-l90-rj',
          type: 'song',
          subtitle: 'Sai Abhyankkar, Rokesh',
          language: 'tamil',
          youtubeUrl: 'https://music.youtube.com/watch?v=sVgnd4w315g',
        ),
      ],
      featuredPlaylists: [
        HomeItem(
          id: '1181705742',
          name: 'Malayalam 2000s',
          title: 'Malayalam 2000s',
          image: 'https://c.saavncdn.com/editorial/charts_Malayalam2000s_160867_20240408063713_500x500.jpg',
          imageUrl: 'https://c.saavncdn.com/editorial/charts_Malayalam2000s_160867_20240408063713_500x500.jpg',
          type: 'playlist',
          language: 'malayalam',
        ),
        HomeItem(
          id: '1170578779',
          name: 'Tamil 1990s',
          title: 'Tamil 1990s',
          image: 'https://c.saavncdn.com/editorial/charts_Tamil1990s_190250_20240408062124_500x500.jpg',
          imageUrl: 'https://c.saavncdn.com/editorial/charts_Tamil1990s_190250_20240408062124_500x500.jpg',
          type: 'playlist',
          language: 'tamil',
        ),
        HomeItem(
          id: '63116930',
          name: 'English 2010s',
          title: 'English 2010s',
          image: 'https://c.saavncdn.com/editorial/charts_English2010s_178363_20240408065247_500x500.jpg',
          imageUrl: 'https://c.saavncdn.com/editorial/charts_English2010s_178363_20240408065247_500x500.jpg',
          type: 'playlist',
          language: 'english',
        ),
      ],
      trendingAlbums: [
        HomeItem(
          id: '77189973',
          name: 'KALYANI (Remix)',
          title: 'KALYANI (Remix)',
          image: 'https://c.saavncdn.com/475/KALYANI-Remix-Malayalam-2026-20260622131127-500x500.jpg',
          imageUrl: 'https://c.saavncdn.com/475/KALYANI-Remix-Malayalam-2026-20260622131127-500x500.jpg',
          type: 'album',
          subtitle: 'ARJN, KDS, FIFTY4, Shreya Ghoshal',
          language: 'malayalam',
        ),
        HomeItem(
          id: '41106332',
          name: 'Varisu',
          title: 'Varisu',
          image: 'https://c.saavncdn.com/145/Varisu-Tamil-2022-20221226190213-500x500.jpg',
          imageUrl: 'https://c.saavncdn.com/145/Varisu-Tamil-2022-20221226190213-500x500.jpg',
          type: 'album',
          subtitle: 'Thaman S',
          language: 'tamil',
        ),
      ],
      topArtists: [
        HomeItem(
          id: '22096108',
          name: "Malayalam Monkey's",
          title: "Malayalam Monkey's",
          image: 'https://www.jiosaavn.com/_i/3.0/artist-default-music.png',
          imageUrl: 'https://www.jiosaavn.com/_i/3.0/artist-default-music.png',
          type: 'artist',
          language: 'malayalam',
        ),
        HomeItem(
          id: '458139',
          name: 'Prakash Raj',
          title: 'Prakash Raj',
          image: 'https://c.saavncdn.com/artists/Prakash_Raj_500x500.jpg',
          imageUrl: 'https://c.saavncdn.com/artists/Prakash_Raj_500x500.jpg',
          type: 'artist',
          language: 'tamil',
        ),
      ],
    );
  }
}
