import 'dart:async';
import 'dart:js' as js;
import 'package:flutter/foundation.dart';
import 'package:rhythm_flutter/core/services/web_youtube_player/web_youtube_player_base.dart';

/// Web implementation of WebYouTubePlayer interacting with window.rhythmYT via JS interop.
class WebYouTubePlayer implements WebYouTubePlayerBase {
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  String? _currentVideoId;
  Timer? _ticker;

  final _positionController = StreamController<Duration>.broadcast();
  final _playingController = StreamController<bool>.broadcast();
  final _songEndedController = StreamController<void>.broadcast();
  final _errorController = StreamController<void>.broadcast();

  WebYouTubePlayer() {
    _setupJsCallbacks();
  }

  void _setupJsCallbacks() {
    try {
      final rhythmYT = js.context['rhythmYT'];
      if (rhythmYT != null) {
        rhythmYT['onStateChangeCallback'] = (dynamic state) {
          debugPrint('WebYouTubePlayer: state changed -> $state');
          // YT.PlayerState: -1: unstarted, 0: ended, 1: playing, 2: paused, 3: buffering, 5: cued
          if (state == 1) {
            _isPlaying = true;
            _playingController.add(true);
            _startTicker();
          } else if (state == 2) {
            _isPlaying = false;
            _playingController.add(false);
            _stopTicker();
          } else if (state == 0) {
            _isPlaying = false;
            _playingController.add(false);
            _stopTicker();
            _songEndedController.add(null);
          }
        };

        rhythmYT['onErrorCallback'] = (dynamic errorCode) {
          debugPrint('WebYouTubePlayer: error -> $errorCode');
          _errorController.add(null);
        };
      }
    } catch (e) {
      debugPrint('WebYouTubePlayer: Error setting up JS callbacks: $e');
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _pollPositionAndDuration();
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  void _pollPositionAndDuration() {
    try {
      final rhythmYT = js.context['rhythmYT'];
      if (rhythmYT != null) {
        final curSec = rhythmYT.callMethod('getCurrentTime');
        final durSec = rhythmYT.callMethod('getDuration');

        if (curSec is num && curSec >= 0) {
          _currentPosition = Duration(milliseconds: (curSec * 1000).round());
          _positionController.add(_currentPosition);
        }

        if (durSec is num && durSec > 0) {
          _totalDuration = Duration(milliseconds: (durSec * 1000).round());
        }
      }
    } catch (_) {}
  }

  @override
  bool get isPlaying => _isPlaying;

  @override
  Duration get currentPosition => _currentPosition;

  @override
  Duration get totalDuration => _totalDuration;

  @override
  String? get currentVideoId => _currentVideoId;

  @override
  Stream<Duration> get positionStream => _positionController.stream;

  @override
  Stream<bool> get playingStream => _playingController.stream;

  @override
  Stream<void> get songEndedStream => _songEndedController.stream;

  @override
  Stream<void> get errorStream => _errorController.stream;

  @override
  Future<void> play(String videoId, {Duration initialPosition = Duration.zero}) async {
    _currentVideoId = videoId;
    _currentPosition = initialPosition;
    _totalDuration = Duration.zero;

    try {
      final rhythmYT = js.context['rhythmYT'];
      if (rhythmYT != null) {
        rhythmYT.callMethod('playVideo', [videoId, initialPosition.inSeconds]);
        _isPlaying = true;
        _playingController.add(true);
        _startTicker();
        debugPrint('WebYouTubePlayer: Started playing YouTube video $videoId at ${initialPosition.inSeconds}s');
      }
    } catch (e) {
      debugPrint('WebYouTubePlayer: Failed to play $videoId: $e');
    }
  }

  @override
  Future<void> pause() async {
    try {
      final rhythmYT = js.context['rhythmYT'];
      if (rhythmYT != null) {
        rhythmYT.callMethod('pauseVideo');
      }
      _isPlaying = false;
      _playingController.add(false);
      _stopTicker();
    } catch (e) {
      debugPrint('WebYouTubePlayer: Pause failed: $e');
    }
  }

  @override
  Future<void> resume() async {
    try {
      final rhythmYT = js.context['rhythmYT'];
      if (rhythmYT != null) {
        rhythmYT.callMethod('resumeVideo');
      }
      _isPlaying = true;
      _playingController.add(true);
      _startTicker();
    } catch (e) {
      debugPrint('WebYouTubePlayer: Resume failed: $e');
    }
  }

  @override
  Future<void> seek(Duration position) async {
    _currentPosition = position;
    _positionController.add(position);
    try {
      final rhythmYT = js.context['rhythmYT'];
      if (rhythmYT != null) {
        rhythmYT.callMethod('seekTo', [position.inSeconds]);
      }
    } catch (e) {
      debugPrint('WebYouTubePlayer: Seek failed: $e');
    }
  }

  @override
  Future<void> setVolume(double volume) async {
    try {
      final rhythmYT = js.context['rhythmYT'];
      if (rhythmYT != null) {
        final volInt = (volume.clamp(0.0, 1.0) * 100).round();
        rhythmYT.callMethod('setVolume', [volInt]);
      }
    } catch (e) {
      debugPrint('WebYouTubePlayer: setVolume failed: $e');
    }
  }

  @override
  Future<void> stop() async {
    _stopTicker();
    _isPlaying = false;
    _playingController.add(false);
    _currentVideoId = null;
    try {
      final rhythmYT = js.context['rhythmYT'];
      if (rhythmYT != null) {
        rhythmYT.callMethod('stopVideo');
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _stopTicker();
    _positionController.close();
    _playingController.close();
    _songEndedController.close();
    _errorController.close();
  }
}

WebYouTubePlayerBase createWebYouTubePlayer() => WebYouTubePlayer();
