import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rhythm_flutter/core/theme/app_colors.dart';
import 'package:rhythm_flutter/core/theme/glass_decoration.dart';
import 'package:rhythm_flutter/core/theme/spacing.dart';
import 'package:rhythm_flutter/core/animations/app_animations.dart';
import 'package:rhythm_flutter/core/extensions/context_extensions.dart';
import 'package:rhythm_flutter/core/services/audio_handler.dart';
import 'package:rhythm_flutter/core/widgets/music_list_tile.dart';
import 'package:rhythm_flutter/features/home/data/models/music.dart';
import 'package:rhythm_flutter/features/player/providers/audio_provider.dart';
import 'package:rhythm_flutter/features/player/providers/music_detail_provider.dart';
import 'package:rhythm_flutter/features/home/providers/favorites_provider.dart';

class SongDetailScreen extends ConsumerStatefulWidget {
  final int initialMusicId;
  const SongDetailScreen({
    super.key,
    required this.initialMusicId,
  });

  @override
  ConsumerState<SongDetailScreen> createState() => _SongDetailScreenState();
}

class _SongDetailScreenState extends ConsumerState<SongDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  double? _dragValue;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _playMusic(Music music, RhythmAudioHandler handler, String locale) {
    handler.loadPlaylist([musicToMediaItem(music, locale)]);
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.l10n.localeName;
    final mediaItemAsync = ref.watch(currentMediaItemProvider);
    final playbackAsync = ref.watch(playbackStateProvider);
    final handler = ref.read(audioHandlerProvider);
    final musicAsync = ref.watch(musicDetailsProvider(widget.initialMusicId));
    final relatedAsync = ref.watch(relatedSongsProvider(widget.initialMusicId));
    final isLiked = ref.watch(favoritesProvider).contains(widget.initialMusicId);

    // Seed favorites only on first load.
    ref.listen<AsyncValue<Music>>(
      musicDetailsProvider(widget.initialMusicId),
          (prev, next) {
        if (next.isLoading || next.hasError) return;
        next.whenData((music) {
          if (prev == null || prev.isLoading) {
            ref.read(favoritesProvider.notifier).initFromList([music]);
          }
          final currentItem = ref.read(currentMediaItemProvider).value;
          final ps = ref.read(playbackStateProvider).value;
          if (currentItem?.id != music.id.toString()) {
            _playMusic(music, handler, locale);
          } else if (ps != null && !ps.playing) {
            handler.play();
          }
        });
      },
    );

