import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

/// Helper to determine if running on native mobile (Android or iOS).
bool get isMobilePlatform =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

/// Service dedicated to managing YouTube playback on mobile platforms via youtube_player_iframe.
///
/// Avoids attempting to extract raw streams on mobile (Option 1 — YouTube player).
class MobileYouTubePlayerService extends ChangeNotifier {
  static final MobileYouTubePlayerService instance =
      MobileYouTubePlayerService._();

  MobileYouTubePlayerService._();

  YoutubePlayerController? _controller;
  String? _currentVideoId;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  bool _isDetailScreenActive = false;

  StreamSubscription<dynamic>? _stateSub;
  StreamSubscription<dynamic>? _videoStateSub;

  final StreamController<Duration> _positionController =
      StreamController<Duration>.broadcast();
  final StreamController<bool> _playingController =
      StreamController<bool>.broadcast();
  final StreamController<void> _songEndedController =
      StreamController<void>.broadcast();
  final StreamController<void> _errorController =
      StreamController<void>.broadcast();

  YoutubePlayerController? get controller => _controller;
  String? get currentVideoId => _currentVideoId;
  bool get isPlaying => _isPlaying;
  Duration get currentPosition => _currentPosition;
  bool get isDetailScreenActive => _isDetailScreenActive;

  Stream<Duration> get positionStream => _positionController.stream;
  Stream<bool> get playingStream => _playingController.stream;
  Stream<void> get songEndedStream => _songEndedController.stream;
  Stream<void> get errorStream => _errorController.stream;

  void setDetailScreenActive(bool active) {
    if (_isDetailScreenActive != active) {
      _isDetailScreenActive = active;
      notifyListeners();
    }
  }

  Future<void> play(String videoId) async {
    final cleanId = videoId.trim();
    if (cleanId.isEmpty) return;

    if (_currentVideoId == cleanId && _controller != null) {
      _controller!.playVideo();
      _isPlaying = true;
      _playingController.add(true);
      notifyListeners();
      return;
    }

    _currentVideoId = cleanId;

    // Clean up old subscriptions and controller
    _stateSub?.cancel();
    _videoStateSub?.cancel();
    try {
      _controller?.close();
    } catch (_) {}

    debugPrint('MobileYouTubePlayerService: Initializing YoutubePlayerController for videoId: $cleanId');
    _controller = YoutubePlayerController.fromVideoId(
      videoId: cleanId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
      ),
    );

    _isPlaying = true;
    _playingController.add(true);

    _stateSub = _controller!.listen((event) {
      final playerState = event.playerState;
      if (playerState == PlayerState.playing) {
        if (!_isPlaying) {
          _isPlaying = true;
          _playingController.add(true);
          notifyListeners();
        }
      } else if (playerState == PlayerState.paused) {
        if (_isPlaying) {
          _isPlaying = false;
          _playingController.add(false);
          notifyListeners();
        }
      } else if (playerState == PlayerState.ended) {
        _isPlaying = false;
        _playingController.add(false);
        _songEndedController.add(null);
        notifyListeners();
      }
    });

    _videoStateSub = _controller!.videoStateStream.listen((videoState) {
      _currentPosition = videoState.position;
      _positionController.add(_currentPosition);
    });

    notifyListeners();
  }

  Future<void> pause() async {
    _controller?.pauseVideo();
    _isPlaying = false;
    _playingController.add(false);
    notifyListeners();
  }

  Future<void> resume() async {
    _controller?.playVideo();
    _isPlaying = true;
    _playingController.add(true);
    notifyListeners();
  }

  Future<void> seek(Duration position) async {
    _currentPosition = position;
    _controller?.seekTo(seconds: position.inMilliseconds / 1000.0);
    _positionController.add(position);
  }

  Future<void> stop() async {
    _controller?.pauseVideo();
    _isPlaying = false;
    _playingController.add(false);
    notifyListeners();
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _videoStateSub?.cancel();
    _controller?.close();
    _positionController.close();
    _playingController.close();
    _songEndedController.close();
    _errorController.close();
    super.dispose();
  }
}
