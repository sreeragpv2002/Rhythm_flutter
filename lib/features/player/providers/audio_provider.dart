import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rhythm_flutter/core/services/audio_handler.dart';
import 'package:rhythm_flutter/features/home/data/models/music.dart';
import 'package:rhythm_flutter/features/home/data/repositories/music_repository.dart';
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

/// Fetch details for the currently playing song (including related songs).
final currentMusicDetailsProvider = FutureProvider<Music?>((ref) async {
  final mediaItem = ref.watch(currentMediaItemProvider).value;
  if (mediaItem == null) return null;

  final repository = ref.read(musicRepositoryProvider);
  final music = await repository.getMusicDetails(int.parse(mediaItem.id));

  // Auto-enrich queue with related songs if this is the only track.
  final queue = ref.read(audioHandlerProvider).queue.value;
  if (queue.length <= 1 && music.audioUrl != null) {
    final related = await repository.getRelatedSongs(int.parse(mediaItem.id));
    if (related.isNotEmpty) {
      final relatedMediaItems = related.map((m) => musicToMediaItem(m)).toList();
      ref.read(audioHandlerProvider).addItemsToQueue(relatedMediaItems);
    }
  }

  return music;
});
