import 'package:audio_service/audio_service.dart';
import 'package:rhythm_flutter/core/services/audio_quality_service.dart';
import 'package:rhythm_flutter/features/home/data/models/music.dart';
import 'package:rhythm_flutter/features/home/data/models/home_feed.dart';

/// Converts a [Music] domain model into an [audio_service.MediaItem].
///
/// Centralised here because it's called from 4+ places:
/// audio_provider, song_detail_screen, search_tab, related songs.
Uri? _safeParseArtUri(String? url) {
  if (url == null || url.trim().isEmpty) return null;
  final clean = url.trim();
  if (!clean.startsWith('http://') && !clean.startsWith('https://')) return null;
  try {
    final uri = Uri.parse(clean);
    return (uri.hasScheme && uri.host.isNotEmpty) ? uri : null;
  } catch (_) {
    return null;
  }
}

MediaItem musicToMediaItem(Music music, [String? locale, dynamic downloadUrls]) {
  final rawUrls = downloadUrls ?? (music.toJson()['download_urls'] ?? music.toJson()['downloadUrl']);
  final parsedQualities = AdaptiveAudioQualitySelector.parseDownloadUrls(rawUrls);
  final rawId = music.rawStringId;
  final cleanRawId = rawId.trim();
  final jsonMap = music.toJson();
  final ytUrl = music.youtubeUrl ?? jsonMap['youtube_url']?.toString() ?? jsonMap['url']?.toString();
  final isYt = music.isYouTubeSong ||
      (ytUrl != null &&
          (ytUrl.contains('youtube.com') ||
              ytUrl.contains('youtu.be') ||
              ytUrl.contains('music.youtube.com'))) ||
      RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(cleanRawId) ||
      cleanRawId.startsWith('yt_');
  final resolvedYtUrl = ytUrl ?? (isYt ? 'https://music.youtube.com/watch?v=$cleanRawId' : null);

  return MediaItem(
    id: rawId,
    title: music.getDisplayTitle(locale ?? 'en'),
    artist: music.getDisplayArtists(locale ?? 'en'),
    album: music.getDisplayAlbum(locale ?? 'en') ?? '',
    duration: Duration(seconds: music.duration),
    artUri: _safeParseArtUri(music.thumbUrl),
    extras: {
      'raw_id': rawId,
      'audio_url': music.audioUrl,
      'youtube_url': resolvedYtUrl,
      'is_youtube': isYt,
      'duration_formatted': music.durationFormatted,
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
  final rawUrls = downloadUrls ?? item.downloadUrls;
  final parsedQualities = AdaptiveAudioQualitySelector.parseDownloadUrls(rawUrls);
  final cleanId = item.id.trim();
  final isYt = (item.youtubeUrl != null &&
          (item.youtubeUrl!.contains('youtube.com') ||
              item.youtubeUrl!.contains('youtu.be') ||
              item.youtubeUrl!.contains('music.youtube.com'))) ||
      RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(cleanId) ||
      cleanId.startsWith('yt_');
  final ytUrl = item.youtubeUrl ?? (isYt ? 'https://music.youtube.com/watch?v=$cleanId' : null);

  return MediaItem(
    id: item.id,
    title: item.displayTitle,
    artist: item.displaySubtitle,
    album: item.isAlbum ? item.displayTitle : '',
    duration: item.duration != null ? Duration(seconds: item.duration!) : Duration.zero,
    artUri: _safeParseArtUri(item.displayImage),
    extras: {
      'raw_id': item.id,
      'type': item.type,
      'language': item.language,
      'image_url': item.displayImage,
      'audio_url': item.audioUrl,
      'youtube_url': ytUrl,
      'is_youtube': isYt,
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

