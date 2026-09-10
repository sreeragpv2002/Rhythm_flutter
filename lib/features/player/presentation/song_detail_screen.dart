import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rhythm_flutter/core/theme/app_colors.dart';
import 'package:rhythm_flutter/core/extensions/context_extensions.dart';
import 'package:rhythm_flutter/core/services/audio_handler.dart';
import 'package:rhythm_flutter/core/services/audio_quality_service.dart';
import 'package:rhythm_flutter/features/home/data/models/music.dart';
import 'package:rhythm_flutter/features/player/providers/audio_provider.dart';
import 'package:rhythm_flutter/features/player/providers/music_detail_provider.dart';
import 'package:rhythm_flutter/features/home/providers/favorites_provider.dart';
import 'package:rhythm_flutter/features/playlist/presentation/widgets/add_to_playlist_sheet.dart';

/// Modern, responsive Music Player Screen with ambient artwork glow,
/// dynamic scaling, glassmorphic controls, and zero-overflow layout.
class SongDetailScreen extends ConsumerStatefulWidget {
  final dynamic initialMusicId;
  const SongDetailScreen({super.key, required this.initialMusicId});

  @override
  ConsumerState<SongDetailScreen> createState() => _SongDetailScreenState();
}

class _SongDetailScreenState extends ConsumerState<SongDetailScreen> {
  double? _dragValue;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();

