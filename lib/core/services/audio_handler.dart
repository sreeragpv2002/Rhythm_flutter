import 'package:audio_service/audio_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rxdart/rxdart.dart';
import 'package:rhythm_flutter/core/config/app_config.dart';
import 'package:rhythm_flutter/core/services/audio_quality_service.dart';
import 'package:rhythm_flutter/core/services/storage_service.dart';

/// Custom AudioHandler that manages playback with just_audio
/// and integrates with audio_service for background + notification controls.
class RhythmAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  String _baseStreamUrl;
  final StorageService _storage;
  final NetworkSpeedService _networkSpeedService;

  RhythmAudioHandler(
    this._baseStreamUrl,
    this._storage, [
    NetworkSpeedService? networkSpeedService,
  ]) : _networkSpeedService = networkSpeedService ?? NetworkSpeedService() {
    // Broadcast playback state changes by combining event and state streams.
    // This ensures play/pause changes (which emit in playerStateStream)
    // always trigger a playbackState update for the UI.
    Rx.combineLatest2<PlaybackEvent, PlayerState, PlaybackState>(
      _player.playbackEventStream.startWith(_player.playbackEvent),
      _player.playerStateStream,
      (event, state) => _transformEvent(event),
    ).listen(playbackState.add);

    _initAudioSession();

    // Listen for current index changes to update mediaItem and record recent plays
    _player.currentIndexStream.listen((index) {
      if (index != null && queue.value.isNotEmpty && index < queue.value.length) {
        final item = queue.value[index];
        mediaItem.add(item);
        _recordRecentPlay(item.id);
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

  Future<void> _initAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    
    // Request notification permission on Android 13+ so media controls show in notification shade
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        Permission.notification.request().then((status) {
          debugPrint('AudioHandler: Android notification permission status: $status');
        });
      } catch (e) {
        debugPrint('AudioHandler: Note: error requesting notification permission: $e');
      }
    }

    // Listen for audio interruptions (e.g. phone calls)
    session.interruptionEventStream.listen((event) {
      if (event.begin) {
        switch (event.type) {
          case AudioInterruptionType.duck:
            _player.setVolume(0.5);
            break;
          case AudioInterruptionType.pause:
          case AudioInterruptionType.unknown:
            _player.pause();
            break;
        }
      } else {
        switch (event.type) {
          case AudioInterruptionType.duck:
            _player.setVolume(1.0);
            break;
          case AudioInterruptionType.pause:
            _player.play();
            break;
          case AudioInterruptionType.unknown:
            break;
        }
      }
    });

    // Listen for unplugging headphones
    session.becomingNoisyEventStream.listen((_) {
      _player.pause();
    });
  }

  AudioPlayer get player => _player;
  NetworkSpeedService get networkSpeedService => _networkSpeedService;

  void updateBaseUrl(String newUrl) {
    debugPrint('AudioHandler: Updating base URL from $_baseStreamUrl to $newUrl');
    _baseStreamUrl = newUrl;
  }

  // ── Auth headers ──

  Map<String, String> _getAuthHeaders() {
    final token = _storage.accessToken;
    if (token != null) {
      return {'Authorization': 'Bearer $token'};
    }
    return {};
  }

  // ── Song Details Auto-Resolver ──

  Future<Map<String, dynamic>?> _fetchSongDetails(String songId) async {
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
      ));
      final directUrl = '${AppConfig.baseUrl}/api/v1/songs/$songId';
      final response = await dio.get(directUrl);
      if (response.data != null) {
        final dynamic raw = response.data['data'] ?? response.data;
        if (raw is Map<String, dynamic>) {
          return raw;
        }
      }
    } catch (e) {
      debugPrint('AudioHandler: Error fetching song details for $songId: $e');
    }
    return null;
  }

  // ── Playlist loading ──

  /// Load and play a list of songs, starting at the given index.
  Future<void> loadPlaylist(List<MediaItem> items, {int initialIndex = 0}) async {
    if (items.isEmpty) return;

    final safeIndex = (initialIndex >= 0 && initialIndex < items.length) ? initialIndex : 0;
    final mutableItems = List<MediaItem>.from(items);
    final targetId = mutableItems[safeIndex].id;
    debugPrint('AudioHandler: loadPlaylist target ID: $targetId at index $safeIndex (total: ${mutableItems.length})');

    // 1. If target item does not yet have a direct audio URL or download qualities, resolve it immediately!
    final targetItem = mutableItems[safeIndex];
    final hasAudioUrl = targetItem.extras?['audio_url'] != null && (targetItem.extras!['audio_url'] as String).isNotEmpty;
    final hasDownloadUrls = targetItem.extras?['download_urls'] != null && (targetItem.extras!['download_urls'] as List).isNotEmpty;

    if (!hasAudioUrl && !hasDownloadUrls) {
      debugPrint('AudioHandler: Resolving stream URL for target item $targetId before playback...');
      final details = await _fetchSongDetails(targetId);
      if (details != null) {
        final rawUrls = details['downloadUrl'] ?? details['download_url'] ?? details['download_urls'];
        final qualities = AdaptiveAudioQualitySelector.parseDownloadUrls(rawUrls);
        final updatedExtras = Map<String, dynamic>.from(targetItem.extras ?? {});
        if (qualities.isNotEmpty) {
          updatedExtras['download_urls'] = qualities.map((e) => e.toJson()).toList();
          updatedExtras['audio_url'] = qualities.last.url;
        } else if (details['audio_url'] != null) {
          updatedExtras['audio_url'] = details['audio_url'];
        }
        mutableItems[safeIndex] = targetItem.copyWith(extras: updatedExtras);
      }
    }

    queue.add(mutableItems);
    final headers = _getAuthHeaders();
    final audioSources = mutableItems.map((item) => _createAudioSource(item, headers)).toList();

    try {
      await _player.setAudioSources(audioSources, initialIndex: safeIndex);
      await _player.play();
      debugPrint('AudioHandler: Playback started successfully for index $safeIndex');
    } on PlayerException catch (e) {
      debugPrint('AudioHandler: PlayerException during loadPlaylist: ${e.message}');
      if (mutableItems.length > 1 && safeIndex + 1 < mutableItems.length) {
        debugPrint('AudioHandler: Attempting next track after error');
        await _player.seek(Duration.zero, index: safeIndex + 1);
        await _player.play();
      }
    } on PlayerInterruptedException catch (e) {
      debugPrint('AudioHandler: PlayerInterruptedException: $e');
    } catch (e) {
      debugPrint('AudioHandler: Error during loadPlaylist: $e');
    }

    // 2. Asynchronously background-resolve any other items in the queue that lack stream URLs
    _backgroundResolveQueue(mutableItems, safeIndex);
  }

  void _backgroundResolveQueue(List<MediaItem> items, int skipIndex) async {
    bool hasUpdates = false;
    for (int i = 0; i < items.length; i++) {
      if (i == skipIndex) continue;
      final it = items[i];
      final hasAudio = it.extras?['audio_url'] != null && (it.extras!['audio_url'] as String).isNotEmpty;
      final hasQualities = it.extras?['download_urls'] != null && (it.extras!['download_urls'] as List).isNotEmpty;
      if (!hasAudio && !hasQualities) {
        final details = await _fetchSongDetails(it.id);
        if (details != null) {
          final rawUrls = details['downloadUrl'] ?? details['download_url'] ?? details['download_urls'];
          final qualities = AdaptiveAudioQualitySelector.parseDownloadUrls(rawUrls);
          final updatedExtras = Map<String, dynamic>.from(it.extras ?? {});
          if (qualities.isNotEmpty) {
            updatedExtras['download_urls'] = qualities.map((e) => e.toJson()).toList();
            updatedExtras['audio_url'] = qualities.last.url;
          } else if (details['audio_url'] != null) {
            updatedExtras['audio_url'] = details['audio_url'];
          }
          items[i] = it.copyWith(extras: updatedExtras);
          hasUpdates = true;
        }
      }
    }

    if (hasUpdates && queue.value.length == items.length) {
      queue.add(items);
      final headers = _getAuthHeaders();
      final audioSources = items.map((item) => _createAudioSource(item, headers)).toList();
      try {
        final curIdx = _player.currentIndex;
        final curPos = _player.position;
        final isPlaying = _player.playing;
        await _player.setAudioSources(audioSources, initialIndex: curIdx, initialPosition: curPos);
        if (isPlaying) {
          await _player.play();
        }
      } catch (e) {
        debugPrint('AudioHandler: Note: error applying background resolved queue: $e');
      }
    }
  }

  Future<void> _ensureItemResolved(int index) async {
    final currentQ = queue.value;
    if (index < 0 || index >= currentQ.length) return;
    final it = currentQ[index];
    final hasAudio = it.extras?['audio_url'] != null && (it.extras!['audio_url'] as String).isNotEmpty;
    final hasQualities = it.extras?['download_urls'] != null && (it.extras!['download_urls'] as List).isNotEmpty;
    if (!hasAudio && !hasQualities) {
      final details = await _fetchSongDetails(it.id);
      if (details != null) {
        final rawUrls = details['downloadUrl'] ?? details['download_url'] ?? details['download_urls'];
        final qualities = AdaptiveAudioQualitySelector.parseDownloadUrls(rawUrls);
        final updatedExtras = Map<String, dynamic>.from(it.extras ?? {});
        if (qualities.isNotEmpty) {
          updatedExtras['download_urls'] = qualities.map((e) => e.toJson()).toList();
          updatedExtras['audio_url'] = qualities.last.url;
        } else if (details['audio_url'] != null) {
          updatedExtras['audio_url'] = details['audio_url'];
        }
        final updatedItem = it.copyWith(extras: updatedExtras);
        final newQ = List<MediaItem>.from(currentQ);
        newQ[index] = updatedItem;
        queue.add(newQ);

        final headers = _getAuthHeaders();
        final newSources = newQ.map((item) => _createAudioSource(item, headers)).toList();
        await _player.setAudioSources(newSources, initialIndex: _player.currentIndex);
      }
    }
  }

  /// Append more items to the end of the current queue.
  Future<void> addItemsToQueue(List<MediaItem> items) async {
    final currentQueue = queue.value;
    final newQueue = [...currentQueue, ...items];
    queue.add(newQueue);

    final headers = _getAuthHeaders();
    final newSources = items.map((item) => _createAudioSource(item, headers)).toList();
    final sequence = _player.sequence;

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
    String? url;

    // 1. Adaptive Network Speed Quality Resolution
    final rawDownloadUrls = item.extras?['download_urls'];
    final qualities = AdaptiveAudioQualitySelector.parseDownloadUrls(rawDownloadUrls);

    if (qualities.isNotEmpty) {
      final prefCode = _storage.audioQualityPreference;
      final pref = AudioQualityPreference.fromCode(prefCode);
      final grade = _networkSpeedService.currentGrade;

      final selectedQuality = AdaptiveAudioQualitySelector.resolveQuality(
        availableQualities: qualities,
        preference: pref,
        currentGrade: grade,
      );

      if (selectedQuality != null && selectedQuality.url.isNotEmpty) {
        url = selectedQuality.url;
        debugPrint(
          'AudioHandler: [Adaptive Quality] Selected ${selectedQuality.displayLabel} for ${item.title} '
          '(Pref: ${pref.code}, Network: ${grade.label}, Speed: ${_networkSpeedService.currentSpeedKbps.toStringAsFixed(0)} kbps)',
        );
      }
    }

    url ??= item.extras?['audio_url'] as String?;

    if (url == null || url.isEmpty) {
      url = '$_baseStreamUrl/music/${item.id}/stream/';
    }

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

  /// Seamlessly switches the streaming quality for the currently playing track
  Future<void> switchCurrentSongQuality(SongDownloadUrl targetQuality) async {
    final currentItem = mediaItem.value;
    if (currentItem == null) return;

    final currentPosition = _player.position;
    final wasPlaying = _player.playing;

    debugPrint('AudioHandler: Switching quality to ${targetQuality.displayLabel} at position ${currentPosition.inSeconds}s');

    final headers = _getAuthHeaders();
    final updatedExtras = Map<String, dynamic>.from(currentItem.extras ?? {});
    updatedExtras['selected_quality'] = targetQuality.shortLabel;
    updatedExtras['audio_url'] = targetQuality.url;

    final updatedItem = currentItem.copyWith(extras: updatedExtras);
    mediaItem.add(updatedItem);

    final newSource = AudioSource.uri(
      Uri.parse(targetQuality.url),
      headers: targetQuality.url.contains(Uri.parse(_baseStreamUrl).host) ? headers : null,
      tag: updatedItem,
    );

    try {
      await _player.setAudioSource(newSource, initialPosition: currentPosition);
      if (wasPlaying) {
        await _player.play();
      }
    } catch (e) {
      debugPrint('AudioHandler: Error switching quality: $e');
    }
  }

  // ── Playback controls ──

  @override
  Future<void> play() {
    final future = _player.play();
    _broadcastState();
    return future;
  }

  @override
  Future<void> pause() {
    final future = _player.pause();
    _broadcastState();
    return future;
  }

  void _broadcastState() {
    playbackState.add(_transformEvent(_player.playbackEvent));
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= queue.value.length) return;
    await _ensureItemResolved(index);
    await _player.seek(Duration.zero, index: index);
    await _player.play();
  }

  @override
  Future<void> skipToNext() async {
    if (_player.hasNext) {
      final nextIdx = (_player.currentIndex ?? 0) + 1;
      await _ensureItemResolved(nextIdx);
      await _player.seekToNext();
      await _player.play();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_player.hasPrevious) {
      final prevIdx = (_player.currentIndex ?? 0) - 1;
      await _ensureItemResolved(prevIdx);
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

  /// Fire-and-forget recent play recording to POST /api/v1/recent-plays
  Future<void> _recordRecentPlay(String songId) async {
    try {
      final userId = _storage.currentUserId ?? 'dZnjYn0Ku1X9vleSQYmyczZvcLL2';
      final dio = Dio(BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(seconds: 4),
        receiveTimeout: const Duration(seconds: 4),
      ));
      await dio.post('/api/v1/recent-plays', data: {
        'user_id': userId,
        'song_id': songId,
      });
      debugPrint('AudioHandler: Recorded recent play for $songId');
    } catch (e) {
      debugPrint('AudioHandler: Note: Error recording recent play: $e');
    }
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
        MediaAction.setRepeatMode,
        MediaAction.setShuffleMode,
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
