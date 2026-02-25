import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rhythm_flutter/core/extensions/context_extensions.dart';
import 'package:rhythm_flutter/core/services/audio_handler.dart';
import 'package:rhythm_flutter/core/widgets/app_text_field.dart';
import 'package:rhythm_flutter/core/widgets/gradient_background.dart';
import 'package:rhythm_flutter/features/home/data/models/music.dart';
import 'package:rhythm_flutter/features/player/providers/audio_provider.dart';
import 'package:rhythm_flutter/features/search/providers/search_provider.dart';
import 'package:rhythm_flutter/shared/providers/locale_provider.dart';

class SearchTab extends ConsumerStatefulWidget {
  const SearchTab({super.key});

  @override
  ConsumerState<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends ConsumerState<SearchTab> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final resultsAsync = ref.watch(searchResultsProvider);
    final locale = ref.watch(localeProvider).languageCode;
    final handler = ref.read(audioHandlerProvider);

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.search,
                  style: context.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                AppTextField(
                  controller: _searchController,
                  hintText: context.l10n.searchHint,
                  prefixIcon: Icons.search,
                  onChanged: (val) =>
                      ref.read(searchQueryProvider.notifier).updateQuery(val),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: query.isEmpty
                      ? _buildInitialState(context)
                      : resultsAsync.when(
                          data: (songs) => songs.isEmpty
                              ? _buildEmptyState(context)
                              : _buildResultsList(songs, locale, handler),
                          loading: () => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          error: (e, st) => Center(
                            child: Text(
                              'Error: $e',
                              style: const TextStyle(color: Colors.white70),
                            ),
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

  Widget _buildInitialState(BuildContext context) {
    return FadeIn(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.music_note_rounded,
              size: 80,
              color: context.colorScheme.onSurface.withValues(alpha: 0.1),
            ),
            const SizedBox(height: 16),
            Text(
              'Search for your favorite songs',
              style: context.textTheme.bodyLarge?.copyWith(
                color: context.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return FadeIn(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 80,
              color: context.colorScheme.onSurface.withValues(alpha: 0.1),
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.noResults,
              style: context.textTheme.bodyLarge?.copyWith(
                color: context.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList(
      List<Music> songs, String locale, RhythmAudioHandler handler) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        return FadeInUp(
          delay: Duration(milliseconds: index * 50),
          duration: const Duration(milliseconds: 300),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 4),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: song.thumbUrl != null
                  ? Image.network(
                      song.thumbUrl!,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 52,
                      height: 52,
                      color: Colors.white10,
                      child: const Icon(Icons.music_note, color: Colors.white24),
                    ),
            ),
            title: Text(
              song.getDisplayTitle(locale),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              song.getDisplayArtists(locale),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 13,
              ),
            ),
            onTap: () {
              final mediaItem = musicToMediaItem(song, locale);
              handler.loadPlaylist([mediaItem]);
              context.push('/player/${song.id}');
            },
          ),
        );
      },
    );
  }
}
