import 'dart:math';
import 'dart:ui';
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
import 'package:rhythm_flutter/core/services/media_item_mapper.dart';
import 'package:rhythm_flutter/core/widgets/music_list_tile.dart';
import 'package:rhythm_flutter/features/home/data/models/music.dart';
import 'package:rhythm_flutter/features/home/data/repositories/music_repository.dart';
import 'package:rhythm_flutter/features/player/providers/audio_provider.dart';
import 'package:rhythm_flutter/features/player/providers/music_detail_provider.dart';

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
  bool _isLiked = false;
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
    final mediaItem = musicToMediaItem(music, locale);
    handler.loadPlaylist([mediaItem]);
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.l10n.localeName;
    final mediaItemAsync = ref.watch(currentMediaItemProvider);
    final playbackAsync = ref.watch(playbackStateProvider);
    final positionAsync = ref.watch(positionDataProvider);
    final handler = ref.read(audioHandlerProvider);
    final colorScheme = context.colorScheme;
    final musicAsync = ref.watch(musicDetailsProvider(widget.initialMusicId));
    final relatedAsync = ref.watch(relatedSongsProvider(widget.initialMusicId));

    // Listen for music details to trigger playback
    ref.listen<AsyncValue<Music>>(musicDetailsProvider(widget.initialMusicId), (prev, next) {
      if (next.isLoading) return;
      next.whenData((music) {
        final currentItem = ref.read(currentMediaItemProvider).value;
        final playbackState = ref.read(playbackStateProvider).value;

        if (_isLiked != music.isFavorited) {
          setState(() => _isLiked = music.isFavorited);
        }

        if (currentItem?.id != music.id.toString()) {
          _playMusic(music, handler, locale);
        } else if (playbackState != null && !playbackState.playing) {
          handler.play();
        }
      });
    });

    // Handle initial data if already loaded
    if (!musicAsync.isLoading && musicAsync.hasValue) {
      final music = musicAsync.value!;
      final currentItem = ref.read(currentMediaItemProvider).value;
      if (currentItem?.id != music.id.toString()) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            final playbackState = ref.read(playbackStateProvider).value;
            if (ref.read(currentMediaItemProvider).value?.id != music.id.toString()) {
              _playMusic(music, handler, locale);
            } else if (playbackState != null && !playbackState.playing) {
              handler.play();
            }
          }
        });
      }
    }

    // Sync rotation with playback
    playbackAsync.whenData((state) {
      if (state.playing) {
        if (!_rotationController.isAnimating) _rotationController.repeat();
      } else {
        _rotationController.stop();
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: Theme.of(context).brightness == Brightness.dark 
              ? AppColors.playerGradient 
              : AppColors.playerGradientLight,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _PlayerAppBar(onBack: () => Navigator.of(context).pop()),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: AppSpacing.md),

                      // ── Album Art ──
                      _AlbumArtDisc(
                        rotationController: _rotationController,
                        mediaItemAsync: mediaItemAsync,
                        musicAsync: musicAsync,
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl - 4),
                        child: Column(
                          children: [
                            // ── Title & Like ──
                            _TitleRow(
                              mediaItemAsync: mediaItemAsync,
                              isLiked: _isLiked,
                              onLikeToggle: () => _handleLikeToggle(ref),
                            ),

                            const SizedBox(height: AppSpacing.xl - 4),

                            // ── Seek bar ──
                            positionAsync.when(
                              data: (pos) => _SeekBar(
                                positionData: pos,
                                handler: handler,
                                isDragging: _isDragging,
                                dragValue: _dragValue,
                                onDragStart: (v) => setState(() { _isDragging = true; _dragValue = v; }),
                                onDragEnd: (v) {
                                  if (pos.duration.inMilliseconds > 0) {
                                    handler.seek(Duration(milliseconds: (v * pos.duration.inMilliseconds).round()));
                                  }
                                  setState(() { _isDragging = false; _dragValue = null; });
                                },
                                formatDuration: _formatDuration,
                              ),
                              loading: () => const SizedBox(height: AppSpacing.xxl),
                              error: (_, __) => const SizedBox(height: AppSpacing.xxl),
                            ),

                            const SizedBox(height: AppSpacing.lg - 4),

                            // ── Controls ──
                            _PlayerControls(handler: handler, playbackAsync: playbackAsync),

                            const SizedBox(height: AppSpacing.xl),
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
                        loading: () => const Padding(
                          padding: EdgeInsets.all(AppSpacing.lg),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (_, __) => const SizedBox.shrink(),
                      ),

                      const SizedBox(height: AppSpacing.xxl - 8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLikeToggle(WidgetRef ref) async {
    final music = ref.read(musicDetailsProvider(widget.initialMusicId)).valueOrNull;
    if (music == null) return;

    setState(() => _isLiked = !_isLiked);

    try {
      final newStatus = await ref.read(musicRepositoryProvider).toggleFavorite(music.id);
      if (mounted && _isLiked != newStatus) {
        setState(() => _isLiked = newStatus);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLiked = !_isLiked);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

// ════════════════════════════════════════════════
//  Extracted Sub-Widgets
// ════════════════════════════════════════════════

/// Top bar with collapse and menu buttons.
class _PlayerAppBar extends StatelessWidget {
  final VoidCallback onBack;
  const _PlayerAppBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.expand_more_rounded, color: textColor, size: AppSpacing.iconLg),
            onPressed: onBack,
          ),
          const Spacer(),
          Text(
            context.l10n.nowPlaying,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.more_vert_rounded, color: textColor.withValues(alpha: 0.7)),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

/// Rotating album art disc with glassmorphism glow.
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
        (musicAsync.valueOrNull?.thumbUrl);
    final size = MediaQuery.of(context).size.width * 0.72;

    return FadeScaleIn(
      duration: AppAnimations.entrance,
      child: AnimatedBuilder(
        animation: rotationController,
        builder: (context, child) {
          return Transform.rotate(
            angle: rotationController.value * 2 * pi,
            child: child,
          );
        },
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: GlassDecoration.glow(AppColors.primaryDark, intensity: 0.45),
          ),
          child: ClipOval(
            child: artUrl != null
                ? CachedNetworkImage(
                    imageUrl: artUrl,
                    fit: BoxFit.cover,
                    memCacheWidth: (size * 2).toInt(),
                    placeholder: (_, __) => _albumPlaceholder(),
                    errorWidget: (_, __, ___) => _albumPlaceholder(),
                  )
                : _albumPlaceholder(),
          ),
        ),
      ),
    );
  }

  Widget _albumPlaceholder() {
    return Container(
      color: AppColors.surfaceDark,
      child: const Center(
        child: Icon(Icons.music_note_rounded, color: AppColors.primaryDark, size: 80),
      ),
    );
  }
}

/// Song title row with like button.
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
              SlideUpFadeIn(
                duration: AppAnimations.normal,
                child: Text(
                  item?.title ?? '—',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              SlideUpFadeIn(
                delay: const Duration(milliseconds: 100),
                duration: AppAnimations.normal,
                child: Text(
                  item?.artist ?? '—',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.65),
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm + 4),
        FadeScaleIn(
          delay: const Duration(milliseconds: 200),
          child: GestureDetector(
            onTap: onLikeToggle,
            child: AnimatedSwitcher(
              duration: AppAnimations.fast,
              child: Icon(
                isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                key: ValueKey(isLiked),
                color: isLiked ? const Color(0xFFFF6B6B) : textColor.withValues(alpha: 0.54),
                size: 28,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Seek bar with buffered progress and drag support.
class _SeekBar extends StatelessWidget {
  final PositionData positionData;
  final RhythmAudioHandler handler;
  final bool isDragging;
  final double? dragValue;
  final ValueChanged<double> onDragStart;
  final ValueChanged<double> onDragEnd;
  final String Function(Duration) formatDuration;

  const _SeekBar({
    required this.positionData,
    required this.handler,
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
    final sliderValue = isDragging ? dragValue ?? progress : progress;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 4),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Buffered bar
              Container(
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: textColor.withValues(alpha: 0.12),
                ),
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: bufferedProgress,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: textColor.withValues(alpha: 0.25),
                    ),
                  ),
                ),
              ),
              // Seek slider
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                  inactiveTrackColor: Colors.transparent,
                  thumbColor: textColor,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                  trackHeight: 4,
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: AppSpacing.md),
                ),
                child: Slider(
                  value: sliderValue.clamp(0.0, 1.0),
                  onChanged: onDragStart,
                  onChangeEnd: onDragEnd,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatDuration(position),
                style: TextStyle(color: textColor.withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.w500),
              ),
              Text(
                formatDuration(duration),
                style: TextStyle(color: textColor.withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Main playback controls with shuffle/repeat wired to the audio handler.
class _PlayerControls extends ConsumerWidget {
  final RhythmAudioHandler handler;
  final AsyncValue<PlaybackState> playbackAsync;

  const _PlayerControls({
    required this.handler,
    required this.playbackAsync,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPlaying = playbackAsync.valueOrNull?.playing ?? false;
    final shuffleAsync = ref.watch(shuffleModeProvider);
    final loopAsync = ref.watch(loopModeProvider);

    final isShuffle = shuffleAsync.valueOrNull ?? false;
    final repeatMode = loopAsync.valueOrNull ?? AudioServiceRepeatMode.none;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? Colors.white : Colors.black87;

    return Column(
      children: [
        // Shuffle + Repeat row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => handler.setShuffleEnabled(!isShuffle),
              child: Icon(
                Icons.shuffle_rounded,
                color: isShuffle
                    ? (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                    : iconColor.withValues(alpha: 0.38),
                size: AppSpacing.iconMd,
              ),
            ),
            GestureDetector(
              onTap: () {
                final nextMode = switch (repeatMode) {
                  AudioServiceRepeatMode.none => AudioServiceRepeatMode.all,
                  AudioServiceRepeatMode.all => AudioServiceRepeatMode.one,
                  _ => AudioServiceRepeatMode.none,
                };
                handler.setRepeatMode(nextMode);
              },
              child: Icon(
                repeatMode == AudioServiceRepeatMode.one
                    ? Icons.repeat_one_rounded
                    : Icons.repeat_rounded,
                color: repeatMode != AudioServiceRepeatMode.none
                    ? (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                    : iconColor.withValues(alpha: 0.38),
                size: AppSpacing.iconMd,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: AppSpacing.lg),

        // Main controls: ⏮ ⏸/▶ ⏭
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ControlButton(
              icon: Icons.skip_previous_rounded,
              size: AppSpacing.iconXl,
              color: iconColor,
              onTap: handler.skipToPrevious,
            ),
            const SizedBox(width: AppSpacing.lg - 4),

            // Play / Pause (big circle)
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
                  boxShadow: GlassDecoration.glow(
                    isDark ? AppColors.primaryDark : AppColors.primaryLight, 
                    intensity: 0.5,
                  ),
                ),
                child: AnimatedSwitcher(
                  duration: AppAnimations.fast + const Duration(milliseconds: 50),
                  child: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    key: ValueKey(isPlaying),
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
            ),

            const SizedBox(width: AppSpacing.lg - 4),
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

/// Related songs section using shared MusicListTile.
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm + 4),
          child: Text(
            context.l10n.upNext,
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          itemCount: songs.length,
          itemBuilder: (context, index) {
            final song = songs[index];
            return SlideUpFadeIn(
              delay: AppAnimations.stagger(index, baseMs: 60),
              duration: AppAnimations.normal,
              child: MusicListTile(
                title: song.getDisplayTitle(locale),
                subtitle: song.getDisplayArtists(locale),
                imageUrl: song.thumbUrl,
                trailing: formatDuration(Duration(seconds: song.duration)),
                onTap: () {
                  final mediaItem = musicToMediaItem(song, locale);
                  handler.loadPlaylist([mediaItem]);
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Small reusable control button.
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
    final surfaceColor = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: surfaceColor,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: size * 0.6),
      ),
    );
  }
}