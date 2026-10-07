import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rhythm_flutter/core/extensions/context_extensions.dart';
import 'package:rhythm_flutter/core/services/audio_quality_service.dart';
import 'package:rhythm_flutter/core/theme/app_colors.dart';
import 'package:rhythm_flutter/core/theme/scroll_physics.dart';
import 'package:rhythm_flutter/features/home/providers/favorites_provider.dart';
import 'package:rhythm_flutter/features/player/providers/audio_provider.dart';

/// Right-hand music player sidebar for desktop viewports (width >= 960px).
class DesktopPlayerSidebar extends ConsumerStatefulWidget {
  const DesktopPlayerSidebar({super.key});

  @override
  ConsumerState<DesktopPlayerSidebar> createState() =>
      _DesktopPlayerSidebarState();
}

class _DesktopPlayerSidebarState extends ConsumerState<DesktopPlayerSidebar> {
  double? _dragSeekValue;
  bool _isDraggingSeek = false;
  double _currentVolume = 1.0;
  double _preMuteVolume = 1.0;

  @override
  void initState() {
    super.initState();
    final handler = ref.read(audioHandlerProvider);
    _currentVolume = handler.player.volume;
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mediaItemAsync = ref.watch(currentMediaItemProvider);
    final playbackAsync = ref.watch(playbackStateProvider);
    final handler = ref.read(audioHandlerProvider);

    final mediaItem = mediaItemAsync.valueOrNull;
    final playbackState = playbackAsync.valueOrNull;
    final isPlaying = playbackState?.playing ?? false;
    final processingState =
        playbackState?.processingState ?? AudioProcessingState.idle;
    final isLoading = processingState == AudioProcessingState.loading ||
        processingState == AudioProcessingState.buffering;

    final bgColor = isDark ? const Color(0xFF0D0D1B) : const Color(0xFFF7F6FD);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.07);

