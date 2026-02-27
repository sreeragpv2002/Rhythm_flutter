import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rhythm_flutter/core/animations/app_animations.dart';
import 'package:rhythm_flutter/core/extensions/context_extensions.dart';
import 'package:rhythm_flutter/core/services/media_item_mapper.dart';
import 'package:rhythm_flutter/core/theme/spacing.dart';
import 'package:rhythm_flutter/core/widgets/music_list_tile.dart';
import 'package:rhythm_flutter/features/home/data/models/home_feed.dart';
import 'package:rhythm_flutter/features/home/providers/home_provider.dart';
import 'package:rhythm_flutter/features/home/providers/favorites_provider.dart';
import 'package:rhythm_flutter/features/player/providers/audio_provider.dart';

class LibraryTab extends ConsumerWidget {
  const LibraryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeAsync = ref.watch(homeProvider);
    final favorites = ref.watch(favoritesProvider);
    final locale = context.l10n.localeName;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            backgroundColor: isDark ? Colors.black : Colors.white,
            elevation: 0,
            title: Text(
              context.l10n.library,
              style: context.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: false,
          ),
          
          if (favorites.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.favorite_border_rounded,
                      size: 64,
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.2),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      context.l10n.noSongsFound,
                      style: context.textTheme.bodyLarge?.copyWith(
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            homeAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => SliverFillRemaining(
                child: Center(child: Text('${context.l10n.error}: $err')),
              ),
              data: (feed) {
                final favoriteSongs = favorites
                    .map((id) => feed.getMusicById(id))
                    .whereType<dynamic>() // Music is technically dynamic here due to freezed generation sometimes
                    .toList();

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final song = favoriteSongs[index];
                        return SlideUpFadeIn(
                          delay: AppAnimations.stagger(index, baseMs: 40),
                          child: MusicListTile(
                            title: song.getDisplayTitle(locale),
                            subtitle: song.getDisplayArtists(locale),
                            imageUrl: song.thumbUrl,
                            isFavorite: true,
                            onFavoriteToggle: () => ref.read(favoritesProvider.notifier).toggleFavorite(song.id),
                            onTap: () {
                              final handler = ref.read(audioHandlerProvider);
                              final mediaItems = favoriteSongs
                                  .map((m) => musicToMediaItem(m, locale))
                                  .toList();
                              handler.loadPlaylist(mediaItems, initialIndex: index);
                            },
                          ),
                        );
                      },
                      childCount: favoriteSongs.length,
                    ),
                  ),
                );
              },
            ),
            
          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.miniPlayerHeight + AppSpacing.xl),
          ),
        ],
      ),
    );
  }
}
