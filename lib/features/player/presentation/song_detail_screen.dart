import 'dart:math';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rhythm_flutter/core/theme/app_colors.dart';
import 'package:rhythm_flutter/core/extensions/context_extensions.dart';
import 'package:rhythm_flutter/core/services/audio_handler.dart';
import 'package:rhythm_flutter/features/home/data/models/music.dart';
import 'package:rhythm_flutter/features/player/providers/audio_provider.dart';
import 'package:rhythm_flutter/features/player/providers/music_detail_provider.dart';
import 'package:rhythm_flutter/features/home/providers/favorites_provider.dart';

class SongDetailScreen extends ConsumerStatefulWidget {
  final int initialMusicId;
  const SongDetailScreen({super.key, required this.initialMusicId});

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
      duration: const Duration(seconds: 25),
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
    // Media Query Integration
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = context.l10n.localeName;
    final mediaItemAsync = ref.watch(currentMediaItemProvider);
    final playbackAsync = ref.watch(playbackStateProvider);
    final handler = ref.read(audioHandlerProvider);
    
    // Support skipping: use the currently playing ID if the player has moved on
    final currentItem = mediaItemAsync.valueOrNull;
    final effectiveId = (currentItem != null) 
        ? (int.tryParse(currentItem.id) ?? widget.initialMusicId)
        : widget.initialMusicId;

    final musicAsync = ref.watch(musicDetailsProvider(effectiveId));
    final relatedAsync = ref.watch(relatedSongsProvider(effectiveId));
        
    final isLiked = ref.watch(favoritesProvider).contains(effectiveId);

    // Logic remains untouched
    ref.listen<AsyncValue<Music>>(
      musicDetailsProvider(widget.initialMusicId),
      (prev, next) {
        if (next.isLoading || next.hasError) return;
        next.whenData((music) {
          // Sync favorites state from the detailed response
          ref.read(favoritesProvider.notifier).initFromList([music]);

          final currentItem = ref.read(currentMediaItemProvider).value;
          if (widget.initialMusicId != 0 && currentItem?.id != music.id.toString()) {
            _playMusic(music, handler, locale);
          }
        });
      },
    );

