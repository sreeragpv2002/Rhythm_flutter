import 'dart:async';

/// Base contract for Web YouTube Player playback controller.
abstract class WebYouTubePlayerBase {
  bool get isPlaying;
  Duration get currentPosition;
  Duration get totalDuration;
  String? get currentVideoId;

  Stream<Duration> get positionStream;
  Stream<bool> get playingStream;
  Stream<void> get songEndedStream;
  Stream<void> get errorStream;

  Future<void> play(String videoId, {Duration initialPosition = Duration.zero});
  Future<void> pause();
  Future<void> resume();
  Future<void> seek(Duration position);
  Future<void> setVolume(double volume); // 0.0 to 1.0
  Future<void> stop();
  void dispose();
}