    return Container(
      width: 330,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(left: BorderSide(color: borderColor, width: 1)),
      ),
      child: mediaItem == null
          ? _buildIdleState(context, isDark)
          : _buildActivePlayer(
              context: context,
              mediaItem: mediaItem,
              isPlaying: isPlaying,
              isLoading: isLoading,
              isDark: isDark,
              handler: handler,
            ),
    );
  }

  /// Idle placeholder when no track is currently loaded
  Widget _buildIdleState(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primaryLight.withValues(alpha: 0.25),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.04),
                    border: Border.all(
                      color: (isDark ? Colors.white : Colors.black)
                          .withValues(alpha: 0.08),
                    ),
                  ),
                  child: Icon(
                    Icons.headphones_rounded,
                    size: 30,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Track Playing',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select any song or playlist from your home feed to begin listening in high-fidelity sound.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: isDark ? Colors.white38 : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Active track player panel with artwork, controls, seek bar, and volume
  Widget _buildActivePlayer({
    required BuildContext context,
    required MediaItem mediaItem,
    required bool isPlaying,
    required bool isLoading,
    required bool isDark,
    required RhythmAudioHandler handler,
  }) {
    final numericFavId = int.tryParse(mediaItem.id) ?? mediaItem.id.hashCode.abs();
    final isLiked = ref.watch(favoritesProvider).contains(numericFavId);

    return SingleChildScrollView(
      physics: AppScrollPhysics.adaptive,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Row ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isPlaying ? AppColors.success : Colors.white24,
                      shape: BoxShape.circle,
                      boxShadow: isPlaying
                          ? [
                              BoxShadow(
                                color: AppColors.success.withValues(alpha: 0.6),
                                blurRadius: 6,
                              ),
                            ]
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'NOW PLAYING',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(
                  Icons.fullscreen_rounded,
                  size: 22,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
                tooltip: 'Full Screen View',
                onPressed: () {
                  context.push('/player/${mediaItem.id}');
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Album Artwork ──
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryLight.withValues(alpha: 0.25),
                    blurRadius: 30,
                    offset: const Offset(0, 14),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.15),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: mediaItem.artUri != null
                    ? CachedNetworkImage(
                        imageUrl: mediaItem.artUri.toString(),
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _artPlaceholder(isDark),
                        errorWidget: (_, __, ___) => _artPlaceholder(isDark),
                      )
                    : _artPlaceholder(isDark),
              ),
            ),
          ),

          const SizedBox(height: 22),

          // ── Title & Artist + Favorite Toggle ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mediaItem.title.isNotEmpty
                          ? mediaItem.title
                          : context.l10n.appName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mediaItem.artist?.isNotEmpty == true
                          ? mediaItem.artist!
                          : context.l10n.unknownArtist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.55)
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (ref.watch(isCurrentSongYouTubeProvider)) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF0000).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.play_arrow_rounded, size: 11, color: Color(0xFFFF4B6E)),
                                SizedBox(width: 2),
                                Text(
                                  'YouTube Music',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFFF8DA1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          ref.watch(currentActiveQualityLabelProvider),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isLiked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    key: ValueKey(isLiked),
                    color: isLiked
                        ? const Color(0xFFFF6B6B)
                        : (isDark ? Colors.white38 : Colors.black38),
                    size: 24,
                  ),
                ),
                onPressed: () async {
                  await ref
                      .read(favoritesProvider.notifier)
                      .toggleFavorite(mediaItem.id);
                  final liked =
                      ref.read(favoritesProvider).contains(numericFavId);
                  handler.updateMediaItemFavorite(mediaItem.id, liked);
                },
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Interactive Scrubber Seek Bar ──
          StreamBuilder<PositionData>(
            stream: handler.positionDataStream,
            builder: (context, snapshot) {
              final pos = snapshot.data ??
                  PositionData(Duration.zero, Duration.zero, Duration.zero);
              final totalMs = pos.duration.inMilliseconds;
              final currentMs = pos.position.inMilliseconds;
              final progress = (totalMs > 0)
                  ? (currentMs / totalMs).clamp(0.0, 1.0)
                  : 0.0;

              final sliderValue =
                  _isDraggingSeek ? (_dragSeekValue ?? progress) : progress;

              return Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 6),
                      activeTrackColor: isDark
                          ? AppColors.primaryDark
                          : AppColors.primaryLight,
                      inactiveTrackColor: (isDark ? Colors.white : Colors.black)
                          .withValues(alpha: 0.12),
                      overlayShape:
                          const RoundSliderOverlayShape(overlayRadius: 14),
                      overlayColor: AppColors.primaryLight.withValues(alpha: 0.15),
                    ),
                    child: Slider(
                      value: sliderValue.clamp(0.0, 1.0),
                      onChanged: (val) {
                        setState(() {
                          _isDraggingSeek = true;
                          _dragSeekValue = val;
                        });
                      },
                      onChangeEnd: (val) {
                        final targetMs = (val * totalMs).round();
                        handler.seek(Duration(milliseconds: targetMs));
                        setState(() {
                          _isDraggingSeek = false;
                          _dragSeekValue = null;
                        });
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(pos.position),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white38 : Colors.black45,
                          ),
                        ),
                        Text(
                          _formatDuration(pos.duration),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white38 : Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 16),

          // ── Playback Controls ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Shuffle Toggle
              StreamBuilder<bool>(
                stream: handler.player.shuffleModeEnabledStream,
                builder: (context, snapshot) {
                  final isShuffle = snapshot.data ?? false;
                  return IconButton(
                    icon: Icon(
                      Icons.shuffle_rounded,
                      size: 20,
                      color: isShuffle
                          ? (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                          : (isDark ? Colors.white38 : Colors.black38),
                    ),
                    tooltip: isShuffle ? 'Shuffle On' : 'Shuffle Off',
                    onPressed: () {
                      handler.player.setShuffleModeEnabled(!isShuffle);
                    },
                  );
                },
              ),

              // Skip Previous
              IconButton(
                icon: Icon(
                  Icons.skip_previous_rounded,
                  size: 28,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
                tooltip: 'Previous',
                onPressed: handler.skipToPrevious,
              ),

              // Play / Pause FAB
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryLight.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () =>
                        isPlaying ? handler.pause() : handler.play(),
                    child: Center(
                      child: isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white),
                              ),
                            )
                          : Icon(
                              isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                    ),
                  ),
                ),
              ),

              // Skip Next
              IconButton(
                icon: Icon(
                  Icons.skip_next_rounded,
                  size: 28,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
                tooltip: 'Next',
                onPressed: handler.skipToNext,
              ),

              // Loop / Repeat Toggle
              StreamBuilder<LoopMode>(
                stream: handler.player.loopModeStream,
                builder: (context, snapshot) {
                  final loop = snapshot.data ?? LoopMode.off;
                  final isLooping = loop != LoopMode.off;
                  return IconButton(
                    icon: Icon(
                      loop == LoopMode.one
                          ? Icons.repeat_one_rounded
                          : Icons.repeat_rounded,
                      size: 20,
                      color: isLooping
                          ? (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                          : (isDark ? Colors.white38 : Colors.black38),
                    ),
                    tooltip: loop.name.toUpperCase(),
                    onPressed: () {
                      final next = loop == LoopMode.off
                          ? LoopMode.all
                          : (loop == LoopMode.all ? LoopMode.one : LoopMode.off);
                      handler.player.setLoopMode(next);
                    },
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Volume Control Slider ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black)
                    .withValues(alpha: 0.05),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  icon: Icon(
                    _currentVolume <= 0.01
                        ? Icons.volume_off_rounded
                        : (_currentVolume < 0.5
                            ? Icons.volume_down_rounded
                            : Icons.volume_up_rounded),
                    size: 18,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                  tooltip: _currentVolume <= 0.01 ? 'Unmute' : 'Mute',
                  onPressed: () {
                    setState(() {
                      if (_currentVolume > 0.01) {
                        _preMuteVolume = _currentVolume;
                        _currentVolume = 0.0;
                      } else {
                        _currentVolume =
                            _preMuteVolume > 0.01 ? _preMuteVolume : 0.8;
                      }
                      handler.player.setVolume(_currentVolume);
                    });
                  },
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 5),
                      activeTrackColor: isDark
                          ? AppColors.primaryDark
                          : AppColors.primaryLight,
                      inactiveTrackColor: (isDark ? Colors.white : Colors.black)
                          .withValues(alpha: 0.12),
                      overlayShape:
                          const RoundSliderOverlayShape(overlayRadius: 10),
                    ),
                    child: Slider(
                      value: _currentVolume.clamp(0.0, 1.0),
                      onChanged: (val) {
                        setState(() => _currentVolume = val);
                        handler.player.setVolume(val);
                      },
                    ),
                  ),
                ),
                Text(
                  '${(_currentVolume * 100).round()}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white38 : Colors.black45,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Audio Quality Info Badge (Clickable for Quality Switcher) ──
          Consumer(
            builder: (context, ref, _) {
              final qualityLabel = ref.watch(currentActiveQualityLabelProvider);
              final pref = ref.watch(audioQualityPreferenceProvider);
              final isAuto = pref == AudioQualityPreference.auto;

              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _showDesktopQualityDialog(context, ref, handler),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.04)
                        : Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (isDark ? Colors.white : Colors.black)
                          .withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.graphic_eq_rounded,
                        size: 16,
                        color: isDark
                            ? AppColors.primaryDark
                            : AppColors.primaryLight,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          qualityLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (isAuto
                                  ? const Color(0xFF00E676)
                                  : (isDark ? AppColors.primaryDark : AppColors.primaryLight))
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isAuto ? 'AUTO' : 'HQ',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.6,
                            color: isAuto
                                ? const Color(0xFF00E676)
                                : (isDark ? AppColors.primaryDark : AppColors.primaryLight),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showDesktopQualityDialog(BuildContext context, WidgetRef ref, RhythmAudioHandler handler) {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final currentPref = ref.watch(audioQualityPreferenceProvider);
        final speedService = ref.watch(networkSpeedServiceProvider);
        final speedKbpsAsync = ref.watch(networkSpeedKbpsProvider);
        final gradeAsync = ref.watch(networkSpeedGradeProvider);

        final speedKbps = speedKbpsAsync.valueOrNull ?? speedService.currentSpeedKbps;
        final grade = gradeAsync.valueOrNull ?? speedService.currentGrade;
        final songQualities = ref.watch(currentSongQualitiesProvider);

        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF16162C) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.graphic_eq_rounded, color: AppColors.primaryLight, size: 22),
              const SizedBox(width: 10),
              const Text('Streaming Audio Quality', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Network Speed: ${(speedKbps / 1000.0).toStringAsFixed(1)} Mbps (${grade.label})',
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                ),
                const SizedBox(height: 12),
                ...AudioQualityPreference.values.map((pref) {
                  final isSelected = currentPref == pref;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: isSelected ? AppColors.primaryLight : Colors.white38,
                    ),
                    title: Text(pref.title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                    subtitle: Text(pref.subtitle, style: const TextStyle(fontSize: 11)),
                    onTap: () async {
                      await ref.read(audioQualityPreferenceProvider.notifier).setPreference(pref);
                      if (songQualities.isNotEmpty) {
                        final target = AdaptiveAudioQualitySelector.resolveQuality(
                          availableQualities: songQualities,
                          preference: pref,
                          currentGrade: grade,
                        );
                        if (target != null) {
                          await handler.switchCurrentSongQuality(target);
                        }
                      }
                      if (context.mounted) Navigator.pop(context);
                    },
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  Widget _artPlaceholder(bool isDark) {
    return Container(
      color: isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceElevatedLight,
      child: Center(
        child: Icon(
          Icons.music_note_rounded,
          size: 64,
          color: isDark ? Colors.white24 : Colors.black26,
        ),
      ),
    );
  }
}
