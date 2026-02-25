import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rhythm_flutter/core/theme/app_colors.dart';
import 'package:rhythm_flutter/core/theme/glass_decoration.dart';
import 'package:rhythm_flutter/core/theme/spacing.dart';
import 'package:rhythm_flutter/core/extensions/context_extensions.dart';
import 'package:rhythm_flutter/features/player/providers/audio_provider.dart';
import 'package:rhythm_flutter/features/home/data/models/music.dart';
import 'package:rhythm_flutter/features/home/providers/favorites_provider.dart';

/// Compact now-playing bar shown above the bottom navigation.
///
/// Uses glassmorphism BackdropFilter and theme-aware colors.
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaItemAsync = ref.watch(currentMediaItemProvider);
    final playbackAsync = ref.watch(playbackStateProvider);
    final positionAsync = ref.watch(positionDataProvider);
    final handler = ref.read(audioHandlerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final mediaItem = mediaItemAsync.valueOrNull;
    if (mediaItem == null) return const SizedBox.shrink();

    final isPlaying = playbackAsync.valueOrNull?.playing ?? false;

    // Progress fraction for the thin bar
    final posData = positionAsync.valueOrNull;
    final progress = (posData != null && posData.duration.inMilliseconds > 0)
        ? (posData.position.inMilliseconds / posData.duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return GestureDetector(
      onTap: () {
        context.push('/player/${mediaItem.id}');
      },
      child: ClipRRect(
        child: BackdropFilter(
          filter: GlassDecoration.blur(),
          child: Container(
            height: AppSpacing.miniPlayerHeight,
            decoration: GlassDecoration.surface(context),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Progress indicator ──
                Container(
                  height: 2,
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                ),

                // ── Content row ──
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: Row(
                      children: [
                        // Thumbnail
                        RepaintBoundary(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                            child: SizedBox(
                              width: AppSpacing.thumbnailSm,
                              height: AppSpacing.thumbnailSm,
                              child: mediaItem.artUri != null
                                  ? CachedNetworkImage(
                                      imageUrl: mediaItem.artUri.toString(),
                                      fit: BoxFit.cover,
                                      memCacheWidth: (AppSpacing.thumbnailSm * 2).toInt(),
                                    )
                                  : Container(
                                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                                      child: Icon(
                                        Icons.music_note_rounded,
                                        color: Theme.of(context).colorScheme.primary,
                                        size: AppSpacing.iconMd,
                                      ),
                                    ),
                            ),
                          ),
                        ),

                        const SizedBox(width: AppSpacing.sm + 4),

                        // Title + artist
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                mediaItem.title.isEmpty ? context.l10n.appName : mediaItem.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                (mediaItem.artist == null || mediaItem.artist!.isEmpty)
                                    ? context.l10n.unknownArtist
                                    : mediaItem.artist!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.55)
                                      : AppColors.textSecondaryLight,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Favorite toggle
                        IconButton(
                          icon: Icon(
                            ref.watch(favoritesProvider).contains(int.tryParse(mediaItem.id) ?? -1)
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: ref.watch(favoritesProvider).contains(int.tryParse(mediaItem.id) ?? -1)
                                ? const Color(0xFFFF6B6B)
                                : (isDark ? Colors.white : AppColors.textPrimaryLight).withValues(alpha: 0.35),
                            size: 24,
                          ),
                          onPressed: () async {
                            final musicId = int.tryParse(mediaItem.id);
                            if (musicId != null) {
                              // We need a Music object but we only have MediaItem.
                              // Actually toggleFavorite might need more than just ID if it reverts.
                              // But repository.toggleFavorite(id) only needs ID.
                              // The provider.toggleFavorite(music) needs music for optimistic update.
                              // Let's create a minimal Music object or adjust the provider.
                              // For now, let's use the provider's logic.
                              final music = Music(
                                id: musicId,
                                titles: mediaItem.extras?['titles'] != null ? Map<String, String>.from(mediaItem.extras!['titles']) : {},
                                artistNames: mediaItem.extras?['artist_names'] != null ? List<Map<String, String>>.from(mediaItem.extras!['artist_names'].map((e) => Map<String, String>.from(e))) : [],
                                duration: mediaItem.duration?.inSeconds ?? 0,
                                language: 'en',
                                languageDisplay: 'English',
                              );
                              await ref.read(favoritesProvider.notifier).toggleFavorite(music);
                              final isLiked = ref.read(favoritesProvider).contains(musicId);
                              handler.updateMediaItemFavorite(mediaItem.id, isLiked);
                            }
                          },
                        ),

                        // Play / Pause
                        IconButton(
                          icon: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              key: ValueKey(isPlaying),
                              color: isDark ? Colors.white : AppColors.textPrimaryLight,
                              size: 28,
                            ),
                          ),
                          onPressed: () => isPlaying ? handler.pause() : handler.play(),
                        ),

                        // Skip next
                        IconButton(
                          icon: Icon(
                            Icons.skip_next_rounded,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.7)
                                : AppColors.textSecondaryLight,
                            size: AppSpacing.iconMd,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          onPressed: handler.skipToNext,
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
