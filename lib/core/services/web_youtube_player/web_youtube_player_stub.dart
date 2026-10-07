import 'dart:async';
import 'package:rhythm_flutter/core/services/web_youtube_player/web_youtube_player_base.dart';

/// Stub implementation of WebYouTubePlayer for Desktop & Mobile platforms.
class WebYouTubePlayer implements WebYouTubePlayerBase {
  @override
  bool get isPlaying => false;

  @override
  Duration get currentPosition => Duration.zero;

  @override
  Duration get totalDuration => Duration.zero;

  @override
  String? get currentVideoId => null;

  @override
  Stream<Duration> get positionStream => const Stream.empty();

  @override
  Stream<bool> get playingStream => const Stream.empty();

  @override
  Stream<void> get songEndedStream => const Stream.empty();

  @override
  Stream<void> get errorStream => const Stream.empty();

  @override
  Future<void> play(String videoId, {Duration initialPosition = Duration.zero}) async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> seek(Duration position) async {}

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Future<void> stop() async {}

  @override
  void dispose() {}
}

WebYouTubePlayerBase createWebYouTubePlayer() => WebYouTubePlayer();
