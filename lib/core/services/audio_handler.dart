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

    // Log player errors for diagnostics
    _player.playerStateStream.listen(null, onError: (Object e, StackTrace st) {
      debugPrint('AudioHandler: Player stream error: $e');
    });
  }

  AudioPlayer get player => _player;

  // ── Auth headers ──

  Map<String, String> _getAuthHeaders() {
    final token = _storage.accessToken;
    if (token != null) {
      return {'Authorization': 'Bearer $token'};
    }
    return {};
  }

  // ── Playlist loading ──

  /// Load and play a list of songs, starting at the given index.
  Future<void> loadPlaylist(List<MediaItem> items, {int initialIndex = 0}) async {
    debugPrint('AudioHandler: loadPlaylist called with ${items.length} items, initialIndex: $initialIndex');
    queue.add(items);

    final headers = _getAuthHeaders();
    final audioSources = items.map((item) => _createAudioSource(item, headers)).toList();

    try {
      await _player.setAudioSources(audioSources, initialIndex: initialIndex);
      await _player.play();
      debugPrint('AudioHandler: Playback started successfully');
    } on PlayerException catch (e) {
      debugPrint('AudioHandler: PlayerException during loadPlaylist: ${e.message}');
      // Attempt to skip to next track on error
      if (items.length > 1 && initialIndex + 1 < items.length) {
        debugPrint('AudioHandler: Attempting next track after error');
        await _player.seek(Duration.zero, index: initialIndex + 1);
        await _player.play();
      }
    } on PlayerInterruptedException catch (e) {
      debugPrint('AudioHandler: PlayerInterruptedException: $e');
    } catch (e) {
      debugPrint('AudioHandler: Error during loadPlaylist: $e');
    }
  }

  /// Append more items to the end of the current queue.
  Future<void> addItemsToQueue(List<MediaItem> items) async {
    final currentQueue = queue.value;
    final newQueue = [...currentQueue, ...items];
    queue.add(newQueue);

    final headers = _getAuthHeaders();
    final newSources = items.map((item) => _createAudioSource(item, headers)).toList();
    final sequence = _player.sequence ?? [];

    try {
      await _player.setAudioSources(
        [...sequence, ...newSources],
        initialIndex: _player.currentIndex,
      );
    } catch (e) {
      debugPrint('AudioHandler: Error adding items to queue: $e');
    }
  }

  AudioSource _createAudioSource(MediaItem item, Map<String, String> headers) {
    final directUrl = item.extras?['audio_url'] as String?;
    String url = directUrl ?? '$_baseStreamUrl/music/${item.id}/stream/';

    // Handle relative URLs
    if (!url.startsWith('http')) {
      final uri = Uri.parse(_baseStreamUrl);
      final origin = '${uri.scheme}://${uri.host}${uri.hasPort ? ":${uri.port}" : ""}';
      url = url.startsWith('/') ? '$origin$url' : '$origin/$url';
    }

    debugPrint('AudioHandler: Resolved URL for ${item.id}: $url');

    final useHeaders = url.contains(Uri.parse(_baseStreamUrl).host) ? headers : null;

    return AudioSource.uri(
      Uri.parse(url),
      headers: useHeaders,
      tag: item,
    );
  }

  // ── Playback controls ──

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

  // ── Shuffle & Repeat (wired to just_audio) ──

  /// Set shuffle mode. Updates both just_audio and broadcasts.
  Future<void> setShuffleEnabled(bool enabled) async {
    await _player.setShuffleModeEnabled(enabled);
  }

  /// Get current shuffle state.
  bool get shuffleEnabled => _player.shuffleModeEnabled;

  /// Set loop/repeat mode.
  /// 0 = off, 1 = all, 2 = one
  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    final loopMode = switch (repeatMode) {
      AudioServiceRepeatMode.all || AudioServiceRepeatMode.group => LoopMode.all,
      AudioServiceRepeatMode.one => LoopMode.one,
      AudioServiceRepeatMode.none => LoopMode.off,
    };
    await _player.setLoopMode(loopMode);
  }

  /// Get current repeat mode as int (0=off, 1=all, 2=one).
  int get repeatMode => switch (_player.loopMode) {
    LoopMode.all => 1,
    LoopMode.one => 2,
    _ => 0,
  };

  /// Stream of shuffle mode changes.
  Stream<bool> get shuffleModeStream => _player.shuffleModeEnabledStream;

  /// Stream of loop mode changes.
  Stream<LoopMode> get loopModeStream => _player.loopModeStream;

  // ── Metadata ──

  /// Update localized metadata for all items in the queue.
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

    final currentIndex = _player.currentIndex;
    if (currentIndex != null && currentIndex < updatedQueue.length) {
      mediaItem.add(updatedQueue[currentIndex]);
    }
  }

  /// Update favorite status for a specific item in the queue
  void updateMediaItemFavorite(String id, bool isFavorite) {
    final currentQueue = queue.value;
    final index = currentQueue.indexWhere((item) => item.id == id);
    if (index != -1) {
      final item = currentQueue[index];
      final extras = Map<String, dynamic>.from(item.extras ?? {});
      extras['is_favorited'] = isFavorite;
      
      final newItem = item.copyWith(extras: extras);
      final newQueue = List<MediaItem>.from(currentQueue);
      newQueue[index] = newItem;
      
      queue.add(newQueue);
      
      if (mediaItem.value?.id == id) {
        mediaItem.add(newItem);
      }
    }
  }

  // ── Lifecycle ──

  @override
  Future<void> stop() async {
    await _player.stop();
    return super.stop();
  }

  /// Dispose the underlying player. Call when the app is shutting down.
  Future<void> dispose() async {
    await _player.dispose();
  }

  // ── State mapping ──

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

  /// Combined stream of position, buffered position, and duration.
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

/// Helper class to bundle position data.
class PositionData {
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;

  PositionData(this.position, this.bufferedPosition, this.duration);
}
