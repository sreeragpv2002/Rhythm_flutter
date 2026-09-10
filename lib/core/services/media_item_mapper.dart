import 'package:audio_service/audio_service.dart';
import 'package:rhythm_flutter/core/services/audio_quality_service.dart';
import 'package:rhythm_flutter/features/home/data/models/music.dart';
import 'package:rhythm_flutter/features/home/data/models/home_feed.dart';

/// Converts a [Music] domain model into an [audio_service.MediaItem].
///
/// Centralised here because it's called from 4+ places:
/// audio_provider, song_detail_screen, search_tab, related songs.
MediaItem musicToMediaItem(Music music, [String? locale, dynamic downloadUrls]) {
  final rawUrls = downloadUrls ?? (music.toJson()['download_urls'] ?? music.toJson()['downloadUrl']);
  final parsedQualities = AdaptiveAudioQualitySelector.parseDownloadUrls(rawUrls);
  final rawId = music.rawStringId;

  return MediaItem(
    id: rawId,
    title: music.getDisplayTitle(locale ?? 'en'),
    artist: music.getDisplayArtists(locale ?? 'en'),
    album: music.getDisplayAlbum(locale ?? 'en') ?? '',
    duration: Duration(seconds: music.duration),
    artUri: music.thumbUrl != null ? Uri.parse(music.thumbUrl!) : null,
    extras: {
      'raw_id': rawId,
      'audio_url': music.audioUrl,
      'titles': music.titles,
      'artist_names': music.artistNames,
      'album_titles': music.albumTitles,
      'is_favorited': music.isFavorited || music.isFavorite,
      if (parsedQualities.isNotEmpty)
        'download_urls': parsedQualities.map((e) => e.toJson()).toList(),
    },
  );
}

/// Converts a [HomeItem] into an [audio_service.MediaItem] for playback.
MediaItem homeItemToMediaItem(HomeItem item, [dynamic downloadUrls]) {
  final parsedQualities = AdaptiveAudioQualitySelector.parseDownloadUrls(downloadUrls);

  return MediaItem(
    id: item.id,
    title: item.displayTitle,
    artist: item.displaySubtitle,
    album: item.isAlbum ? item.displayTitle : '',
    artUri: item.displayImage != null ? Uri.parse(item.displayImage!) : null,
    extras: {
      'type': item.type,
      'language': item.language,
      'image_url': item.displayImage,
      if (parsedQualities.isNotEmpty)
        'download_urls': parsedQualities.map((e) => e.toJson()).toList(),
    },
  );
}

/// Converts a raw Song details map (e.g. from GET /api/v1/songs/{id}) into a [MediaItem]
MediaItem mediaItemFromSongDetails(Map<String, dynamic> data, [String? locale]) {
  final music = Music.fromJson(data);
  final rawUrls = data['downloadUrl'] ?? data['download_url'] ?? data['download_urls'];
  return musicToMediaItem(music, locale, rawUrls);
}