    // Trigger playback immediately if target song differs from current media
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final targetId = widget.initialMusicId.toString();
      if (targetId.isNotEmpty && targetId != '0') {
        final currentItem = ref.read(currentMediaItemProvider).value;
        if (currentItem?.id != targetId) {
          final cached = ref.read(musicDetailsProvider(targetId));
          cached.whenData((music) {
            _playMusic(
              music,
              ref.read(audioHandlerProvider),
              context.l10n.localeName,
            );
          });
        }
      }
    });
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
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = context.l10n.localeName;
    final mediaItemAsync = ref.watch(currentMediaItemProvider);
    final playbackAsync = ref.watch(playbackStateProvider);
    final handler = ref.read(audioHandlerProvider);

    // Support skipping: use currently playing ID if audio handler moved on
    final currentItem = mediaItemAsync.valueOrNull;
    final effectiveId = (currentItem != null && currentItem.id.isNotEmpty)
        ? currentItem.id
        : widget.initialMusicId.toString();

    final musicAsync = ref.watch(musicDetailsProvider(effectiveId));
    final relatedAsync = ref.watch(relatedSongsProvider(effectiveId));

    final numericFavId =
        int.tryParse(effectiveId) ?? effectiveId.hashCode.abs();
    final isLiked = ref.watch(favoritesProvider).contains(numericFavId);

    ref.listen<AsyncValue<Music>>(
      musicDetailsProvider(widget.initialMusicId.toString()),
      (prev, next) {
        if (next.isLoading || next.hasError) return;
        next.whenData((music) {
          ref.read(favoritesProvider.notifier).initFromList([music]);

          final currentItem = ref.read(currentMediaItemProvider).value;
          final targetId = widget.initialMusicId.toString();
          if (targetId != '0' &&
              currentItem?.id != targetId &&
              currentItem?.id != music.rawStringId) {
            _playMusic(music, handler, locale);
          }
        });
      },
    );

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0C0B14) : const Color(0xFFF2F0F9),
      body: Stack(
        children: [
          // ── Ambient Background Glow ──
          _ModernAmbientBackground(
            isDark: isDark,
            mediaItemAsync: mediaItemAsync,
            musicAsync: musicAsync,
            initialId: effectiveId,
          ),

          // ── Main Responsive Content ──
          SafeArea(
            child: width > 900
                ? _DesktopPlayerLayout(
                    width: width,
                    height: height,
                    mediaItemAsync: mediaItemAsync,
                    musicAsync: musicAsync,
                    playbackAsync: playbackAsync,
                    handler: handler,
                    isLiked: isLiked,
                    onLikeToggle: () => _handleLikeToggle(ref, effectiveId),
                    formatDuration: _formatDuration,
                    relatedAsync: relatedAsync,
                    locale: locale,
                    initialMusicId: effectiveId,
                    isDragging: _isDragging,
                    dragValue: _dragValue,
                    onDragStart: (v) => setState(() {
                      _isDragging = true;
                      _dragValue = v;
                    }),
                    onDragEnd: (v) {
                      final duration =
                          mediaItemAsync.value?.duration ?? Duration.zero;
                      handler.seek(Duration(
                          milliseconds:
                              (v * duration.inMilliseconds).round()));
                      setState(() {
                        _isDragging = false;
                        _dragValue = null;
                      });
                    },
                  )
                : _MobilePlayerLayout(
                    width: width,
                    height: height,
                    mediaItemAsync: mediaItemAsync,
                    musicAsync: musicAsync,
                    playbackAsync: playbackAsync,
                    handler: handler,
                    isLiked: isLiked,
                    onLikeToggle: () => _handleLikeToggle(ref, effectiveId),
                    formatDuration: _formatDuration,
                    relatedAsync: relatedAsync,
                    locale: locale,
                    initialMusicId: effectiveId,
                    isDragging: _isDragging,
                    dragValue: _dragValue,
                    onDragStart: (v) => setState(() {
                      _isDragging = true;
                      _dragValue = v;
                    }),
                    onDragEnd: (v) {
                      final duration =
                          mediaItemAsync.value?.duration ?? Duration.zero;
                      handler.seek(Duration(
                          milliseconds:
                              (v * duration.inMilliseconds).round()));
                      setState(() {
                        _isDragging = false;
                        _dragValue = null;
                      });
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLikeToggle(WidgetRef ref, String songId) async {
    final numericId = int.tryParse(songId) ?? songId.hashCode.abs();
    await ref.read(favoritesProvider.notifier).toggleFavorite(songId);
    final liked = ref.read(favoritesProvider).contains(numericId);
    ref.read(audioHandlerProvider).updateMediaItemFavorite(songId, liked);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 📱 MOBILE MODERN PLAYER LAYOUT (NO OVERFLOW)
// ─────────────────────────────────────────────────────────────────────────────

class _MobilePlayerLayout extends ConsumerWidget {
  final double width;
  final double height;
  final AsyncValue<MediaItem?> mediaItemAsync;
  final AsyncValue<Music> musicAsync;
  final AsyncValue<PlaybackState> playbackAsync;
  final RhythmAudioHandler handler;
  final bool isLiked;
  final VoidCallback onLikeToggle;
  final String Function(Duration) formatDuration;
  final AsyncValue<List<Music>> relatedAsync;
  final String locale;
  final String initialMusicId;
  final bool isDragging;
  final double? dragValue;
  final ValueChanged<double> onDragStart;
  final ValueChanged<double> onDragEnd;

  const _MobilePlayerLayout({
    required this.width,
    required this.height,
    required this.mediaItemAsync,
    required this.musicAsync,
    required this.playbackAsync,
    required this.handler,
    required this.isLiked,
    required this.onLikeToggle,
    required this.formatDuration,
    required this.relatedAsync,
    required this.locale,
    required this.initialMusicId,
    required this.isDragging,
    required this.dragValue,
    required this.onDragStart,
    required this.onDragEnd,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPlaying = playbackAsync.valueOrNull?.playing ?? false;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              // ── Top Bar ──
              _ModernPlayerTopBar(
                onDismiss: () => context.pop(),
                onOpenQueue: () => _UpNextBottomSheet.show(
                  context,
                  songs: relatedAsync.value ?? [],
                  locale: locale,
                  handler: handler,
                ),
                onOpenSettings: () =>
                    _AudioQualityBottomSheet.show(context, ref, handler),
              ),

              // ── Album Artwork (Flexibly scaled to guarantee no overflow) ──
              Expanded(
                flex: 10,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: _ModernArtworkCard(
                      mediaItemAsync: mediaItemAsync,
                      musicAsync: musicAsync,
                      playbackAsync: playbackAsync,
                      initialId: initialMusicId,
                      isPlaying: isPlaying,
                    ),
                  ),
                ),
              ),

              // ── Song Info & Favorite ──
              _ModernMetadataSection(
                mediaItemAsync: mediaItemAsync,
                musicAsync: musicAsync,
                playbackAsync: playbackAsync,
                initialId: initialMusicId,
                isLiked: isLiked,
                onLikeToggle: onLikeToggle,
                onQualityTap: () =>
                    _AudioQualityBottomSheet.show(context, ref, handler),
              ),

              const SizedBox(height: 12),

              // ── Modern Sleek Seekbar ──
              _ModernSeekbar(
                handler: handler,
                isDragging: isDragging,
                dragValue: dragValue,
                onDragStart: onDragStart,
                onDragEnd: onDragEnd,
                formatDuration: formatDuration,
              ),

              const SizedBox(height: 14),

              // ── Modern Playback Controls Row ──
              _ModernControlsRow(
                handler: handler,
                playbackAsync: playbackAsync,
              ),

              const SizedBox(height: 14),

              // ── Bottom Quick Actions (Queue, Lyrics, Quality) ──
              _BottomQuickActionsRow(
                onQueueTap: () => _UpNextBottomSheet.show(
                  context,
                  songs: relatedAsync.value ?? [],
                  locale: locale,
                  handler: handler,
                ),
                onQualityTap: () =>
                    _AudioQualityBottomSheet.show(context, ref, handler),
                isDark: isDark,
              ),

              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 🖥️ DESKTOP MODERN PLAYER LAYOUT
// ─────────────────────────────────────────────────────────────────────────────

class _DesktopPlayerLayout extends ConsumerWidget {
  final double width;
  final double height;
  final AsyncValue<MediaItem?> mediaItemAsync;
  final AsyncValue<Music> musicAsync;
  final AsyncValue<PlaybackState> playbackAsync;
  final RhythmAudioHandler handler;
  final bool isLiked;
  final VoidCallback onLikeToggle;
  final String Function(Duration) formatDuration;
  final AsyncValue<List<Music>> relatedAsync;
  final String locale;
  final String initialMusicId;
  final bool isDragging;
  final double? dragValue;
  final ValueChanged<double> onDragStart;
  final ValueChanged<double> onDragEnd;

  const _DesktopPlayerLayout({
    required this.width,
    required this.height,
    required this.mediaItemAsync,
    required this.musicAsync,
    required this.playbackAsync,
    required this.handler,
    required this.isLiked,
    required this.onLikeToggle,
    required this.formatDuration,
    required this.relatedAsync,
    required this.locale,
    required this.initialMusicId,
    required this.isDragging,
    required this.dragValue,
    required this.onDragStart,
    required this.onDragEnd,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPlaying = playbackAsync.valueOrNull?.playing ?? false;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Container(
        margin: EdgeInsets.all(height * 0.04),
        constraints: BoxConstraints(
          maxWidth: width * 0.85,
          maxHeight: height * 0.85,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.2),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Row(
              children: [
                // ── Left: Artwork with Ambient Glow ──
                Expanded(
                  flex: 5,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(36),
                      child: _ModernArtworkCard(
                        mediaItemAsync: mediaItemAsync,
                        musicAsync: musicAsync,
                        playbackAsync: playbackAsync,
                        initialId: initialMusicId,
                        isPlaying: isPlaying,
                      ),
                    ),
                  ),
                ),

                VerticalDivider(
                  width: 1,
                  color: Colors.white.withValues(alpha: 0.1),
                ),

                // ── Right: Controls + Up Next Queue ──
                Expanded(
                  flex: 6,
                  child: Padding(
                    padding: const EdgeInsets.all(36),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ModernPlayerTopBar(
                          onDismiss: () => context.pop(),
                          onOpenQueue: () {},
                          onOpenSettings: () => _AudioQualityBottomSheet.show(
                              context, ref, handler),
                        ),
                        const Spacer(),
                        _ModernMetadataSection(
                          mediaItemAsync: mediaItemAsync,
                          musicAsync: musicAsync,
                          playbackAsync: playbackAsync,
                          initialId: initialMusicId,
                          isLiked: isLiked,
                          onLikeToggle: onLikeToggle,
                          onQualityTap: () => _AudioQualityBottomSheet.show(
                              context, ref, handler),
                        ),
                        const SizedBox(height: 20),
                        _ModernSeekbar(
                          handler: handler,
                          isDragging: isDragging,
                          dragValue: dragValue,
                          onDragStart: onDragStart,
                          onDragEnd: onDragEnd,
                          formatDuration: formatDuration,
                        ),
                        const SizedBox(height: 20),
                        _ModernControlsRow(
                          handler: handler,
                          playbackAsync: playbackAsync,
                        ),
                        const Spacer(),
                        Text(
                          'UP NEXT',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          flex: 5,
                          child: ListView.builder(
                            itemCount: relatedAsync.value?.length ?? 0,
                            itemBuilder: (context, i) => _CompactTile(
                              index: i,
                              songs: relatedAsync.value!,
                              locale: locale,
                              handler: handler,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 🎨 MODERN ARTWORK CARD (SQUIRCLE WITH DYNAMIC ELEVATION & GLOW)
// ─────────────────────────────────────────────────────────────────────────────

class _ModernArtworkCard extends StatelessWidget {
  final AsyncValue<MediaItem?> mediaItemAsync;
  final AsyncValue<Music> musicAsync;
  final AsyncValue<PlaybackState> playbackAsync;
  final String initialId;
  final bool isPlaying;

  const _ModernArtworkCard({
    required this.mediaItemAsync,
    required this.musicAsync,
    required this.playbackAsync,
    required this.initialId,
    required this.isPlaying,
  });

  @override
  Widget build(BuildContext context) {
    final mediaItem = mediaItemAsync.valueOrNull;
    final music = musicAsync.valueOrNull;
    final processingState =
        playbackAsync.valueOrNull?.processingState ?? AudioProcessingState.idle;

    final bool isLoading = processingState == AudioProcessingState.loading ||
        processingState == AudioProcessingState.buffering ||
        (mediaItem == null && musicAsync.isLoading);

    final bool isCorrectSong = mediaItem?.id == initialId ||
        (mediaItem == null && music?.id.toString() == initialId);
    final String? artUrl = isCorrectSong
        ? (mediaItem?.artUri?.toString() ?? music?.thumbUrl)
        : music?.thumbUrl;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Compute optimal square dimension within constraints
        final maxSide = constraints.biggest.shortestSide;
        final size = maxSide.clamp(160.0, 360.0);

        return AnimatedScale(
          scale: isPlaying ? 1.0 : 0.94,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isPlaying ? 0.45 : 0.25),
                  blurRadius: isPlaying ? 35 : 20,
                  offset: Offset(0, isPlaying ? 16 : 10),
                ),
              ],
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 1.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(23),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (artUrl != null && artUrl.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: artUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: const Color(0xFF1B192A),
                        child: const Icon(
                          Icons.music_note_rounded,
                          color: Colors.white24,
                          size: 48,
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: const Color(0xFF1B192A),
                        child: const Icon(
                          Icons.music_note_rounded,
                          color: Colors.white24,
                          size: 48,
                        ),
                      ),
                    )
                  else
                    Container(
                      color: const Color(0xFF1B192A),
                      child: const Icon(
                        Icons.music_note_rounded,
                        color: Colors.white24,
                        size: 48,
                      ),
                    ),

                  // Loading/Buffering overlay
                  if (isLoading)
                    Container(
                      color: Colors.black.withValues(alpha: 0.45),
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 3,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 🏷️ MODERN METADATA SECTION (TITLE, ARTIST, FAVORITE, QUALITY)
// ─────────────────────────────────────────────────────────────────────────────

class _ModernMetadataSection extends ConsumerWidget {
  final AsyncValue<MediaItem?> mediaItemAsync;
  final AsyncValue<Music> musicAsync;
  final AsyncValue<PlaybackState> playbackAsync;
  final String initialId;
  final bool isLiked;
  final VoidCallback onLikeToggle;
  final VoidCallback onQualityTap;

  const _ModernMetadataSection({
    required this.mediaItemAsync,
    required this.musicAsync,
    required this.playbackAsync,
    required this.initialId,
    required this.isLiked,
    required this.onLikeToggle,
    required this.onQualityTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = mediaItemAsync.valueOrNull;
    final music = musicAsync.valueOrNull;
    final processingState =
        playbackAsync.valueOrNull?.processingState ?? AudioProcessingState.idle;

    final bool isLoading = processingState == AudioProcessingState.loading ||
        processingState == AudioProcessingState.buffering;
    final bool isStale = item != null && item.id != initialId && isLoading;

    final String title = isStale || (item == null && isLoading)
        ? 'Loading...'
        : (item?.title ??
            music?.getDisplayTitle(context.l10n.localeName) ??
            '—');

    final String artist = isStale || (item == null && isLoading)
        ? '...'
        : (item?.artist ??
            music?.getDisplayArtists(context.l10n.localeName) ??
            context.l10n.unknownArtist);

    final qualityLabel = ref.watch(currentActiveQualityLabelProvider);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Title & Artist Column
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              // Quality Pill Badge
              _ModernQualityBadge(
                label: qualityLabel,
                onTap: onQualityTap,
              ),
            ],
          ),
        ),

        // Add to Playlist Button
        IconButton(
          tooltip: 'Add to Playlist',
          icon: Icon(
            Icons.playlist_add_rounded,
            color: Colors.white.withValues(alpha: 0.6),
            size: 26,
          ),
          onPressed: () {
            AddToPlaylistSheet.show(
              context,
              songId: item?.id ?? initialId,
              songTitle: title,
              songSubtitle: artist,
              imageUrl: item?.artUri?.toString() ?? music?.thumbUrl,
            );
          },
        ),

        // Animated Favorite Heart Button
        IconButton(
          onPressed: onLikeToggle,
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) => ScaleTransition(
              scale: anim,
              child: child,
            ),
            child: Icon(
              isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              key: ValueKey(isLiked),
              color: isLiked
                  ? const Color(0xFFFF4B6E)
                  : Colors.white.withValues(alpha: 0.4),
              size: 28,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 🎚️ MODERN SLIDER & TIME INDICATOR
// ─────────────────────────────────────────────────────────────────────────────

class _ModernSeekbar extends StatelessWidget {
  final RhythmAudioHandler handler;
  final bool isDragging;
  final double? dragValue;
  final ValueChanged<double> onDragStart;
  final ValueChanged<double> onDragEnd;
  final String Function(Duration) formatDuration;

  const _ModernSeekbar({
    required this.handler,
    required this.isDragging,
    required this.dragValue,
    required this.onDragStart,
    required this.onDragEnd,
    required this.formatDuration,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PositionData>(
      stream: handler.positionDataStream,
      builder: (context, snapshot) {
        final pos = snapshot.data ??
            PositionData(Duration.zero, Duration.zero, Duration.zero);
        final progress = pos.duration.inMilliseconds > 0
            ? pos.position.inMilliseconds / pos.duration.inMilliseconds
            : 0.0;
        final value = isDragging ? (dragValue ?? progress) : progress;

        final currentDuration = isDragging && dragValue != null
            ? Duration(
                milliseconds: (dragValue! * pos.duration.inMilliseconds).round())
            : pos.position;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 6,
                  elevation: 2,
                ),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                activeTrackColor: Colors.white,
                inactiveTrackColor: Colors.white.withValues(alpha: 0.15),
                thumbColor: Colors.white,
                overlayColor: Colors.white.withValues(alpha: 0.12),
              ),
              child: Slider(
                value: value.clamp(0.0, 1.0),
                onChanged: onDragStart,
                onChangeEnd: onDragEnd,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formatDuration(currentDuration),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    formatDuration(pos.duration),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ⏯️ MODERN PLAYBACK CONTROLS (SHUFFLE, PREV, PLAY/PAUSE, NEXT, REPEAT)
// ─────────────────────────────────────────────────────────────────────────────

class _ModernControlsRow extends StatelessWidget {
  final RhythmAudioHandler handler;
  final AsyncValue<PlaybackState> playbackAsync;

  const _ModernControlsRow({
    required this.handler,
    required this.playbackAsync,
  });

  @override
  Widget build(BuildContext context) {
    final isPlaying = playbackAsync.valueOrNull?.playing ?? false;

    return StreamBuilder<bool>(
      stream: handler.shuffleModeStream,
      initialData: handler.shuffleEnabled,
      builder: (context, shuffleSnap) {
        final isShuffle = shuffleSnap.data ?? false;

        return StreamBuilder<LoopMode>(
          stream: handler.loopModeStream,
          initialData: switch (handler.repeatMode) {
            1 => LoopMode.all,
            2 => LoopMode.one,
            _ => LoopMode.off,
          },
          builder: (context, loopSnap) {
            final loopMode = loopSnap.data ?? LoopMode.off;
            final isRepeat = loopMode != LoopMode.off;

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Shuffle ──
                IconButton(
                  icon: Icon(
                    Icons.shuffle_rounded,
                    size: 22,
                    color: isShuffle
                        ? AppColors.primaryLight
                        : Colors.white.withValues(alpha: 0.4),
                  ),
                  tooltip: isShuffle ? 'Shuffle On' : 'Shuffle Off',
                  onPressed: () => handler.setShuffleEnabled(!isShuffle),
                ),

                // ── Skip Previous ──
                IconButton(
                  icon: const Icon(
                    Icons.skip_previous_rounded,
                    size: 36,
                    color: Colors.white,
                  ),
                  onPressed: handler.skipToPrevious,
                ),

                // ── Large Floating Play/Pause FAB ──
                _LargePlayPauseButton(
                  isPlaying: isPlaying,
                  onTap: () => isPlaying ? handler.pause() : handler.play(),
                ),

                // ── Skip Next ──
                IconButton(
                  icon: const Icon(
                    Icons.skip_next_rounded,
                    size: 36,
                    color: Colors.white,
                  ),
                  onPressed: handler.skipToNext,
                ),

                // ── Repeat Mode ──
                IconButton(
                  icon: Icon(
                    loopMode == LoopMode.one
                        ? Icons.repeat_one_rounded
                        : Icons.repeat_rounded,
                    size: 22,
                    color: isRepeat
                        ? AppColors.primaryLight
                        : Colors.white.withValues(alpha: 0.4),
                  ),
                  tooltip: switch (loopMode) {
                    LoopMode.one => 'Repeat One',
                    LoopMode.all => 'Repeat All',
                    _ => 'Repeat Off',
                  },
                  onPressed: () {
                    final nextMode = switch (loopMode) {
                      LoopMode.off => AudioServiceRepeatMode.all,
                      LoopMode.all => AudioServiceRepeatMode.one,
                      LoopMode.one => AudioServiceRepeatMode.none,
                    };
                    handler.setRepeatMode(nextMode);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 🌟 LARGE PLAY/PAUSE BUTTON WITH GRADIENT & GLOW
// ─────────────────────────────────────────────────────────────────────────────

class _LargePlayPauseButton extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onTap;

  const _LargePlayPauseButton({
    required this.isPlaying,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.primaryGradient,
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withValues(alpha: 0.45),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ⚡ BOTTOM QUICK ACTIONS ROW (UP NEXT, AUDIO QUALITY)
// ─────────────────────────────────────────────────────────────────────────────

class _BottomQuickActionsRow extends StatelessWidget {
  final VoidCallback onQueueTap;
  final VoidCallback onQualityTap;
  final bool isDark;

  const _BottomQuickActionsRow({
    required this.onQueueTap,
    required this.onQualityTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Audio Quality Quick Action
        InkWell(
          onTap: onQualityTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.graphic_eq_rounded,
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 6),
                Text(
                  'Audio Quality',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Up Next Queue Button
        InkWell(
          onTap: onQueueTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.queue_music_rounded,
                  size: 16,
                  color: Colors.white,
                ),
                SizedBox(width: 6),
                Text(
                  'Up Next',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 🔝 TOP NAVIGATION BAR
// ─────────────────────────────────────────────────────────────────────────────

class _ModernPlayerTopBar extends StatelessWidget {
  final VoidCallback onDismiss;
  final VoidCallback onOpenQueue;
  final VoidCallback onOpenSettings;

  const _ModernPlayerTopBar({
    required this.onDismiss,
    required this.onOpenQueue,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Dismiss Arrow
          IconButton(
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.white,
              size: 34,
            ),
            onPressed: onDismiss,
          ),

          // Center Label
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'NOW PLAYING',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ),

          // Audio Settings
          IconButton(
            icon: const Icon(
              Icons.tune_rounded,
              color: Colors.white,
              size: 22,
            ),
            tooltip: 'Audio Quality',
            onPressed: onOpenSettings,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 💎 QUALITY BADGE WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class _ModernQualityBadge extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ModernQualityBadge({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: Color(0xFF00E676),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 3),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 12,
              color: Colors.white38,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 🌌 MODERN AMBIENT BLUR BACKGROUND
// ─────────────────────────────────────────────────────────────────────────────

class _ModernAmbientBackground extends StatelessWidget {
  final bool isDark;
  final AsyncValue<MediaItem?> mediaItemAsync;
  final AsyncValue<Music> musicAsync;
  final String initialId;

  const _ModernAmbientBackground({
    required this.isDark,
    required this.mediaItemAsync,
    required this.musicAsync,
    required this.initialId,
  });

  @override
  Widget build(BuildContext context) {
    final mediaItem = mediaItemAsync.valueOrNull;
    final music = musicAsync.valueOrNull;

    final bool isCorrectSong = mediaItem?.id == initialId ||
        (mediaItem == null && music?.id.toString() == initialId);
    final artUrl = isCorrectSong
        ? (mediaItem?.artUri?.toString() ?? music?.thumbUrl)
        : music?.thumbUrl;

    return Stack(
      children: [
        // Solid deep base
        Container(
          color: isDark ? const Color(0xFF0C0B14) : const Color(0xFF141322),
        ),

        // Ambient blurred album art orb
        if (artUrl != null && artUrl.isNotEmpty)
          Positioned.fill(
            child: Opacity(
              opacity: isDark ? 0.35 : 0.25,
              child: CachedNetworkImage(
                imageUrl: artUrl,
                fit: BoxFit.cover,
              ),
            ),
          ),

        // Deep multi-stage blur
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
            child: Container(
              color: Colors.black.withValues(alpha: 0.4),
            ),
          ),
        ),

        // Vignette gradient
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.3),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.6),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 📜 UP NEXT QUEUE BOTTOM SHEET (MODERN & DRAGGABLE)
// ─────────────────────────────────────────────────────────────────────────────

class _UpNextBottomSheet extends StatelessWidget {
  final List<Music> songs;
  final String locale;
  final RhythmAudioHandler handler;

  const _UpNextBottomSheet({
    required this.songs,
    required this.locale,
    required this.handler,
  });

  static void show(
    BuildContext context, {
    required List<Music> songs,
    required String locale,
    required RhythmAudioHandler handler,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _UpNextBottomSheet(
        songs: songs,
        locale: locale,
        handler: handler,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141326) : Colors.white,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black)
                  .withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            children: [
              // Drag Handle
              const SizedBox(height: 12),
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      'Up Next Queue',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${songs.length} tracks',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),
              const Divider(height: 1),

              // Song List
              Expanded(
                child: songs.isEmpty
                    ? Center(
                        child: Text(
                          'No queued tracks',
                          style: TextStyle(
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: songs.length,
                        itemBuilder: (context, i) {
                          final song = songs[i];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: song.thumbUrl != null
                                  ? CachedNetworkImage(
                                      imageUrl: song.thumbUrl!,
                                      width: 44,
                                      height: 44,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      width: 44,
                                      height: 44,
                                      color: Colors.white12,
                                      child: const Icon(
                                        Icons.music_note_rounded,
                                        size: 20,
                                      ),
                                    ),
                            ),
                            title: Text(
                              song.getDisplayTitle(locale),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            subtitle: Text(
                              song.getDisplayArtists(locale),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    isDark ? Colors.white54 : Colors.black54,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.play_circle_outline_rounded,
                              size: 24,
                            ),
                            onTap: () {
                              final mediaItems = songs
                                  .map((s) => musicToMediaItem(s, locale))
                                  .toList();
                              handler.loadPlaylist(mediaItems, initialIndex: i);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 🎵 COMPACT TILE (FOR DESKTOP QUEUE)
// ─────────────────────────────────────────────────────────────────────────────

class _CompactTile extends StatelessWidget {
  final int index;
  final List<Music> songs;
  final String locale;
  final RhythmAudioHandler handler;

  const _CompactTile({
    required this.index,
    required this.songs,
    required this.locale,
    required this.handler,
  });

  Music get song => songs[index];

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: song.thumbUrl != null
            ? CachedNetworkImage(
                imageUrl: song.thumbUrl!,
                width: 42,
                height: 42,
                fit: BoxFit.cover,
              )
            : Container(
                width: 42,
                height: 42,
                color: Colors.white10,
                child: const Icon(Icons.music_note,
                    size: 18, color: Colors.white24),
              ),
      ),
      title: Text(
        song.getDisplayTitle(locale),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
        maxLines: 1,
      ),
      subtitle: Text(
        song.getDisplayArtists(locale),
        style: const TextStyle(color: Colors.white38, fontSize: 11),
        maxLines: 1,
      ),
      onTap: () {
        final mediaItems =
            songs.map((s) => musicToMediaItem(s, locale)).toList();
        handler.loadPlaylist(mediaItems, initialIndex: index);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 🔊 AUDIO QUALITY BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _AudioQualityBottomSheet extends ConsumerStatefulWidget {
  final RhythmAudioHandler handler;
  const _AudioQualityBottomSheet({required this.handler});

  static void show(
      BuildContext context, WidgetRef ref, RhythmAudioHandler handler) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _AudioQualityBottomSheet(handler: handler),
    );
  }

  @override
  ConsumerState<_AudioQualityBottomSheet> createState() =>
      _AudioQualityBottomSheetState();
}

class _AudioQualityBottomSheetState
    extends ConsumerState<_AudioQualityBottomSheet> {
  bool _isTestingSpeed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentPref = ref.watch(audioQualityPreferenceProvider);
    final speedService = ref.watch(networkSpeedServiceProvider);
    final speedKbpsAsync = ref.watch(networkSpeedKbpsProvider);
    final gradeAsync = ref.watch(networkSpeedGradeProvider);

    final speedKbps =
        speedKbpsAsync.valueOrNull ?? speedService.currentSpeedKbps;
    final grade = gradeAsync.valueOrNull ?? speedService.currentGrade;
    final speedMbps = (speedKbps / 1000.0).toStringAsFixed(1);

    final songQualities = ref.watch(currentSongQualitiesProvider);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141426) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color:
              (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black)
                    .withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.graphic_eq_rounded,
                    size: 18, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Streaming Audio Quality',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      'Network speed adaptive streaming',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Real-time Network Speed Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E1E38), const Color(0xFF262648)]
                    : [const Color(0xFFF1EFFB), const Color(0xFFE9E5FA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primaryLight.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.speed_rounded,
                  color: AppColors.primaryLight,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Network Connection: ${grade.label}',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Estimated Bandwidth: $speedMbps Mbps ($speedKbps kbps)',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _isTestingSpeed
                      ? null
                      : () async {
                          setState(() => _isTestingSpeed = true);
                          await speedService.runSpeedProbe();
                          if (mounted) {
                            setState(() => _isTestingSpeed = false);
                          }
                        },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: _isTestingSpeed
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Test',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryLight,
                          ),
                        ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Quality Options List
          ...AudioQualityPreference.values.map((pref) {
            final isSelected = currentPref == pref;

            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                await ref
                    .read(audioQualityPreferenceProvider.notifier)
                    .setPreference(pref);

                if (songQualities.isNotEmpty) {
                  final target = AdaptiveAudioQualitySelector.resolveQuality(
                    availableQualities: songQualities,
                    preference: pref,
                    currentGrade: grade,
                  );
                  if (target != null) {
                    await widget.handler.switchCurrentSongQuality(target);
                  }
                }
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryLight
                          .withValues(alpha: isDark ? 0.18 : 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryLight.withValues(alpha: 0.4)
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: isSelected
                          ? AppColors.primaryLight
                          : (isDark ? Colors.white38 : Colors.black38),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pref.title,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          Text(
                            pref.subtitle,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (pref == AudioQualityPreference.auto)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E676)
                              .withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'SMART',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00E676),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}