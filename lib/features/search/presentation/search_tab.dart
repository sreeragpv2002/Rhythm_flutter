import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rhythm_flutter/core/extensions/context_extensions.dart';
import 'package:rhythm_flutter/core/services/media_item_mapper.dart';
import 'package:rhythm_flutter/core/theme/spacing.dart';
import 'package:rhythm_flutter/core/widgets/music_list_tile.dart';
import 'package:rhythm_flutter/core/widgets/shimmer_loading.dart';
import 'package:rhythm_flutter/features/player/providers/audio_provider.dart';
import 'package:rhythm_flutter/features/home/providers/favorites_provider.dart';
import 'package:rhythm_flutter/features/search/providers/search_provider.dart';

class SearchTab extends ConsumerStatefulWidget {
  const SearchTab({super.key});

  @override
  ConsumerState<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends ConsumerState<SearchTab> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(searchQueryProvider);
    final searchResults = ref.watch(searchResultsProvider);
    final handler = ref.read(audioHandlerProvider);
    final locale = context.l10n.localeName;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Column(
        children: [
          // ── Search field ──
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: context.l10n.search,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(searchQueryProvider.notifier).updateQuery('');
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                ref.read(searchQueryProvider.notifier).updateQuery(value);
              },
            ),
          ),

          // ── Results ──
          Expanded(
            child: searchQuery.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_rounded,
                          size: 64,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.15)
                              : Colors.black.withValues(alpha: 0.1),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          context.l10n.searchHint,
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.4)
                                : Colors.black.withValues(alpha: 0.35),
                          ),
                        ),
                      ],
                    ),
                  )
                : searchResults.when(
                    loading: () => ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                      itemCount: 6,
                      itemBuilder: (_, __) => ShimmerLoading.listTile(),
                    ),
                    error: (err, _) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Text(
                          err.toString(),
                          textAlign: TextAlign.center,
                          style: context.textTheme.bodyMedium,
                        ),
                      ),
                    ),
                    data: (songs) {
                      if (songs.isEmpty) {
                        return Center(
                          child: Text(
                            context.l10n.noResults,
                            style: context.textTheme.bodyLarge?.copyWith(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.5)
                                  : Colors.black.withValues(alpha: 0.4),
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                        itemCount: songs.length,
                        itemBuilder: (context, index) {
                          final song = songs[index];
                          return MusicListTile(
                            title: song.getDisplayTitle(locale),
                            subtitle: song.getDisplayArtists(locale),
                            imageUrl: song.thumbUrl,
                            isFavorite: ref.watch(favoritesProvider).contains(song.id),
                            onFavoriteToggle: () async {
                              await ref.read(favoritesProvider.notifier).toggleFavorite(song.id);
                              // Update audio handler if this is the current song
                              final currentMedia = ref.read(audioHandlerProvider).mediaItem.value;
                              if (currentMedia?.id == song.id.toString()) {
                                final isLiked = ref.read(favoritesProvider).contains(song.id);
                                ref.read(audioHandlerProvider).updateMediaItemFavorite(song.id.toString(), isLiked);
                              }
                            },
                            trailing: _formatDuration(Duration(seconds: song.duration)),
                            onTap: () {
                              final mediaItems = songs
                                  .map((m) => musicToMediaItem(m, locale))
                                  .toList();
                              handler.loadPlaylist(mediaItems, initialIndex: index);
                            },
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
