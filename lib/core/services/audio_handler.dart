import 'dart:math' as math;
import 'package:audio_service/audio_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rxdart/rxdart.dart';
import 'package:rhythm_flutter/core/services/media_item_mapper.dart';
import 'package:rhythm_flutter/features/home/data/models/home_feed.dart';
import 'package:rhythm_flutter/core/config/app_config.dart';
import 'package:rhythm_flutter/core/services/audio_quality_service.dart';
import 'package:rhythm_flutter/core/services/storage_service.dart';
import 'package:rhythm_flutter/core/services/youtube_audio_service.dart';
import 'package:rhythm_flutter/core/services/web_youtube_player/web_youtube_player.dart';

/// Represents the origin of the currently loaded playback queue.
enum QueueSource {
  song, // Standalone song play -> uses suggested_songs for upcoming tracks
  album, // Full album tracklist
  playlist, // Full playlist tracklist
  artist, // Full artist discography / top songs
}

/// Custom AudioHandler that manages playback with just_audio (Mobile/Desktop)
/// and WebYouTubePlayer (Web), integrating with audio_service for notifications and state.
class RhythmAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  final WebYouTubePlayerBase _webPlayer = createWebYouTubePlayer();
  bool _isUsingWebPlayer = false;
  int _consecutiveErrors = 0;
  final BehaviorSubject<PositionData> _positionDataSubject =
      BehaviorSubject<PositionData>.seeded(PositionData(Duration.zero, Duration.zero, Duration.zero));

  String _baseStreamUrl;
  final StorageService _storage;
  final NetworkSpeedService _networkSpeedService;
  final YouTubeAudioService _youtubeAudioService;
  int _currentIndex = 0;
  QueueSource _queueSource = QueueSource.song;

  QueueSource get queueSource => _queueSource;

  RhythmAudioHandler(
    this._baseStreamUrl,
    this._storage, [
    NetworkSpeedService? networkSpeedService,
    YouTubeAudioService? youtubeAudioService,
  ])  : _networkSpeedService = networkSpeedService ?? NetworkSpeedService(),
        _youtubeAudioService = youtubeAudioService ?? YouTubeAudioService() {
    // Broadcast playback state changes from just_audio when not using WebYouTubePlayer
    Rx.combineLatest2<PlaybackEvent, PlayerState, PlaybackState>(
      _player.playbackEventStream.startWith(_player.playbackEvent),
      _player.playerStateStream,
      (event, state) => _transformEvent(event),
    ).listen((state) {
      if (!_isUsingWebPlayer) {
        playbackState.add(state);
      }
    });

    // Wire just_audio position stream to _positionDataSubject
    Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
      _player.positionStream,
      _player.bufferedPositionStream,
      _player.durationStream,
      (position, bufferedPosition, duration) => PositionData(
        position,
        bufferedPosition,
        duration ?? Duration.zero,
      ),
    ).listen((data) {
      if (!_isUsingWebPlayer) {
        _positionDataSubject.add(data);
      }
    });

    // Web YouTube Player listeners
    _webPlayer.playingStream.listen((isPlaying) {
      if (_isUsingWebPlayer) {
        _broadcastWebPlayerState();
      }
    });

    _webPlayer.positionStream.listen((pos) {
      if (_isUsingWebPlayer) {
        final dur = (mediaItem.value?.duration != null && mediaItem.value!.duration! > Duration.zero)
            ? mediaItem.value!.duration!
            : _webPlayer.totalDuration;
        _positionDataSubject.add(PositionData(pos, pos, dur));
      }
    });

    _webPlayer.songEndedStream.listen((_) {
      if (_isUsingWebPlayer) {
        if (_player.loopMode == LoopMode.one) {
          _webPlayer.seek(Duration.zero);
          _webPlayer.resume();
        } else {
          skipToNext();
        }
      }
    });

    _webPlayer.errorStream.listen((_) {
      if (_isUsingWebPlayer) {
        debugPrint('AudioHandler: WebYouTubePlayer encountered error');
        _consecutiveErrors++;
        if (_consecutiveErrors < 3) {
          skipToNext();
        } else {
          _consecutiveErrors = 0;
          pause();
        }
      }
    });

    _initAudioSession();

    // Listen for current index changes to update mediaItem
    _player.currentIndexStream.listen((index) {
      if (index != null && queue.value.isNotEmpty && index < queue.value.length) {
        _currentIndex = index;
        final item = queue.value[index];
        mediaItem.add(item);
      }
    });

    // Listen for when a song completes to auto-play next (just_audio)
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed && !_isUsingWebPlayer) {
        if (_player.loopMode == LoopMode.one) {
          _player.seek(Duration.zero);
          _player.play();
        } else {
          skipToNext();
        }
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
  int get currentIndex => _currentIndex;

  void updateBaseUrl(String newUrl) {
    debugPrint('AudioHandler: Updating base URL from $_baseStreamUrl to $newUrl');
    _baseStreamUrl = newUrl;
  }

  // ── Auth headers ──

  Map<String, String> _getAuthHeaders() {
    final token = _storage.accessToken;
    if (token != null && token.isNotEmpty && token != 'guest_token') {
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

      // 1. Unified details endpoint: /api/v1/details?type=song&id=$songId
      try {
        final detailsUrl = '${AppConfig.baseUrl}/api/v1/details';
        final queryParams = <String, dynamic>{'type': 'song', 'id': songId};
        final uid = _storage.userId;
        if (uid != null && uid.isNotEmpty) {
          queryParams['user_id'] = uid;
        }
        final response = await dio.get<dynamic>(
          detailsUrl,
          queryParameters: queryParams,
        );
        final responseData = response.data;
        if (responseData is Map<String, dynamic> && responseData['success'] == true) {
          final dynamic raw = responseData['data'];
          if (raw is Map<String, dynamic>) {
            return raw;
          }
        }
      } catch (_) {}

      // 2. Try /api/v1/songs/$songId
      try {
        final directUrl = '${AppConfig.baseUrl}/api/v1/songs/$songId';
        final response = await dio.get<dynamic>(directUrl);
        final responseData = response.data;
        if (responseData is Map<String, dynamic>) {
          final dynamic raw = responseData['data'] ?? responseData;
          if (raw is Map<String, dynamic>) {
            return raw;
          }
        }
      } catch (_) {}
    } catch (e) {
      debugPrint('AudioHandler: Error fetching song details for $songId: $e');
    }
    return null;
  }

  /// Searches the backend as a fallback if song details are missing (e.g. legacy IDs)
  Future<Map<String, dynamic>?> _searchSongFallback(String title, [String? artist]) async {
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 6),
        receiveTimeout: const Duration(seconds: 6),
      ));
      final query = [
        title,
        if (artist != null && artist.isNotEmpty && artist != 'Unknown' && artist != 'Song') artist
      ].join(' ').trim();
      final url = '${AppConfig.baseUrl}/api/v1/search/songs';
      final response = await dio.get<dynamic>(url, queryParameters: {'query': query, 'limit': 1});
      final data = response.data;
      if (data is Map<String, dynamic> && data['songs'] is List && (data['songs'] as List).isNotEmpty) {
        final firstSong = (data['songs'] as List).first;
        if (firstSong is Map<String, dynamic>) {
          return firstSong;
        }
      }
    } catch (e) {
      debugPrint('AudioHandler: Song search fallback error for "$title": $e');
    }
    return null;
  }

  // ── Playlist loading & Playback ──

  /// Load and play a list of songs, starting at the given index.
  Future<void> loadPlaylist(
    List<MediaItem> items, {
    int initialIndex = 0,
    QueueSource source = QueueSource.song,
  }) async {
    if (items.isEmpty) return;

    final safeIndex = (initialIndex >= 0 && initialIndex < items.length) ? initialIndex : 0;
    final mutableItems = List<MediaItem>.from(items);
    _currentIndex = safeIndex;
    _queueSource = source;
    queue.add(mutableItems);

    debugPrint('AudioHandler: loadPlaylist target ID: ${mutableItems[safeIndex].id} at index $safeIndex (total: ${mutableItems.length}, source: $source)');

    // Play the target item immediately
    await _playItemAtIndex(safeIndex);

    // Asynchronously pre-resolve any other items in queue
    _backgroundResolveQueue(mutableItems, safeIndex);
  }

  /// Plays a single song and automatically populates the queue with suggested songs
  Future<void> playSong(MediaItem item) async {
    await loadPlaylist([item], initialIndex: 0, source: QueueSource.song);
  }

  /// Internal worker: plays the song at [index] in the current [queue].
  Future<void> _playItemAtIndex(int index, {Duration initialPosition = Duration.zero}) async {
    final currentQ = List<MediaItem>.from(queue.value);
    if (index < 0 || index >= currentQ.length) return;

    _currentIndex = index;
    var targetItem = currentQ[index];

    // Determine if the song is a YouTube track
    var ytUrl = targetItem.extras?['youtube_url'] as String? ?? targetItem.extras?['url'] as String?;
    final explicitYt = targetItem.extras?['is_youtube'] as bool?;
    var isYt = _youtubeAudioService.isYouTubeTrack(
      targetItem.id,
      songUrl: ytUrl,
      explicitIsYouTube: explicitYt,
    );

    Map<String, dynamic>? resolvedDetails;

    // 1. Resolve direct audio URL or download qualities if missing
    final hasAudioUrl = targetItem.extras?['audio_url'] != null &&
        (targetItem.extras!['audio_url'] as String).isNotEmpty;
    final hasDownloadUrls = targetItem.extras?['download_urls'] != null &&
        (targetItem.extras!['download_urls'] as List).isNotEmpty;

    if (!hasAudioUrl && !hasDownloadUrls) {
      debugPrint('AudioHandler: Resolving stream URL for target item ${targetItem.id} (isYt: $isYt)...');

      if (isYt) {
        final videoId = _youtubeAudioService.extractVideoId(ytUrl ?? targetItem.id) ?? targetItem.id;
        ytUrl ??= 'https://music.youtube.com/watch?v=$videoId';
        final updatedExtras = Map<String, dynamic>.from(targetItem.extras ?? {});
        updatedExtras['youtube_url'] = ytUrl;
        updatedExtras['is_youtube'] = true;

        if (!kIsWeb) {
          debugPrint('AudioHandler: Resolving via YouTubeAudioService for ${targetItem.id}...');
          final ytResult = await _youtubeAudioService.resolveStream(targetItem.id, songUrl: ytUrl);
          if (ytResult != null && ytResult.bestAudioUrl.isNotEmpty) {
            updatedExtras['audio_url'] = ytResult.bestAudioUrl;
            if (ytResult.downloadUrls.isNotEmpty) {
              updatedExtras['download_urls'] = ytResult.downloadUrls.map((e) => e.toJson()).toList();
            }
          }
        }
        targetItem = targetItem.copyWith(extras: updatedExtras);
        currentQ[index] = targetItem;
        queue.add(currentQ);
      } else {
        // Query backend song details
        var details = await _fetchSongDetails(targetItem.id);

        // Fallback: search backend if details not found (e.g. legacy Saavn ID like P5pjB99X)
        if (details == null) {
          debugPrint('AudioHandler: Song details not found for ${targetItem.id}, trying search fallback for "${targetItem.title}"...');
          details = await _searchSongFallback(targetItem.title, targetItem.artist);
        }

        if (details != null) {
          resolvedDetails = details;
          final updatedExtras = Map<String, dynamic>.from(targetItem.extras ?? {});
          final rawUrls = details['downloadUrl'] ?? details['download_url'] ?? details['download_urls'];
          final qualities = AdaptiveAudioQualitySelector.parseDownloadUrls(rawUrls);
          final detailYtUrl = details['url'] ?? details['youtube_url'];
          final detailId = details['id']?.toString() ?? targetItem.id;

          if (qualities.isNotEmpty) {
            updatedExtras['download_urls'] = qualities.map((e) => e.toJson()).toList();
            updatedExtras['audio_url'] = qualities.last.url;
          } else if (details['audio_url'] != null) {
            updatedExtras['audio_url'] = details['audio_url'].toString();
          }

          if (detailYtUrl != null || _youtubeAudioService.isYouTubeTrack(detailId, songUrl: detailYtUrl?.toString())) {
            isYt = true;
            ytUrl = detailYtUrl?.toString() ?? 'https://music.youtube.com/watch?v=$detailId';
            updatedExtras['youtube_url'] = ytUrl;
            updatedExtras['is_youtube'] = true;
            if (!kIsWeb && updatedExtras['audio_url'] == null) {
              final ytResult = await _youtubeAudioService.resolveStream(detailId, songUrl: ytUrl);
              if (ytResult != null && ytResult.bestAudioUrl.isNotEmpty) {
                updatedExtras['audio_url'] = ytResult.bestAudioUrl;
                if (ytResult.downloadUrls.isNotEmpty) {
                  updatedExtras['download_urls'] = ytResult.downloadUrls.map((e) => e.toJson()).toList();
                }
              }
            }
          }

          targetItem = targetItem.copyWith(
            id: detailId,
            extras: updatedExtras,
          );
          currentQ[index] = targetItem;
          queue.add(currentQ);
        }
      }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 💡 SUGGESTED SONGS: If user is playing a standalone song (not from album, artist, or playlist),
    // automatically populate upcoming queue with suggested_songs from API response!
    // ─────────────────────────────────────────────────────────────────────────
    if (_queueSource == QueueSource.song) {
      if (resolvedDetails != null && resolvedDetails['suggested_songs'] is List) {
        _populateSuggestedSongsIfApplicable(targetItem.id, resolvedDetails);
      } else {
        _loadAndAppendSuggestedSongs(targetItem.id);
      }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 🌐 WEB YOUTUBE FAST PATH: Play via official YouTube IFrame Player on Web
    // ─────────────────────────────────────────────────────────────────────────
    if (kIsWeb && isYt) {
      final videoId = _youtubeAudioService.extractVideoId(ytUrl ?? targetItem.id) ?? targetItem.id;
      debugPrint('AudioHandler: [Web] Playing YouTube track $videoId via WebYouTubePlayer...');

      // Stop just_audio player if it was playing
      await _player.stop();
      _isUsingWebPlayer = true;

      // Broadcast active mediaItem
      mediaItem.add(targetItem);

      try {
        await _webPlayer.play(videoId, initialPosition: initialPosition);
        _broadcastWebPlayerState();
        _consecutiveErrors = 0;
        _recordRecentPlay(targetItem.id);
        debugPrint('AudioHandler: [Web] Successfully started YouTube playback for ${targetItem.title}');
        return;
      } catch (e) {
        debugPrint('AudioHandler: [Web] WebYouTubePlayer error: $e');
        _isUsingWebPlayer = false;
        // Fall through to regular playback attempt below
      }
    } else if (_isUsingWebPlayer) {
      await _webPlayer.stop();
      _isUsingWebPlayer = false;
    }

    // 2. Broadcast active mediaItem
    mediaItem.add(targetItem);

    // 3. Create audio source and start playback
    final headers = _getAuthHeaders();
    final source = _createAudioSource(targetItem, headers);

    try {
      await _player.setAudioSource(source, initialPosition: initialPosition);
      await _player.play();
      _broadcastState();
      _consecutiveErrors = 0;
      _recordRecentPlay(targetItem.id);
      debugPrint('AudioHandler: Playback successfully started for index $index: ${targetItem.title}');
    } on PlayerException catch (e) {
      debugPrint('AudioHandler: PlayerException playing index $index: ${e.message}');
      _consecutiveErrors++;
      if (_consecutiveErrors < 3 && index + 1 < currentQ.length) {
        debugPrint('AudioHandler: Attempting next track after player error (consecutive errors: $_consecutiveErrors)...');
        await skipToNext();
      } else {
        debugPrint('AudioHandler: Halting auto-skip (consecutive errors: $_consecutiveErrors).');
        _consecutiveErrors = 0;
      }
    } catch (e) {
      debugPrint('AudioHandler: Error playing item at index $index: $e');
      _consecutiveErrors++;
      if (_consecutiveErrors < 3 && index + 1 < currentQ.length) {
        debugPrint('AudioHandler: Attempting next track after error (consecutive errors: $_consecutiveErrors)...');
        await skipToNext();
      } else {
        debugPrint('AudioHandler: Halting auto-skip (consecutive errors: $_consecutiveErrors).');
        _consecutiveErrors = 0;
      }
    }
  }

  Future<void> _loadAndAppendSuggestedSongs(String songId) async {
    try {
      final details = await _fetchSongDetails(songId);
      if (details != null && _queueSource == QueueSource.song) {
        _populateSuggestedSongsIfApplicable(songId, details);
      }
    } catch (e) {
      debugPrint('AudioHandler: Error loading suggested songs for $songId: $e');
    }
  }

  void _populateSuggestedSongsIfApplicable(String songId, Map<String, dynamic> details) {
    if (_queueSource != QueueSource.song) {
      debugPrint('AudioHandler: Queue source is $_queueSource (album/playlist/artist), keeping existing collection.');
      return;
    }

    final rawSuggestions = details['suggested_songs'];
    if (rawSuggestions is! List || rawSuggestions.isEmpty) return;

    final currentQ = List<MediaItem>.from(queue.value);
    if (_currentIndex < 0 || _currentIndex >= currentQ.length) return;

    // Keep played tracks history and current track
    final playedItems = currentQ.sublist(0, _currentIndex + 1);
    final playedIds = playedItems.map((e) => e.id).toSet();
    final newSuggestedItems = <MediaItem>[];

    for (final raw in rawSuggestions) {
      if (raw is Map<String, dynamic>) {
        final id = raw['id']?.toString() ?? '';
        if (id.isNotEmpty && !playedIds.contains(id)) {
          final homeItem = HomeItem.fromJson(raw);
          newSuggestedItems.add(homeItemToMediaItem(homeItem));
          playedIds.add(id);
        }
      }
    }

    if (newSuggestedItems.isNotEmpty) {
      // Keep queue up to current index, and populate remainder with suggested songs
      final updatedQueue = [
        ...currentQ.sublist(0, _currentIndex + 1),
        ...newSuggestedItems,
      ];
      queue.add(updatedQueue);
      debugPrint('AudioHandler: Populated queue with ${newSuggestedItems.length} suggested songs based on $songId');

      // Pre-resolve the immediate upcoming 2 tracks in background
      _backgroundResolveQueue(updatedQueue, _currentIndex);
    }
  }

  void _backgroundResolveQueue(List<MediaItem> items, int skipIndex) async {
    // Only pre-resolve the immediate upcoming 2 tracks to save mobile bandwidth & avoid slowdowns
    final maxLookahead = math.min(items.length, skipIndex + 3);
    for (int i = skipIndex + 1; i < maxLookahead; i++) {
      final it = items[i];
      final hasAudio = it.extras?['audio_url'] != null && (it.extras!['audio_url'] as String).isNotEmpty;
      final hasQualities = it.extras?['download_urls'] != null && (it.extras!['download_urls'] as List).isNotEmpty;
      if (!hasAudio && !hasQualities) {
        final ytUrl = it.extras?['youtube_url'] as String? ?? it.extras?['url'] as String?;
        final explicitYt = it.extras?['is_youtube'] as bool?;
        final isYt = _youtubeAudioService.isYouTubeTrack(
          it.id,
          songUrl: ytUrl,
          explicitIsYouTube: explicitYt,
        );

        if (isYt) {
          final ytResult = await _youtubeAudioService.resolveStream(it.id, songUrl: ytUrl);
          if (ytResult != null && ytResult.bestAudioUrl.isNotEmpty) {
            final updatedExtras = Map<String, dynamic>.from(it.extras ?? {});
            updatedExtras['audio_url'] = ytResult.bestAudioUrl;
            if (ytResult.downloadUrls.isNotEmpty) {
              updatedExtras['download_urls'] = ytResult.downloadUrls.map((e) => e.toJson()).toList();
            }
            final currentQ = List<MediaItem>.from(queue.value);
            if (i < currentQ.length && currentQ[i].id == it.id) {
              currentQ[i] = it.copyWith(extras: updatedExtras);
              queue.add(currentQ);
            }
            continue;
          }
        }

        final details = await _fetchSongDetails(it.id);
        if (details != null) {
          final rawUrls = details['downloadUrl'] ?? details['download_url'] ?? details['download_urls'];
          final qualities = AdaptiveAudioQualitySelector.parseDownloadUrls(rawUrls);
          final updatedExtras = Map<String, dynamic>.from(it.extras ?? {});
          if (qualities.isNotEmpty) {
            updatedExtras['download_urls'] = qualities.map((e) => e.toJson()).toList();
            updatedExtras['audio_url'] = qualities.last.url;
          } else if (details['audio_url'] != null) {
            updatedExtras['audio_url'] = details['audio_url'].toString();
          }
          final currentQ = List<MediaItem>.from(queue.value);
          if (i < currentQ.length && currentQ[i].id == it.id) {
            currentQ[i] = it.copyWith(extras: updatedExtras);
            queue.add(currentQ);
          }
        }
      }
    }
  }

  /// Append more items to the end of the current queue.
  Future<void> addItemsToQueue(List<MediaItem> items) async {
    final currentQueue = queue.value;
    final newQueue = [...currentQueue, ...items];
    queue.add(newQueue);
  }

  AudioSource _createAudioSource(MediaItem item, Map<String, String> headers) {
    String? url;

    // 1. Adaptive Network Speed Quality Resolution
    final rawDownloadUrls = item.extras?['download_urls'];
    if (rawDownloadUrls != null) {
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
            '(Pref: ${pref.code}, Network: ${grade.label})',
          );
        }
      }
    }

    url ??= item.extras?['audio_url'] as String?;

    if (url == null || url.isEmpty) {
      debugPrint('AudioHandler: No valid streaming URL available for ${item.id} (${item.title})');
      throw StateError('AudioHandler: No playable audio stream available for "${item.title}"');
    }

    // Handle relative URLs
    if (!url.startsWith('http')) {
      final uri = Uri.parse(_baseStreamUrl);
      final origin = '${uri.scheme}://${uri.host}${uri.hasPort ? ":${uri.port}" : ""}';
      url = url.startsWith('/') ? '$origin$url' : '$origin/$url';
    }

    // Upgrade known CDN URLs to secure HTTPS
    if (url.startsWith('http://aac.saavncdn.com')) {
      url = url.replaceFirst('http://', 'https://');
    }

    // CRITICAL for Web: Browsers HTMLAudioElement does not support custom request headers.
    // Supplying headers on Web triggers UnsupportedError or CORS preflight blocks.
    Map<String, String>? useHeaders;
    if (!kIsWeb) {
      final map = <String, String>{};
      if (url.contains(Uri.parse(_baseStreamUrl).host)) {
        map.addAll(headers);
      }
      if (url.contains('googlevideo.com') ||
          url.contains('youtube') ||
          url.contains('piped') ||
          url.contains('invidious')) {
        map['User-Agent'] =
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
      }
      if (map.isNotEmpty) {
        useHeaders = map;
      }
    }

    // On Web, strip artUri from AudioSource tag to prevent just_audio_web XMLHttpRequest 429 errors
    final useTag = kIsWeb ? item.copyWith(artUri: null) : item;

    return AudioSource.uri(
      Uri.parse(url),
      headers: useHeaders,
      tag: useTag,
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

    final useHeaders = kIsWeb
        ? null
        : (targetQuality.url.contains(Uri.parse(_baseStreamUrl).host) ? headers : null);

    final useTag = kIsWeb ? updatedItem.copyWith(artUri: null) : updatedItem;

    final newSource = AudioSource.uri(
      Uri.parse(targetQuality.url),
      headers: useHeaders,
      tag: useTag,
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
  Future<void> play() async {
    if (_isUsingWebPlayer) {
      await _webPlayer.resume();
      _broadcastWebPlayerState();
    } else {
      await _player.play();
      _broadcastState();
    }
  }

  @override
  Future<void> pause() async {
    if (_isUsingWebPlayer) {
      await _webPlayer.pause();
      _broadcastWebPlayerState();
    } else {
      await _player.pause();
      _broadcastState();
    }
  }

  void _broadcastState() {
    if (_isUsingWebPlayer) {
      _broadcastWebPlayerState();
    } else {
      playbackState.add(_transformEvent(_player.playbackEvent));
    }
  }

  void _broadcastWebPlayerState() {
    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          if (_webPlayer.isPlaying) MediaControl.pause else MediaControl.play,
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
        processingState: AudioProcessingState.ready,
        playing: _webPlayer.isPlaying,
        updatePosition: _webPlayer.currentPosition,
        bufferedPosition: _webPlayer.currentPosition,
        speed: 1.0,
        queueIndex: _currentIndex,
      ),
    );
  }

  @override
  Future<void> seek(Duration position) async {
    if (_isUsingWebPlayer) {
      await _webPlayer.seek(position);
      _broadcastWebPlayerState();
    } else {
      await _player.seek(position);
    }
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    final currentQ = queue.value;
    if (index < 0 || index >= currentQ.length) return;
    await _playItemAtIndex(index);
  }

  @override
  Future<void> skipToNext() async {
    final currentQ = queue.value;
    if (currentQ.isEmpty) return;

    // Handle shuffle mode
    if (_player.shuffleModeEnabled && currentQ.length > 1) {
      final rand = math.Random();
      int nextIdx;
      do {
        nextIdx = rand.nextInt(currentQ.length);
      } while (nextIdx == _currentIndex && currentQ.length > 1);
      await _playItemAtIndex(nextIdx);
      return;
    }

    final nextIdx = _currentIndex + 1;
    if (nextIdx < currentQ.length) {
      await _playItemAtIndex(nextIdx);
    } else if (_queueSource == QueueSource.song && currentQ.isNotEmpty) {
      // Reached the end of suggestions queue; fetch more suggestions from the last played song
      debugPrint('AudioHandler: Reached end of suggestions, fetching more suggestions...');
      final lastId = currentQ.last.id;
      final details = await _fetchSongDetails(lastId);
      if (details != null && details['suggested_songs'] is List) {
        _populateSuggestedSongsIfApplicable(lastId, details);
        final updatedQ = queue.value;
        if (_currentIndex + 1 < updatedQ.length) {
          await _playItemAtIndex(_currentIndex + 1);
          return;
        }
      }
      if (_player.loopMode == LoopMode.all) {
        await _playItemAtIndex(0);
      }
    } else if (_player.loopMode == LoopMode.all) {
      await _playItemAtIndex(0);
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_player.position.inSeconds > 3) {
      await _player.seek(Duration.zero);
      return;
    }

    final currentQ = queue.value;
    if (currentQ.isEmpty) return;

    final prevIdx = _currentIndex - 1;
    if (prevIdx >= 0) {
      await _playItemAtIndex(prevIdx);
    } else if (_player.loopMode == LoopMode.all) {
      await _playItemAtIndex(currentQ.length - 1);
    } else {
      await _player.seek(Duration.zero);
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

    if (_currentIndex < updatedQueue.length) {
      mediaItem.add(updatedQueue[_currentIndex]);
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
    if (_isUsingWebPlayer) {
      await _webPlayer.stop();
      _isUsingWebPlayer = false;
    }
    await _player.stop();
    return super.stop();
  }

  /// Dispose the underlying player. Call when the app is shutting down.
  Future<void> dispose() async {
    _webPlayer.dispose();
    await _positionDataSubject.close();
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
      }[_player.processingState] ?? AudioProcessingState.idle,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: _currentIndex,
    );
  }

  /// Combined stream of position, buffered position, and duration.
  Stream<PositionData> get positionDataStream => _positionDataSubject.stream;
}

/// Helper class to bundle position data.
class PositionData {
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;

  PositionData(this.position, this.bufferedPosition, this.duration);
}