    playbackAsync.whenData((state) {
      if (state.playing) {
        if (!_rotationController.isAnimating) _rotationController.repeat();
      } else {
        _rotationController.stop();
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          _PremiumBackground(isDark: isDark, mediaItemAsync: mediaItemAsync, musicAsync: musicAsync, initialId: effectiveId.toString()),
          SafeArea(
            child: width > 900
                ? _DesktopLayout(
              width: width,
              height: height,
              rotationController: _rotationController,
              mediaItemAsync: mediaItemAsync,
              musicAsync: musicAsync,
              playbackAsync: playbackAsync,
              handler: handler,
              isLiked: isLiked,
              onLikeToggle: () => _handleLikeToggle(ref),
              formatDuration: _formatDuration,
              relatedAsync: relatedAsync,
              locale: locale,
              initialMusicId: effectiveId.toString(),
              isDragging: _isDragging,
              dragValue: _dragValue,
              onDragStart: (v) => setState(() { _isDragging = true; _dragValue = v; }),
              onDragEnd: (v) {
                final duration = mediaItemAsync.value?.duration ?? Duration.zero;
                handler.seek(Duration(milliseconds: (v * duration.inMilliseconds).round()));
                setState(() { _isDragging = false; _dragValue = null; });
              },
            )
                : _MobilePremiumLayout(
              width: width,
              height: height,
              rotationController: _rotationController,
              mediaItemAsync: mediaItemAsync,
              musicAsync: musicAsync,
              playbackAsync: playbackAsync,
              handler: handler,
              isLiked: isLiked,
              onLikeToggle: () => _handleLikeToggle(ref),
              formatDuration: _formatDuration,
              relatedAsync: relatedAsync,
              locale: locale,
              initialMusicId: effectiveId.toString(),
              isDragging: _isDragging,
              dragValue: _dragValue,
              onDragStart: (v) => setState(() { _isDragging = true; _dragValue = v; }),
              onDragEnd: (v) {
                final duration = mediaItemAsync.value?.duration ?? Duration.zero;
                handler.seek(Duration(milliseconds: (v * duration.inMilliseconds).round()));
                setState(() { _isDragging = false; _dragValue = null; });
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLikeToggle(WidgetRef ref) async {
    final currentItem = ref.read(currentMediaItemProvider).value;
    final targetId = (currentItem != null) 
        ? (int.tryParse(currentItem.id) ?? widget.initialMusicId)
        : widget.initialMusicId;

    await ref.read(favoritesProvider.notifier).toggleFavorite(targetId);
    final liked = ref.read(favoritesProvider).contains(targetId);
    ref.read(audioHandlerProvider).updateMediaItemFavorite(targetId.toString(), liked);
  }
}

// ── MOBILE LAYOUT ──

class _MobilePremiumLayout extends StatelessWidget {
  final double width;
  final double height;
  final AnimationController rotationController;
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

  const _MobilePremiumLayout({
    required this.width, required this.height, required this.rotationController,
    required this.mediaItemAsync, required this.musicAsync, required this.playbackAsync,
    required this.handler, required this.isLiked, required this.onLikeToggle,
    required this.formatDuration, required this.relatedAsync, required this.locale,
    required this.initialMusicId,
    required this.isDragging, required this.dragValue, required this.onDragStart,
    required this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    final bool isShort = height < 700;

    return Column(
      children: [
        _HeaderSection(onBack: () => context.pop()),
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: width * 0.08),
            child: Column(
              children: [
                const Spacer(flex: 1),
                _FloatingDisc(
                  rotationController: rotationController,
                  mediaItemAsync: mediaItemAsync,
                  musicAsync: musicAsync,
                  playbackAsync: playbackAsync,
                  initialId: initialMusicId,
                  size: isShort ? height * 0.3 : height * 0.38,
                ),
                const Spacer(flex: 2),
                _MetadataSection(
                  mediaItemAsync: mediaItemAsync,
                  musicAsync: musicAsync,
                  playbackAsync: playbackAsync,
                  initialId: initialMusicId,
                  isLiked: isLiked,
                  onLikeToggle: onLikeToggle,
                ),
                SizedBox(height: height * 0.02),
                _GlassControlPanel(
                  width: width,
                  height: height,
                  handler: handler,
                  playbackAsync: playbackAsync,
                  isDragging: isDragging,
                  dragValue: dragValue,
                  onDragStart: onDragStart,
                  onDragEnd: onDragEnd,
                  formatDuration: formatDuration,
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
        if (!isShort)
          _UpNextSection(songs: relatedAsync.value ?? [], locale: locale, handler: handler, height: height),
      ],
    );
  }
}

// ── DESKTOP LAYOUT ──

class _DesktopLayout extends StatelessWidget {
  final double width;
  final double height;
  final AnimationController rotationController;
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

  const _DesktopLayout({
    required this.width, required this.height, required this.rotationController,
    required this.mediaItemAsync, required this.musicAsync, required this.playbackAsync,
    required this.handler, required this.isLiked, required this.onLikeToggle,
    required this.formatDuration, required this.relatedAsync, required this.locale,
    required this.initialMusicId,
    required this.isDragging, required this.dragValue, required this.onDragStart,
    required this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Container(
        margin: EdgeInsets.all(height * 0.05),
        constraints: BoxConstraints(maxWidth: width * 0.8, maxHeight: height * 0.8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.1),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Center(
                      child: _FloatingDisc(
                          rotationController: rotationController,
                          mediaItemAsync: mediaItemAsync,
                          musicAsync: musicAsync,
                          playbackAsync: playbackAsync,
                          initialId: initialMusicId,
                          size: height * 0.5
                      )
                  ),
                ),
                VerticalDivider(width: 1, color: Colors.white.withValues(alpha: 0.1)),
                Expanded(
                  flex: 6,
                  child: Container(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HeaderSection(onBack: () => context.pop(), showTitle: false),
                        const Spacer(),
                        _MetadataSection(
                          mediaItemAsync: mediaItemAsync,
                          musicAsync: musicAsync,
                          playbackAsync: playbackAsync,
                          initialId: initialMusicId,
                          isLiked: isLiked,
                          onLikeToggle: onLikeToggle,
                        ),
                        const SizedBox(height: 32),
                        _GlassControlPanel(
                          width: width,
                          height: height,
                          handler: handler,
                          playbackAsync: playbackAsync,
                          isDragging: isDragging,
                          dragValue: dragValue,
                          onDragStart: onDragStart,
                          onDragEnd: onDragEnd,
                          formatDuration: formatDuration,
                        ),
                        const Spacer(),
                        Text(context.l10n.upNext.toUpperCase(), style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 2)),
                        const SizedBox(height: 16),
                        Expanded(
                          flex: 4,
                          child: ListView.builder(
                            itemCount: relatedAsync.value?.length ?? 0,
                            itemBuilder: (context, i) => _CompactTile(index: i, songs: relatedAsync.value!, locale: locale, handler: handler),
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

// ── REUSABLE UI COMPONENTS ──

class _GlassControlPanel extends StatelessWidget {
  final double width;
  final double height;
  final RhythmAudioHandler handler;
  final AsyncValue<PlaybackState> playbackAsync;
  final bool isDragging;
  final double? dragValue;
  final ValueChanged<double> onDragStart;
  final ValueChanged<double> onDragEnd;
  final String Function(Duration) formatDuration;

  const _GlassControlPanel({
    required this.width, required this.height, required this.handler,
    required this.playbackAsync, required this.isDragging, required this.dragValue,
    required this.onDragStart, required this.onDragEnd, required this.formatDuration,
  });

  @override
  Widget build(BuildContext context) {
    final isPlaying = playbackAsync.valueOrNull?.playing ?? false;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Scale Play button based on smaller dimension to avoid overflow
    final playBtnSize = (height * 0.1).clamp(64.0, 88.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          StreamBuilder<PositionData>(
            stream: handler.positionDataStream,
            builder: (context, snapshot) {
              final pos = snapshot.data ?? PositionData(Duration.zero, Duration.zero, Duration.zero);
              final progress = pos.duration.inMilliseconds > 0 ? pos.position.inMilliseconds / pos.duration.inMilliseconds : 0.0;
              final value = isDragging ? (dragValue ?? progress) : progress;
              return Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      activeTrackColor: AppColors.primaryDark,
                      inactiveTrackColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                    ),
                    child: Slider(value: value.clamp(0.0, 1.0), onChanged: onDragStart, onChangeEnd: onDragEnd),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(formatDuration(pos.position), style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
                        Text(formatDuration(pos.duration), style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(icon: const Icon(Icons.shuffle_rounded, color: Colors.white24, size: 22), onPressed: () {}),
              IconButton(icon: const Icon(Icons.skip_previous_rounded, size: 44, color: Colors.white), onPressed: handler.skipToPrevious),
              _PlayButton(isPlaying: isPlaying, size: playBtnSize, onTap: () => isPlaying ? handler.pause() : handler.play()),
              IconButton(icon: const Icon(Icons.skip_next_rounded, size: 44, color: Colors.white), onPressed: handler.skipToNext),
              IconButton(icon: const Icon(Icons.repeat_rounded, color: Colors.white24, size: 22), onPressed: () {}),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  final bool isPlaying;
  final double size;
  final VoidCallback onTap;
  const _PlayButton({required this.isPlaying, required this.size, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(colors: [Color(0xFF6448FE), Color(0xFF8E2DE2)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          boxShadow: [BoxShadow(color: const Color(0xFF6448FE).withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: size * 0.55),
      ),
    );
  }
}

class _FloatingDisc extends StatelessWidget {
  final AnimationController rotationController;
  final AsyncValue<MediaItem?> mediaItemAsync;
  final AsyncValue<Music> musicAsync;
  final AsyncValue<PlaybackState> playbackAsync;
  final String initialId;
  final double size;

  const _FloatingDisc({
    required this.rotationController,
    required this.mediaItemAsync,
    required this.musicAsync,
    required this.playbackAsync,
    required this.initialId,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final mediaItem = mediaItemAsync.valueOrNull;
    final music = musicAsync.valueOrNull;
    final processingState = playbackAsync.valueOrNull?.processingState ?? AudioProcessingState.idle;
    
    // Determine if we should show a loader
    final bool isLoading = processingState == AudioProcessingState.loading || 
                           processingState == AudioProcessingState.buffering ||
                           (mediaItem == null && musicAsync.isLoading);

    // Prevent "other song thumb" flicker: 
    // If the currently playing ID doesn't match our intent, and we are loading, don't show the old thumb.
    final bool isCorrectSong = mediaItem?.id == initialId || (mediaItem == null && music?.id.toString() == initialId);
    final String? artUrl = isCorrectSong 
        ? (mediaItem?.artUri?.toString() ?? music?.thumbUrl)
        : music?.thumbUrl;

    return AnimatedBuilder(
      animation: rotationController,
      builder: (_, child) => Transform.rotate(angle: rotationController.value * 2 * pi, child: child),
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 40, offset: const Offset(0, 20))],
          border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.5),
        ),
        child: ClipOval(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Show correct thumb if we have it (prioritize music model while mediaItem is stale)
              if (artUrl != null)
                CachedNetworkImage(
                  imageUrl: artUrl, 
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: Colors.black87),
                  errorWidget: (context, url, error) => Container(color: Colors.black87),
                )
              else
                Container(color: Colors.black87, child: const Icon(Icons.music_note, color: Colors.white24, size: 60)),
              
              // Loading Overlay
              if (isLoading)
                Container(
                  color: Colors.black.withValues(alpha: 0.4),
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                      strokeWidth: 3,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetadataSection extends StatelessWidget {
  final AsyncValue<MediaItem?> mediaItemAsync;
  final AsyncValue<Music> musicAsync;
  final AsyncValue<PlaybackState> playbackAsync;
  final String initialId;
  final bool isLiked;
  final VoidCallback onLikeToggle;

  const _MetadataSection({
    required this.mediaItemAsync,
    required this.musicAsync,
    required this.playbackAsync,
    required this.initialId,
    required this.isLiked,
    required this.onLikeToggle,
  });

  @override
  Widget build(BuildContext context) {
    final item = mediaItemAsync.valueOrNull;
    final music = musicAsync.valueOrNull;
    final color = Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black;
    final processingState = playbackAsync.valueOrNull?.processingState ?? AudioProcessingState.idle;
    
    final bool isLoading = processingState == AudioProcessingState.loading || 
                           processingState == AudioProcessingState.buffering;

    // Determine if the current media item matches what we intend to show
    final bool isStale = item != null && item.id != initialId && isLoading;

    final String title = isStale || (item == null && isLoading)
        ? 'Loading...'
        : (item?.title ?? music?.getDisplayTitle(context.l10n.localeName) ?? '—');
    
    final String artist = isStale || (item == null && isLoading)
        ? '...'
        : (item?.artist ?? music?.getDisplayArtists(context.l10n.localeName) ?? context.l10n.unknownArtist);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: TextStyle(color: color, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.6), maxLines: 1),
              Text(artist, style: TextStyle(color: color.withValues(alpha: 0.5), fontSize: 17, fontWeight: FontWeight.w500), maxLines: 1),
            ],
          ),
        ),
        IconButton(onPressed: onLikeToggle, icon: Icon(isLiked ? Icons.favorite_rounded : Icons.favorite_outline_rounded, color: isLiked ? Colors.redAccent : color.withValues(alpha: 0.2), size: 30)),
      ],
    );
  }
}

class _PremiumBackground extends StatelessWidget {
  final bool isDark;
  final AsyncValue<MediaItem?> mediaItemAsync;
  final AsyncValue<Music> musicAsync;
  final String initialId;

  const _PremiumBackground({required this.isDark, required this.mediaItemAsync, required this.musicAsync, required this.initialId});

  @override
  Widget build(BuildContext context) {
    final mediaItem = mediaItemAsync.valueOrNull;
    final music = musicAsync.valueOrNull;
    
    // Prevent stale thumb:
    final bool isCorrectSong = mediaItem?.id == initialId || (mediaItem == null && music?.id.toString() == initialId);
    final artUrl = isCorrectSong 
        ? (mediaItem?.artUri?.toString() ?? music?.thumbUrl)
        : music?.thumbUrl;
    return Container(
      color: isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF0F4F8),
      child: Stack(
        children: [
          if (artUrl != null)
            Positioned.fill(
              child: Opacity(
                opacity: isDark ? 0.3 : 0.2,
                child: CachedNetworkImage(imageUrl: artUrl, fit: BoxFit.cover),
              ),
            ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
              child: Container(color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.2)),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  final VoidCallback onBack;
  final bool showTitle;
  const _HeaderSection({required this.onBack, this.showTitle = true});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 36), onPressed: onBack),
          if (showTitle)
            Text(context.l10n.nowPlaying.toUpperCase(), style: const TextStyle(color: Colors.white60, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 2)),
          IconButton(icon: const Icon(Icons.more_horiz_rounded, color: Colors.white), onPressed: () {}),
        ],
      ),
    );
  }
}

class _UpNextSection extends StatelessWidget {
  final List<Music> songs;
  final String locale;
  final RhythmAudioHandler handler;
  final double height;

  const _UpNextSection({required this.songs, required this.locale, required this.handler, required this.height});

  @override
  Widget build(BuildContext context) {
    if (songs.isEmpty) return const SizedBox.shrink();
    return Container(
      height: height * 0.18,
      decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.2),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05))
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10))),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              itemCount: songs.length,
              itemBuilder: (context, i) => _CompactTile(index: i, songs: songs, locale: locale, handler: handler),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactTile extends StatelessWidget {
  final int index;
  final List<Music> songs;
  final String locale;
  final RhythmAudioHandler handler;
  const _CompactTile({required this.index, required this.songs, required this.locale, required this.handler});

  Music get song => songs[index];

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: song.thumbUrl != null
              ? CachedNetworkImage(imageUrl: song.thumbUrl!, width: 44, height: 44, fit: BoxFit.cover)
              : Container(width: 44, height: 44, color: Colors.white10, child: const Icon(Icons.music_note, size: 18, color: Colors.white24))
      ),
      title: Text(song.getDisplayTitle(locale), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1),
      subtitle: Text(song.getDisplayArtists(locale), style: const TextStyle(color: Colors.white38, fontSize: 11), maxLines: 1),
      onTap: () {
        final mediaItems = songs.map((s) => musicToMediaItem(s, locale)).toList();
        handler.loadPlaylist(mediaItems, initialIndex: index);
      },
    );
  }
}