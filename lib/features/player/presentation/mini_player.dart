import 'dart:math' as math;
import 'dart:ui';
import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rhythm_flutter/core/theme/app_colors.dart';
import 'package:rhythm_flutter/core/theme/spacing.dart';
import 'package:rhythm_flutter/core/extensions/context_extensions.dart';
import 'package:rhythm_flutter/features/player/providers/audio_provider.dart';
import 'package:rhythm_flutter/features/home/providers/favorites_provider.dart';

/// Compact, modern floating glassmorphic Mini Player.
///
/// Features:
/// - Sleek, space-efficient 54px profile.
/// - Smooth gradient progress indicator.
/// - Album artwork with ambient shadow & live animated equalizer when playing.
/// - Dynamic text marquee / safe overflow typography.
/// - Instant reactive favorite toggle with bounce micro-animation.
/// - Play / Pause / Skip controls with haptics and loading indicator.
/// - Swipe gestures: Swipe up to expand full player, swipe left/right to skip tracks.
class MiniPlayer extends ConsumerStatefulWidget {
  const MiniPlayer({super.key});

  @override
  ConsumerState<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends ConsumerState<MiniPlayer> {
  @override
  Widget build(BuildContext context) {
    final mediaItemAsync = ref.watch(currentMediaItemProvider);
    final playbackAsync = ref.watch(playbackStateProvider);
    final qualityLabel = ref.watch(currentActiveQualityLabelProvider);
    final handler = ref.read(audioHandlerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final mediaItem = mediaItemAsync.valueOrNull;
    if (mediaItem == null) return const SizedBox.shrink();

    final isPlaying = playbackAsync.valueOrNull?.playing ?? false;
    final processingState = playbackAsync.valueOrNull?.processingState ?? AudioProcessingState.idle;
    final bool isLoading = processingState == AudioProcessingState.loading ||
        processingState == AudioProcessingState.buffering;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          context.push('/player/${mediaItem.id}');
        },
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null && details.primaryVelocity! < -200) {
            // Swipe up to expand player
            HapticFeedback.mediumImpact();
            context.push('/player/${mediaItem.id}');
          }
        },
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity != null) {
            if (details.primaryVelocity! < -300) {
              // Swipe left: Skip next
              HapticFeedback.lightImpact();
              handler.skipToNext();
            } else if (details.primaryVelocity! > 300) {
              // Swipe right: Skip previous
              HapticFeedback.lightImpact();
              handler.skipToPrevious();
            }
          }
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  color: (isDark ? const Color(0xFF161426) : Colors.white).withValues(alpha: isDark ? 0.85 : 0.94),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: isDark ? 0.12 : 0.07),
                    width: 0.9,
                  ),
                ),
                child: Stack(
                  children: [
                    // ── Thin top gradient progress line (isolated reactive widget) ──
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: _MiniPlayerProgressBar(isDark: isDark),
                    ),

                    // ── Content Row ──
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0, left: 8, right: 6),
                      child: Row(
                        children: [
                          // ── Artwork Thumbnail with Equalizer Overlay ──
                          _ThumbnailSquircle(
                            mediaItem: mediaItem,
                            isLoading: isLoading,
                            isPlaying: isPlaying,
                          ),

                          const SizedBox(width: 8),

                          // ── Title & Artist Metadata ──
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isLoading
                                      ? 'Loading...'
                                      : (mediaItem.title.isEmpty ? context.l10n.appName : mediaItem.title),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                    fontSize: 13.0,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        isLoading
                                            ? '...'
                                            : ((mediaItem.artist == null || mediaItem.artist!.isEmpty)
                                                ? context.l10n.unknownArtist
                                                : mediaItem.artist!),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white.withValues(alpha: 0.55)
                                              : AppColors.textSecondaryLight,
                                          fontSize: 11.0,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                    if (ref.watch(isCurrentSongYouTubeProvider)) ...[
                                      const SizedBox(width: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 3.5, vertical: 0.5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFF0000).withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                        child: const Text(
                                          'YT',
                                          style: TextStyle(
                                            color: Color(0xFFFF4B6E),
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                    if (qualityLabel.isNotEmpty && !isLoading) ...[
                                      const SizedBox(width: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 3.5, vertical: 0.5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF6C5CE7).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                        child: Text(
                                          qualityLabel.split(' ').first,
                                          style: const TextStyle(
                                            color: Color(0xFF9D84FF),
                                            fontSize: 9.0,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 4),

                          // ── Favorite Heart Button ──
                          _FavoriteButton(
                            mediaItem: mediaItem,
                            handler: handler,
                          ),

                          // ── Play / Pause Button ──
                          _PlayPauseButton(
                            isPlaying: isPlaying,
                            isLoading: isLoading,
                            isDark: isDark,
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              if (isPlaying) {
                                handler.pause();
                              } else {
                                handler.play();
                              }
                            },
                          ),

                          // ── Skip Next Button ──
                          IconButton(
                            icon: Icon(
                              Icons.skip_next_rounded,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.75)
                                  : AppColors.textPrimaryLight.withValues(alpha: 0.75),
                              size: 22,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              handler.skipToNext();
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 🖼️ THUMBNAIL SQUIRCLE WITH LIVE EQUALIZER OVERLAY
// ─────────────────────────────────────────────────────────────────────────────

class _ThumbnailSquircle extends StatelessWidget {
  final MediaItem mediaItem;
  final bool isLoading;
  final bool isPlaying;

  const _ThumbnailSquircle({
    required this.mediaItem,
    required this.isLoading,
    required this.isPlaying,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (mediaItem.artUri != null)
              CachedNetworkImage(
                imageUrl: mediaItem.artUri.toString(),
                fit: BoxFit.cover,
                memCacheWidth: (AppSpacing.thumbnailSm * 2).toInt(),
                placeholder: (_, __) => Container(
                  color: const Color(0xFF221F35),
                  child: const Icon(
                    Icons.music_note_rounded,
                    color: Colors.white24,
                    size: 18,
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: const Color(0xFF221F35),
                  child: const Icon(
                    Icons.music_note_rounded,
                    color: Colors.white24,
                    size: 18,
                  ),
                ),
              )
            else
              Container(
                color: const Color(0xFF6C5CE7).withValues(alpha: 0.2),
                child: const Icon(
                  Icons.music_note_rounded,
                  color: Color(0xFF6C5CE7),
                  size: 18,
                ),
              ),

            // Animated Equalizer Indicator
            if (isPlaying && !isLoading)
              Positioned(
                bottom: 1.5,
                right: 1.5,
                child: _MiniEqualizerBars(isPlaying: isPlaying),
              ),

            // Loading / Buffering Spinner
            if (isLoading)
              Container(
                color: Colors.black45,
                child: const Center(
                  child: SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.8,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 📊 ANIMATED MINI EQUALIZER BARS
// ─────────────────────────────────────────────────────────────────────────────

class _MiniEqualizerBars extends StatefulWidget {
  final bool isPlaying;
  const _MiniEqualizerBars({required this.isPlaying});

  @override
  State<_MiniEqualizerBars> createState() => _MiniEqualizerBarsState();
}

class _MiniEqualizerBarsState extends State<_MiniEqualizerBars>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _MiniEqualizerBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value * 2 * math.pi;
        final h1 = widget.isPlaying ? (0.3 + 0.6 * (0.5 + 0.5 * (math.sin(t)))) : 0.3;
        final h2 = widget.isPlaying ? (0.3 + 0.7 * (0.5 + 0.5 * (math.sin(t + 1.5)))) : 0.4;
        final h3 = widget.isPlaying ? (0.3 + 0.65 * (0.5 + 0.5 * (math.sin(t + 3.0)))) : 0.25;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 1.5),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildBar(h1),
              const SizedBox(width: 1.0),
              _buildBar(h2),
              const SizedBox(width: 1.0),
              _buildBar(h3),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBar(double heightFactor) {
    return Container(
      width: 1.8,
      height: 8.5 * heightFactor.clamp(0.2, 1.0),
      decoration: BoxDecoration(
        color: const Color(0xFF6C5CE7),
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ❤️ FAVORITE BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class _FavoriteButton extends ConsumerWidget {
  final MediaItem mediaItem;
  final RhythmAudioHandler handler;

  const _FavoriteButton({
    required this.mediaItem,
    required this.handler,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final numericFavId = int.tryParse(mediaItem.id) ?? mediaItem.id.hashCode.abs();
    final isFav = ref.watch(favoritesProvider).contains(numericFavId);

    return IconButton(
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        transitionBuilder: (child, anim) => ScaleTransition(
          scale: anim,
          child: child,
        ),
        child: Icon(
          isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          key: ValueKey(isFav),
          color: isFav
              ? const Color(0xFFFF4B6E)
              : (isDark ? Colors.white : AppColors.textPrimaryLight).withValues(alpha: 0.4),
          size: 19,
        ),
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      onPressed: () async {
        HapticFeedback.selectionClick();
        await ref.read(favoritesProvider.notifier).toggleFavorite(mediaItem.id);
        final isLiked = ref.read(favoritesProvider).contains(numericFavId);
        handler.updateMediaItemFavorite(mediaItem.id, isLiked);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ⏯️ PLAY / PAUSE BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class _PlayPauseButton extends StatelessWidget {
  final bool isPlaying;
  final bool isLoading;
  final bool isDark;
  final VoidCallback onPressed;

  const _PlayPauseButton({
    required this.isPlaying,
    required this.isLoading,
    required this.isDark,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 34,
      child: isLoading
          ? const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C5CE7)),
                ),
              ),
            )
          : IconButton(
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) => ScaleTransition(
                  scale: anim,
                  child: child,
                ),
                child: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  key: ValueKey(isPlaying),
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                  size: 24,
                ),
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: onPressed,
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 📏 ISOLATED MINI PLAYER PROGRESS BAR
// ─────────────────────────────────────────────────────────────────────────────

class _MiniPlayerProgressBar extends ConsumerWidget {
  final bool isDark;
  const _MiniPlayerProgressBar({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final positionAsync = ref.watch(positionDataProvider);
    final posData = positionAsync.valueOrNull;
    final progress = (posData != null && posData.duration.inMilliseconds > 0)
        ? (posData.position.inMilliseconds / posData.duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      height: 2.0,
      alignment: Alignment.centerLeft,
      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
      child: FractionallySizedBox(
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ),
    );
  }
}

