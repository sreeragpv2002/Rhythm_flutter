import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:rhythm_flutter/core/theme/app_colors.dart';
import 'package:rhythm_flutter/core/extensions/context_extensions.dart';
import 'package:rhythm_flutter/core/services/audio_handler.dart';
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
  bool _isShuffle = false;
  int _repeatMode = 0; // 0=off, 1=all, 2=one
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

  void _toggleRepeat() {
    setState(() => _repeatMode = (_repeatMode + 1) % 3);
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

        // Sync liked status
        if (_isLiked != music.isFavorited) {
          setState(() => _isLiked = music.isFavorited);
        }

        // Load if it's not the song currently in the player, OR if it is but not playing
        if (currentItem?.id != music.id.toString()) {
          debugPrint('SongDetailScreen: Triggering playback for new song ${music.id}');
          _playMusic(music, handler, locale);
        } else if (playbackState != null && !playbackState.playing) {
          debugPrint('SongDetailScreen: Song already current but paused, calling play()');
          handler.play();
        }
      });
    });

    // Manually handle initial data if it's already loaded
    if (!musicAsync.isLoading && musicAsync.hasValue) {
      final music = musicAsync.value!;
      final currentItem = ref.read(currentMediaItemProvider).value;
      if (currentItem?.id != music.id.toString()) {
        // We use WidgetsBinding to ensure we don't trigger playback mid-build
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
      backgroundColor: AppColors.backgroundDark,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A0533), Color(0xFF0D0D1A), Color(0xFF0D0D1A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── App bar ──
              _buildAppBar(context),

              // ── Scrollable body ──
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),

                      // ── Album Art ──
                      _buildAlbumArt(mediaItemAsync, musicAsync, locale),

                      const SizedBox(height: 32),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Column(
                          children: [
                            // ── Title & Like ──
                            _buildTitleRow(mediaItemAsync, colorScheme),

                            const SizedBox(height: 28),

                            // ── Seek bar ──
                            positionAsync.when(
                              data: (pos) => _buildSeekBar(pos, handler, colorScheme),
                              loading: () => _buildSeekBar(null, handler, colorScheme),
                              error: (_, __) => const SizedBox(height: 48),
                            ),

                            const SizedBox(height: 20),

                            // ── Controls ──
                            playbackAsync.when(
                              data: (state) => _buildControls(state, handler, colorScheme),
                              loading: () => _buildControls(null, handler, colorScheme),
                              error: (_, __) => const SizedBox(height: 80),
                            ),

                            const SizedBox(height: 32),
                          ],
                        ),
                      ),

                      // ── Related songs ──
                      relatedAsync.when(
                        data: (songs) {
                          if (songs.isEmpty) return const SizedBox.shrink();
                          return _buildRelatedSongs(songs, locale, colorScheme, handler);
                        },
                        loading: () => const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (_, __) => const SizedBox.shrink(),
                      ),

                      const SizedBox(height: 40),
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

  // ────────────────────────────────────────────
  //  Widgets
  // ────────────────────────────────────────────

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.expand_more_rounded, color: Colors.white, size: 32),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Spacer(),
          Text(
            context.l10n.nowPlaying,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white70),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumArt(
      AsyncValue<MediaItem?> mediaItemAsync,
      AsyncValue<dynamic> musicAsync,
      String locale,
      ) {
    final artUrl = mediaItemAsync.valueOrNull?.artUri?.toString() ??
        (musicAsync.valueOrNull?.thumbUrl);

    return FadeInDown(
      duration: const Duration(milliseconds: 600),
      child: AnimatedBuilder(
        animation: _rotationController,
        builder: (context, child) {
          return Transform.rotate(
            angle: _rotationController.value * 2 * pi,
            child: child,
          );
        },
        child: Container(
          width: MediaQuery.of(context).size.width * 0.72,
          height: MediaQuery.of(context).size.width * 0.72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withValues(alpha: 0.45),
                blurRadius: 40,
                spreadRadius: 8,
              ),
            ],
          ),
          child: ClipOval(
            child: artUrl != null
                ? CachedNetworkImage(
              imageUrl: artUrl,
              fit: BoxFit.cover,
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

  Widget _buildTitleRow(AsyncValue<MediaItem?> mediaItemAsync, ColorScheme colorScheme) {
    final item = mediaItemAsync.valueOrNull;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeInUp(
                duration: const Duration(milliseconds: 400),
                child: Text(
                  item?.title ?? '—',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              FadeInUp(
                delay: const Duration(milliseconds: 100),
                duration: const Duration(milliseconds: 400),
                child: Text(
                  item?.artist ?? '—',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        FadeIn(
          delay: const Duration(milliseconds: 200),
          child: GestureDetector(
            onTap: () async {
              final music = ref.read(musicDetailsProvider(widget.initialMusicId)).valueOrNull;
              if (music == null) return;
              
              // Optimistic UI update
              setState(() => _isLiked = !_isLiked);
              
              try {
                final newStatus = await ref.read(musicRepositoryProvider).toggleFavorite(music.id);
                if (mounted && _isLiked != newStatus) {
                  setState(() => _isLiked = newStatus);
                }
              } catch (e) {
                // Revert on error
                if (mounted) {
                  setState(() => _isLiked = !_isLiked);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Icon(
                _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                key: ValueKey(_isLiked),
                color: _isLiked ? const Color(0xFFFF6B6B) : Colors.white54,
                size: 28,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSeekBar(PositionData? pos, dynamic handler, ColorScheme colorScheme) {
    final position = pos?.position ?? Duration.zero;
    final duration = pos?.duration ?? Duration.zero;
    final buffered = pos?.bufferedPosition ?? Duration.zero;

    final progress = duration.inMilliseconds > 0
        ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    final bufferedProgress = duration.inMilliseconds > 0
        ? (buffered.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    // Only use _dragValue if user is actively dragging
    final sliderValue = _isDragging ? _dragValue ?? progress : progress;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Buffered bar (behind)
              Container(
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: Colors.white.withValues(alpha: 0.12),
                ),
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: bufferedProgress,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                ),
              ),
              // Seek slider (on top)
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.primaryDark,
                  inactiveTrackColor: Colors.transparent,
                  thumbColor: Colors.white,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                  trackHeight: 4,
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                ),
                child: Slider(
                  value: sliderValue.clamp(0.0, 1.0),
                  onChanged: (value) {
                    setState(() {
                      _isDragging = true;
                      _dragValue = value;
                    });
                  },
                  onChangeEnd: (value) {
                    if (duration.inMilliseconds > 0) {
                      final seekPosition = Duration(
                        milliseconds: (value * duration.inMilliseconds).round(),
                      );
                      handler.seek(seekPosition);
                    }
                    setState(() {
                      _isDragging = false;
                      _dragValue = null;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(position),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                _formatDuration(duration),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControls(PlaybackState? state, dynamic handler, ColorScheme colorScheme) {
    final isPlaying = state?.playing ?? false;

    return Column(
      children: [
        // Shuffle + Repeat row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Shuffle toggle
            GestureDetector(
              onTap: () => setState(() => _isShuffle = !_isShuffle),
              child: Icon(
                Icons.shuffle_rounded,
                color: _isShuffle ? AppColors.primaryDark : Colors.white38,
                size: 24,
              ),
            ),
            // Repeat toggle
            GestureDetector(
              onTap: _toggleRepeat,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    _repeatMode == 2
                        ? Icons.repeat_one_rounded
                        : Icons.repeat_rounded,
                    color: _repeatMode > 0 ? AppColors.primaryDark : Colors.white38,
                    size: 24,
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Main controls row ⏮ ⏸/▶ ⏭
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Previous
            _ControlButton(
              icon: Icons.skip_previous_rounded,
              size: 48,
              color: Colors.white,
              onTap: () => handler.skipToPrevious(),
            ),

            const SizedBox(width: 20),

            // Play / Pause (big circle button)
            GestureDetector(
              onTap: () {
                if (isPlaying) {
                  handler.pause();
                } else {
                  handler.play();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryDark, Color(0xFF6C5CE7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryDark.withValues(alpha: 0.5),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    key: ValueKey(isPlaying),
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 20),

            // Next
            _ControlButton(
              icon: Icons.skip_next_rounded,
              size: 48,
              color: Colors.white,
              onTap: () => handler.skipToNext(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRelatedSongs(List<dynamic> songs, String locale, ColorScheme colorScheme, dynamic handler) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
          child: Text(
            context.l10n.upNext,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: songs.length,
          itemBuilder: (context, index) {
            final song = songs[index];
            return FadeInUp(
              delay: Duration(milliseconds: index * 60),
              duration: const Duration(milliseconds: 300),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: song.thumbUrl != null
                      ? CachedNetworkImage(
                    imageUrl: song.thumbUrl!,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _relatedPlaceholder(),
                  )
                      : _relatedPlaceholder(),
                ),
                title: Text(
                  song.getDisplayTitle(locale),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: Text(
                  song.getDisplayArtists(locale),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 12),
                ),
                trailing: Text(
                  _formatDuration(Duration(seconds: song.duration)),
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
                ),
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

  Widget _relatedPlaceholder() {
    return Container(
      width: 52,
      height: 52,
      color: AppColors.surfaceDark,
      child: const Icon(Icons.music_note_rounded, color: AppColors.primaryDark, size: 24),
    );
  }
}

// ────────────────────────────────────────────
// Small reusable control button
// ────────────────────────────────────────────
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: size * 0.6),
      ),
    );
  }
}