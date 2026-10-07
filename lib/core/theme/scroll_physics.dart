import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Centralized platform scroll physics configuration for Rhythm.
///
/// Tailored for distinct platform expectations:
/// - **Web & Desktop**: [ClampingScrollPhysics] providing crisp, precision
///   scrolling for mouse-wheels, trackpads, and standard browser scrollbars
///   without disorienting rubber-band bounce.
/// - **Mobile (Android & iOS)**: [BouncingScrollPhysics] providing fluid,
///   elastic touch gestures and tactile overscroll feedback.
class AppScrollPhysics {
  const AppScrollPhysics._();

  /// Platform-adaptive scroll physics:
  /// - Web: [ClampingScrollPhysics]
  /// - Mobile: [BouncingScrollPhysics]
  static ScrollPhysics get adaptive =>
      kIsWeb ? const ClampingScrollPhysics() : const BouncingScrollPhysics();

  /// Platform-adaptive physics wrapped with [AlwaysScrollableScrollPhysics],
  /// essential for [RefreshIndicator] and scrollable viewports on both platforms.
  static ScrollPhysics get alwaysScrollableAdaptive => kIsWeb
      ? const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics())
      : const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics());
}
