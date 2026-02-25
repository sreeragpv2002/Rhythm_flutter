import 'package:cached_network_image/cached_network_image.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rhythm_flutter/core/theme/app_colors.dart';
import 'package:rhythm_flutter/features/player/providers/audio_provider.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaItemAsync = ref.watch(currentMediaItemProvider);
    final playbackAsync = ref.watch(playbackStateProvider);
    final positionAsync = ref.watch(positionDataProvider);

    return mediaItemAsync.when(
      data: (mediaItem) {
        if (mediaItem == null) return const SizedBox.shrink();

        return playbackAsync.when(
          data: (state) {
            // Don't show if idle
            if (state.processingState == AudioProcessingState.idle) {
              return const SizedBox.shrink();
            }

            final handler = ref.read(audioHandlerProvider);
            final isPlaying = state.playing;

            return GestureDetector(
              onTap: () {
                final musicId = int.tryParse(mediaItem.id);
                if (musicId != null) {
                  context.push('/player/$musicId');
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  border: Border(
                    top: BorderSide(
                      color: AppColors.primaryDark.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Progress bar at the top
                    positionAsync.when(
                      data: (data) {
                        final progress = data.duration.inMilliseconds > 0
                            ? data.position.inMilliseconds /
                                data.duration.inMilliseconds
                            : 0.0;
                        return LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          minHeight: 2,
                          backgroundColor: Colors.transparent,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primaryDark,
                          ),
                        );
                      },
                      loading: () => const SizedBox(height: 2),
                      error: (error, stackTrace) => const SizedBox(height: 2),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          // Thumbnail
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: AppColors.primaryDark.withValues(alpha: 0.2),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: mediaItem.artUri != null
                                ? CachedNetworkImage(
                                    imageUrl: mediaItem.artUri.toString(),
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const Center(
                                      child: Opacity(
                                        opacity: 0.1,
                                        child: Icon(Icons.music_note_rounded, color: Colors.white),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) => const Icon(
                                      Icons.broken_image_rounded,
                                      color: Colors.white24,
                                    ),
                                  )
                                : const Icon(
                                    Icons.music_note_rounded,
                                    color: Colors.white54,
                                  ),
                          ),
                          const SizedBox(width: 12),
                          // Song info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  mediaItem.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  mediaItem.artist ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Play/Pause
                          IconButton(
                            icon: Icon(
                              isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                            onPressed: () {
                              if (isPlaying) {
                                handler.pause();
                              } else {
                                handler.play();
                              }
                            },
                          ),
                          // Next
                          IconButton(
                            icon: const Icon(
                              Icons.skip_next_rounded,
                              color: Colors.white70,
                              size: 28,
                            ),
                            onPressed: handler.skipToNext,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (e, s) => const SizedBox.shrink(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, s) => const SizedBox.shrink(),
    );
  }
}