    // Trigger playback when data is already cached.
    if (!musicAsync.isLoading && musicAsync.hasValue) {
      final music = musicAsync.value!;
      final currentItem = ref.read(currentMediaItemProvider).value;
      if (currentItem?.id != music.id.toString()) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final ps = ref.read(playbackStateProvider).value;
          if (ref.read(currentMediaItemProvider).value?.id != music.id.toString()) {
            _playMusic(music, handler, locale);
          } else if (ps != null && !ps.playing) {
            handler.play();
          }
        });
      }
    }

    // Sync disc rotation with playback state.
    playbackAsync.whenData((state) {
      if (state.playing) {
        if (!_rotationController.isAnimating) _rotationController.repeat();
      } else {
        _rotationController.stop();
      }
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.playerGradient : AppColors.playerGradientLight,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── App bar ──
              _PlayerAppBar(onBack: () => Navigator.of(context).pop()),

              // ── Main player area ──
              Expanded(
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.md),

                    // ── Album art disc with orbit rings ──
                    _AlbumArtDisc(
                      rotationController: _rotationController,
                      mediaItemAsync: mediaItemAsync,
                      musicAsync: musicAsync,
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // ── Glass controls card ──
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        child: _GlassControlCard(
                          isDark: isDark,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.xl - 4,
                              AppSpacing.lg,
                              AppSpacing.xl - 4,
                              AppSpacing.md,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title & Like
                                _TitleRow(
                                  mediaItemAsync: mediaItemAsync,
                                  isLiked: isLiked,
                                  onLikeToggle: () => _handleLikeToggle(ref),
                                ),

                                const SizedBox(height: AppSpacing.lg),

                                // Seek bar
                                StreamBuilder<PositionData>(
                                  stream: handler.positionDataStream,
                                  builder: (context, snapshot) {
                                    final pos = snapshot.data;
                                    if (pos == null || pos.duration == Duration.zero) {
                                      return const _SeekBarPlaceholder();
                                    }
                                    return _SeekBar(
                                      positionData: pos,
                                      isDragging: _isDragging,
                                      dragValue: _dragValue,
                                      onDragStart: (v) => setState(() {
                                        _isDragging = true;
                                        _dragValue = v;
                                      }),
                                      onDragEnd: (v) {
                                        if (pos.duration.inMilliseconds > 0) {
                                          handler.seek(Duration(
                                            milliseconds:
                                            (v * pos.duration.inMilliseconds).round(),
                                          ));
                                        }
                                        setState(() {
                                          _isDragging = false;
                                          _dragValue = null;
                                        });
                                      },
                                      formatDuration: _formatDuration,
                                    );
                                  },
                                ),

                                const SizedBox(height: AppSpacing.sm),

                                // Controls
                                _PlayerControls(
                                    handler: handler, playbackAsync: playbackAsync),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.sm),
                  ],
                ),
              ),

              // ── Related songs ──
              relatedAsync.when(
                data: (songs) {
                  if (songs.isEmpty) return const SizedBox.shrink();
                  return _RelatedSongsList(
                    songs: songs,
                    locale: locale,
                    handler: handler,
                    formatDuration: _formatDuration,
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLikeToggle(WidgetRef ref) async {
    try {
      await ref.read(favoritesProvider.notifier).toggleFavorite(widget.initialMusicId);
      final liked = ref.read(favoritesProvider).contains(widget.initialMusicId);
      ref
          .read(audioHandlerProvider)
          .updateMediaItemFavorite(widget.initialMusicId.toString(), liked);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}

// ════════════════════════════════════════════════
//  Sub-Widgets
// ════════════════════════════════════════════════

/// Glassmorphism container for the controls card.
class _GlassControlCard extends StatelessWidget {
  final bool isDark;
  final Widget child;
  const _GlassControlCard({required this.isDark, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.55),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.white.withValues(alpha: 0.7),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.08),
            blurRadius: 32,
            spreadRadius: -4,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _PlayerAppBar extends StatelessWidget {
  final VoidCallback onBack;
  const _PlayerAppBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    return Padding(
      padding:
      const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      child: Row(
        children: [
          // Back button with subtle glass pill
          _AppBarIconButton(
            icon: Icons.keyboard_arrow_down_rounded,
            color: textColor,
            size: 28,
            onTap: onBack,
          ),
          const Spacer(),
          Column(
            children: [
              Text(
                context.l10n.nowPlaying,
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 3),
                width: 20,
                height: 2,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(1),
                  gradient: LinearGradient(
                    colors: [
                      isDark ? AppColors.primaryDark : AppColors.primaryLight,
                      isDark
                          ? AppColors.primaryDark.withValues(alpha: 0)
                          : AppColors.primaryLight.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          _AppBarIconButton(
            icon: Icons.more_horiz_rounded,
            color: textColor.withValues(alpha: 0.55),
            size: 24,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _AppBarIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback onTap;
  const _AppBarIconButton(
      {required this.icon,
        required this.color,
        required this.size,
        required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.05),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.10)
                : Colors.black.withValues(alpha: 0.06),
            width: 1,
          ),
        ),
        child: Icon(icon, color: color, size: size),
      ),
    );
  }
}

/// Rotating album art disc with decorative orbit rings and glow.
class _AlbumArtDisc extends StatelessWidget {
  final AnimationController rotationController;
  final AsyncValue<MediaItem?> mediaItemAsync;
  final AsyncValue<dynamic> musicAsync;

  const _AlbumArtDisc({
    required this.rotationController,
    required this.mediaItemAsync,
    required this.musicAsync,
  });

  @override
  Widget build(BuildContext context) {
    final artUrl = mediaItemAsync.valueOrNull?.artUri?.toString() ??
        (musicAsync.valueOrNull?.thumbUrl as String?);
    final size = MediaQuery.of(context).size.width * 0.58;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return FadeScaleIn(
      duration: AppAnimations.entrance,
      child: SizedBox(
        width: size + 44,
        height: size + 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer orbit ring 1 — slow rotate opposite
            _OrbitRing(
              size: size + 40,
              strokeWidth: 1,
              color: accentColor.withValues(alpha: 0.18),
              dashPattern: true,
            ),
            // Outer orbit ring 2 — dashes
            _OrbitRing(
              size: size + 22,
              strokeWidth: 1.5,
              color: accentColor.withValues(alpha: 0.30),
            ),
            // Disc glow
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.35),
                    blurRadius: 40,
                    spreadRadius: 4,
                  ),
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.12),
                    blurRadius: 80,
                    spreadRadius: 12,
                  ),
                ],
              ),
            ),
            // Rotating disc
            AnimatedBuilder(
              animation: rotationController,
              builder: (_, child) => Transform.rotate(
                angle: rotationController.value * 2 * pi,
                child: child,
              ),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.0),
                      Colors.black.withValues(alpha: 0.12),
                      Colors.black.withValues(alpha: 0.0),
                    ],
                  ),
                ),
                child: ClipOval(
                  child: artUrl != null
                      ? CachedNetworkImage(
                    imageUrl: artUrl,
                    fit: BoxFit.cover,
                    memCacheWidth: (size * 2).toInt(),
                    placeholder: (_, __) => _placeholder(),
                    errorWidget: (_, __, ___) => _placeholder(),
                  )
                      : _placeholder(),
                ),
              ),
            ),
            // Center hole
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFEEEEF5),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
    color: AppColors.surfaceDark,
    child: const Center(
      child: Icon(Icons.music_note_rounded, color: AppColors.primaryDark, size: 64),
    ),
  );
}

