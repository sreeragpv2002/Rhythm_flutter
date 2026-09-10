import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rhythm_flutter/core/services/audio_handler.dart';
import 'package:rhythm_flutter/core/services/audio_quality_service.dart';
import 'package:rhythm_flutter/features/home/data/models/music.dart';
import 'package:rhythm_flutter/features/home/data/repositories/music_repository.dart';
import 'package:rhythm_flutter/features/home/providers/favorites_provider.dart';
import 'package:rhythm_flutter/core/services/media_item_mapper.dart';

// Re-export the mapper so existing imports continue to work.
export 'package:rhythm_flutter/core/services/media_item_mapper.dart';

/// Singleton provider for the audio handler — initialized in main.dart
final audioHandlerProvider = Provider<RhythmAudioHandler>((ref) {
  throw UnimplementedError('audioHandlerProvider must be overridden at app startup');
});

/// Current playback state stream.
final playbackStateProvider = StreamProvider<PlaybackState>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.playbackState;
});

/// Current media item stream.
final currentMediaItemProvider = StreamProvider<MediaItem?>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.mediaItem;
});

/// Position data stream (position, buffered, duration).
final positionDataProvider = StreamProvider<PositionData>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.positionDataStream;
});

/// Current queue stream.
final queueProvider = StreamProvider<List<MediaItem>>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.queue;
});

/// Shuffle mode stream.
final shuffleModeProvider = StreamProvider<bool>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.shuffleModeStream;
});

/// Loop mode stream.
final loopModeProvider = StreamProvider<LoopMode>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.loopModeStream;
});

/// List of available download qualities for the currently playing song
final currentSongQualitiesProvider = Provider<List<SongDownloadUrl>>((ref) {
  final mediaItem = ref.watch(currentMediaItemProvider).value;
  if (mediaItem == null) return [];
  final rawUrls = mediaItem.extras?['download_urls'];
  return AdaptiveAudioQualitySelector.parseDownloadUrls(rawUrls);
});

/// Currently selected quality display badge label (e.g. "320 kbps • Auto")
final currentActiveQualityLabelProvider = Provider<String>((ref) {
  final mediaItem = ref.watch(currentMediaItemProvider).value;
  final pref = ref.watch(audioQualityPreferenceProvider);
  final grade = ref.watch(networkSpeedGradeProvider).valueOrNull ?? NetworkSpeedGrade.good;

  if (mediaItem == null) return 'HQ Audio';

  final qualities = AdaptiveAudioQualitySelector.parseDownloadUrls(mediaItem.extras?['download_urls']);
  if (qualities.isNotEmpty) {
    final selected = AdaptiveAudioQualitySelector.resolveQuality(
      availableQualities: qualities,
      preference: pref,
      currentGrade: grade,
    );
    if (selected != null) {
      if (pref == AudioQualityPreference.auto) {
        return '${selected.shortLabel} • Auto';
      }
      return selected.shortLabel;
    }
  }

  final explicit = mediaItem.extras?['selected_quality'] as String?;
  if (explicit != null && explicit.isNotEmpty) return explicit;
  return 'HQ Audio';
});

/// Fetch details for the currently playing song (including related songs).
final currentMusicDetailsProvider = FutureProvider<Music?>((ref) async {
  final mediaItem = ref.watch(currentMediaItemProvider).value;
  if (mediaItem == null) return null;

  final repository = ref.read(musicRepositoryProvider);
  final music = await repository.getMusicDetails(mediaItem.id);

  // Sync favorites state
  ref.read(favoritesProvider.notifier).initFromList([music]);

  // Auto-enrich queue with related songs if this is the only track.
  final queue = ref.read(audioHandlerProvider).queue.value;
  if (queue.length <= 1 && music.audioUrl != null) {
    final related = await repository.getRelatedSongs(mediaItem.id);
    if (related.isNotEmpty) {
      final relatedMediaItems = related.map((m) => musicToMediaItem(m)).toList();
      ref.read(audioHandlerProvider).addItemsToQueue(relatedMediaItems);
      // Also sync favorites from related songs
      ref.read(favoritesProvider.notifier).initFromList(related);
    }
  }

  return music;
});
