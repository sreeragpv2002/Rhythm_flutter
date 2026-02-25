import 'package:audio_service/audio_service.dart';
import 'package:rhythm_flutter/features/home/data/models/music.dart';

/// Converts a [Music] domain model into an [audio_service.MediaItem].
///
/// Centralised here because it's called from 4+ places:
/// audio_provider, song_detail_screen, search_tab, related songs.
MediaItem musicToMediaItem(Music music, [String? locale]) {
  return MediaItem(
    id: music.id.toString(),
    title: music.getDisplayTitle(locale ?? 'en'),
    artist: music.getDisplayArtists(locale ?? 'en'),
    album: music.getDisplayAlbum(locale ?? 'en') ?? '',
    duration: Duration(seconds: music.duration),
    artUri: music.thumbUrl != null ? Uri.parse(music.thumbUrl!) : null,
    extras: {
      'audio_url': music.audioUrl,
      'titles': music.titles,
      'artist_names': music.artistNames,
      'album_titles': music.albumTitles,
    },
  );
}