/// Decorative ring drawn around the disc.
class _OrbitRing extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final Color color;
  final bool dashPattern;
  const _OrbitRing({
    required this.size,
    required this.strokeWidth,
    required this.color,
    this.dashPattern = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
            color: color, strokeWidth: strokeWidth, dashed: dashPattern),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final bool dashed;
  _RingPainter(
      {required this.color, required this.strokeWidth, this.dashed = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    if (!dashed) {
      canvas.drawCircle(center, radius, paint);
    } else {
      const dashCount = 32;
      for (int i = 0; i < dashCount; i++) {
        if (i % 2 == 0) {
          final startAngle = (2 * pi / dashCount) * i;
          final sweepAngle = (2 * pi / dashCount) * 0.6;
          canvas.drawArc(
            Rect.fromCircle(center: center, radius: radius),
            startAngle,
            sweepAngle,
            false,
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => false;
}

class _TitleRow extends StatelessWidget {
  final AsyncValue<MediaItem?> mediaItemAsync;
  final bool isLiked;
  final VoidCallback onLikeToggle;

  const _TitleRow({
    required this.mediaItemAsync,
    required this.isLiked,
    required this.onLikeToggle,
  });

  @override
  Widget build(BuildContext context) {
    final item = mediaItemAsync.valueOrNull;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item?.title ?? '—',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                item?.artist ?? context.l10n.unknownArtist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.50),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        GestureDetector(
          onTap: onLikeToggle,
          child: AnimatedContainer(
            duration: AppAnimations.fast,
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isLiked
                  ? const Color(0xFFFF6B6B).withValues(alpha: 0.15)
                  : textColor.withValues(alpha: 0.06),
              border: Border.all(
                color: isLiked
                    ? const Color(0xFFFF6B6B).withValues(alpha: 0.4)
                    : textColor.withValues(alpha: 0.10),
                width: 1,
              ),
            ),
            child: AnimatedSwitcher(
              duration: AppAnimations.fast,
              child: Icon(
                isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                key: ValueKey(isLiked),
                color: isLiked
                    ? const Color(0xFFFF6B6B)
                    : textColor.withValues(alpha: 0.45),
                size: 22,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Empty placeholder while duration is not yet known.
class _SeekBarPlaceholder extends StatelessWidget {
  const _SeekBarPlaceholder();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trackColor =
    (isDark ? Colors.white : Colors.black87).withValues(alpha: 0.10);
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 4,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: trackColor,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('00:00',
                  style: TextStyle(color: trackColor, fontSize: 12)),
              Text('00:00',
                  style: TextStyle(color: trackColor, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Seek bar with buffered progress.
class _SeekBar extends StatelessWidget {
  final PositionData positionData;
  final bool isDragging;
  final double? dragValue;
  final ValueChanged<double> onDragStart;
  final ValueChanged<double> onDragEnd;
  final String Function(Duration) formatDuration;

  const _SeekBar({
    required this.positionData,
    required this.isDragging,
    required this.dragValue,
    required this.onDragStart,
    required this.onDragEnd,
    required this.formatDuration,
  });

  @override
  Widget build(BuildContext context) {
    final position = positionData.position;
    final duration = positionData.duration;
    final buffered = positionData.bufferedPosition;

    final progress = duration.inMilliseconds > 0
        ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;
    final bufferedProgress = duration.inMilliseconds > 0
        ? (buffered.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;
    final sliderValue = isDragging ? (dragValue ?? progress) : progress;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Track background
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: Container(
                  height: 4,
                  color: textColor.withValues(alpha: 0.10),
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: bufferedProgress,
                    child: Container(color: textColor.withValues(alpha: 0.22)),
                  ),
                ),
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: primaryColor,
                  inactiveTrackColor: Colors.transparent,
                  secondaryActiveTrackColor: Colors.transparent,
                  thumbColor: Colors.white,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                  trackHeight: 4,
                  overlayColor: primaryColor.withValues(alpha: 0.15),
                  overlayShape:
                  const RoundSliderOverlayShape(overlayRadius: AppSpacing.md),
                  activeTickMarkColor: Colors.transparent,
                  inactiveTickMarkColor: Colors.transparent,
                  valueIndicatorColor: primaryColor,
                  disabledActiveTrackColor: Colors.transparent,
                  disabledInactiveTrackColor: Colors.transparent,
                  disabledThumbColor: Colors.white,
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: Theme.of(context).colorScheme.copyWith(
                      primary: primaryColor,
                      secondary: primaryColor,
                    ),
                  ),
                  child: Slider(
                    value: sliderValue.clamp(0.0, 1.0),
                    onChanged: onDragStart,
                    onChangeEnd: onDragEnd,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatDuration(isDragging && dragValue != null
                    ? Duration(
                    milliseconds:
                    (dragValue! * duration.inMilliseconds).round())
                    : position),
                style: TextStyle(
                    color: textColor.withValues(alpha: 0.50),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5),
              ),
              Text(
                formatDuration(duration),
                style: TextStyle(
                    color: textColor.withValues(alpha: 0.50),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlayerControls extends ConsumerWidget {
  final RhythmAudioHandler handler;
  final AsyncValue<PlaybackState> playbackAsync;

  const _PlayerControls({required this.handler, required this.playbackAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPlaying = playbackAsync.valueOrNull?.playing ?? false;
    final isShuffle = ref.watch(shuffleModeProvider).valueOrNull ?? false;
    final repeatMode = switch (ref.watch(loopModeProvider).valueOrNull) {
      LoopMode.all => AudioServiceRepeatMode.all,
      LoopMode.one => AudioServiceRepeatMode.one,
      _ => AudioServiceRepeatMode.none,
    };

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? Colors.white : Colors.black87;
    final accentColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return Column(
      children: [
        // Shuffle + Repeat row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _ToggleIconButton(
              icon: Icons.shuffle_rounded,
              active: isShuffle,
              activeColor: accentColor,
              inactiveColor: iconColor.withValues(alpha: 0.28),
              onTap: () => handler.setShuffleEnabled(!isShuffle),
            ),
            _ToggleIconButton(
              icon: repeatMode == AudioServiceRepeatMode.one
                  ? Icons.repeat_one_rounded
                  : Icons.repeat_rounded,
              active: repeatMode != AudioServiceRepeatMode.none,
              activeColor: accentColor,
              inactiveColor: iconColor.withValues(alpha: 0.28),
              onTap: () {
                final next = switch (repeatMode) {
                  AudioServiceRepeatMode.none => AudioServiceRepeatMode.all,
                  AudioServiceRepeatMode.all => AudioServiceRepeatMode.one,
                  _ => AudioServiceRepeatMode.none,
                };
                handler.setRepeatMode(next);
              },
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.sm),

        // ⏮  ⏸/▶  ⏭
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ControlButton(
              icon: Icons.skip_previous_rounded,
              size: AppSpacing.iconXl,
              color: iconColor,
              onTap: handler.skipToPrevious,
            ),
            const SizedBox(width: AppSpacing.lg),
            // Main play/pause — prominent gradient circle
            GestureDetector(
              onTap: () => isPlaying ? handler.pause() : handler.play(),
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: isDark
                        ? [AppColors.primaryDark, const Color(0xFF6C5CE7)]
                        : [AppColors.primaryLight, const Color(0xFF9B8DFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.45),
                      blurRadius: 24,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.20),
                      blurRadius: 48,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: AnimatedSwitcher(
                  duration: AppAnimations.fast + const Duration(milliseconds: 50),
                  child: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    key: ValueKey(isPlaying),
                    color: Colors.white,
                    size: 34,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            _ControlButton(
              icon: Icons.skip_next_rounded,
              size: AppSpacing.iconXl,
              color: iconColor,
              onTap: handler.skipToNext,
            ),
          ],
        ),
      ],
    );
  }
}

/// Shuffle/Repeat icon with active indicator dot beneath.
class _ToggleIconButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;
  const _ToggleIconButton({
    required this.icon,
    required this.active,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 44,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: active ? activeColor : inactiveColor, size: AppSpacing.iconMd),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: AppAnimations.fast,
              width: active ? 6 : 0,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: activeColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Related songs section.
class _RelatedSongsList extends StatelessWidget {
  final List<dynamic> songs;
  final String locale;
  final RhythmAudioHandler handler;
  final String Function(Duration) formatDuration;

  const _RelatedSongsList({
    required this.songs,
    required this.locale,
    required this.handler,
    required this.formatDuration,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 220),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding:
            const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xs),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 16,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        isDark ? AppColors.primaryDark : AppColors.primaryLight,
                        (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                            .withValues(alpha: 0.3),
                      ],
                    ),
                  ),
                ),
                Text(
                  context.l10n.upNext,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              itemCount: songs.length,
              itemBuilder: (context, index) {
                final song = songs[index];
                return MusicListTile(
                  title: song.getDisplayTitle(locale),
                  subtitle: song.getDisplayArtists(locale),
                  imageUrl: song.thumbUrl,
                  trailing: formatDuration(Duration(seconds: song.duration)),
                  onTap: () =>
                      handler.loadPlaylist([musicToMediaItem(song, locale)]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color color;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.size,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : Colors.black.withValues(alpha: 0.04),
          shape: BoxShape.circle,
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
        child: Icon(icon, color: color, size: size * 0.6),
      ),
    );
  }
}