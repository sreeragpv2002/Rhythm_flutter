import 'package:flutter/widgets.dart';

class PlayPauseIntent extends Intent {
  const PlayPauseIntent();
}

class SkipNextIntent extends Intent {
  const SkipNextIntent();
}

class SkipPreviousIntent extends Intent {
  const SkipPreviousIntent();
}

class VolumeUpIntent extends Intent {
  const VolumeUpIntent();
}

class VolumeDownIntent extends Intent {
  const VolumeDownIntent();
}
