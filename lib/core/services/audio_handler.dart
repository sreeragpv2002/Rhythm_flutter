import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import 'package:rhythm_flutter/core/services/storage_service.dart';
import 'package:rhythm_flutter/core/constants/app_constants.dart';

/// Custom AudioHandler that manages playback with just_audio
/// and integrates with audio_service for background + notification controls.
class RhythmAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  final String _baseStreamUrl;
  final StorageService _storage;

  RhythmAudioHandler(this._baseStreamUrl, this._storage) {
    // Broadcast playback state changes
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);

    // Listen for current index changes to update mediaItem
    _player.currentIndexStream.listen((index) {
      if (index != null && queue.value.isNotEmpty && index < queue.value.length) {
        mediaItem.add(queue.value[index]);
      }
    });

    // Listen for when a song completes to auto-play next
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        skipToNext();
      }
    });
  }

  AudioPlayer get player => _player;

  /// Build the stream URL for a music ID with auth header
  Map<String, String> _getAuthHeaders() {
    final token = _storage.accessToken;
    if (token != null) {
      return {'Authorization': 'Bearer $token'};
    }
    return {};
  }

  /// Load and play a list of songs, starting at the given index
  Future<void> loadPlaylist(List<MediaItem> items, {int initialIndex = 0}) async {
    debugPrint('AudioHandler: loadPlaylist called with ${items.length} items, initialIndex: $initialIndex');
    // Update the queue index
    queue.add(items);

    final headers = _getAuthHeaders();
    debugPrint('AudioHandler: Auth headers retrieved: ${headers.isNotEmpty}');

    // Create audio sources from the queue
    final audioSources = items.map((item) => _createAudioSource(item, headers)).toList();
    debugPrint('AudioHandler: ${audioSources.length} audio sources created');

    // Set up the playlist in just_audio
    try {
      debugPrint('AudioHandler: Setting audio sources in player');
      await _player.setAudioSources(audioSources, initialIndex: initialIndex);
      debugPrint('AudioHandler: Starting playback');
      await _player.play();
      debugPrint('AudioHandler: Playback started successfully');
    } catch (e) {
      debugPrint('AudioHandler: Error during loadPlaylist/play: $e');
    }
  }

  /// Append more items to the end of the current queue
  Future<void> addItemsToQueue(List<MediaItem> items) async {
    final currentQueue = queue.value;
    final newQueue = [...currentQueue, ...items];
    queue.add(newQueue);

    final headers = _getAuthHeaders();
    final newSources = items.map((item) => _createAudioSource(item, headers)).toList();

    // just_audio's current playlist is accessible and mutable
    final sequence = _player.sequence ?? [];
    await _player.setAudioSources([...sequence, ...newSources], initialIndex: _player.currentIndex);
  }

  AudioSource _createAudioSource(MediaItem item, Map<String, String> headers) {
    final directUrl = item.extras?['audio_url'] as String?;
    String url = directUrl ?? '$_baseStreamUrl/music/${item.id}/stream/';
    
    // Handle relative URLs
    if (!url.startsWith('http')) {
      // Extract the origin from _baseStreamUrl (e.g., https://dev.example.com)
      final uri = Uri.parse(_baseStreamUrl);
      final origin = '${uri.scheme}://${uri.host}${uri.hasPort ? ":${uri.port}" : ""}';
      
      if (url.startsWith('/')) {
        url = '$origin$url';
      } else {
        url = '$origin/$url';
      }
    }

    debugPrint('AudioHandler: Resolved URL for ${item.id}: $url');

    // Only add auth headers if it's our API
    final useHeaders = url.contains('pythonanywhere.com') || url.contains(Uri.parse(_baseStreamUrl).host) ? headers : null;

    return AudioSource.uri(
      Uri.parse(url),
      headers: useHeaders,
      tag: item,
    );
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= queue.value.length) return;
    await _player.seek(Duration.zero, index: index);
    await _player.play();
  }

  @override
  Future<void> skipToNext() async {
    if (_player.hasNext) {
      await _player.seekToNext();
      await _player.play();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_player.hasPrevious) {
      await _player.seekToPrevious();
      await _player.play();
    }
  }

  /// Update localized metadata for all items in the queue
  void updateQueueMetadata(String locale) {
    final currentQueue = queue.value;
    if (currentQueue.isEmpty) return;

    final updatedQueue = currentQueue.map((item) {
      final titles = item.extras?['titles'] as Map<dynamic, dynamic>?;
      final artists = item.extras?['artist_names'] as List<dynamic>?;
      final albums = item.extras?['album_titles'] as Map<dynamic, dynamic>?;

      String? newTitle;
      if (titles != null) {
        newTitle = titles[locale]?.toString() ?? titles['en']?.toString() ?? item.title;
      }

      String? newArtist;
      if (artists != null) {
        newArtist = artists.map((a) {
          if (a is Map) return a[locale]?.toString() ?? a['en']?.toString() ?? a.values.firstOrNull?.toString() ?? '';
          return a.toString();
        }).join(', ');
      }

      String? newAlbum;
      if (albums != null) {
        newAlbum = albums[locale]?.toString() ?? albums['en']?.toString() ?? albums.values.firstOrNull?.toString();
      }

      return item.copyWith(
        title: newTitle ?? item.title,
        artist: newArtist ?? item.artist,
        album: newAlbum ?? item.album,
      );
    }).toList();

    queue.add(updatedQueue);

    // Update the current item as well
    final currentIndex = _player.currentIndex;
    if (currentIndex != null && currentIndex < updatedQueue.length) {
      mediaItem.add(updatedQueue[currentIndex]);
    }
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    return super.stop();
  }

  /// Transform just_audio events into audio_service PlaybackState
  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
        MediaControl.stop,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }

  /// Combined stream of position, buffered position, and duration
  Stream<PositionData> get positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
        _player.positionStream,
        _player.bufferedPositionStream,
        _player.durationStream,
        (position, bufferedPosition, duration) => PositionData(
          position,
          bufferedPosition,
          duration ?? Duration.zero,
        ),
      );
}

/// Helper class to bundle position data
class PositionData {
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;

  PositionData(this.position, this.bufferedPosition, this.duration);
}
