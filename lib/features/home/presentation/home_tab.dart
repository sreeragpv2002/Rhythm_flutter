import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rhythm_flutter/core/extensions/context_extensions.dart';
import 'package:rhythm_flutter/core/widgets/gradient_background.dart';
import 'package:rhythm_flutter/features/home/providers/home_provider.dart';
import 'package:rhythm_flutter/features/home/data/models/music.dart';
import 'package:rhythm_flutter/features/home/presentation/widgets/music_card.dart';

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  /// Open the player for a specific song ID
  void _playSong(BuildContext context, int musicId) {
    context.push('/player/$musicId');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeAsync = ref.watch(homeProvider);
    final locale = context.l10n.localeName;

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () => ref.read(homeProvider.notifier).fetchHomeFeed(),
            child: homeAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: $err'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.read(homeProvider.notifier).fetchHomeFeed(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (homeFeed) => CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  _buildHeader(context),
                  ...homeFeed.sections.map((section) {
                    // Normalize items using the map (O(1) lookup)
                    final musicList = section.items
                        .map((id) => homeFeed.musicMap[id.toString()])
                        .whereType<Music>()
                        .toList();

                    if (musicList.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

                    // Render based on slug or section type if needed
                    // For Spotify-like experience, we usually use horizontal lists for most sections
                    return SliverMainAxisGroup(
                      slivers: [
                        _buildSectionHeader(context, section.title),
                        _buildHorizontalMusicList(context, ref, musicList, locale),
                      ],
                    );
                  }),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(24),
      sliver: SliverToBoxAdapter(
        child: FadeInDown(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.welcomeMessage,
                    style: context.textTheme.headlineMedium,
                  ),
                  Text(
                    context.l10n.explore,
                    style: context.textTheme.bodyMedium,
                  ),
                ],
              ),
              const CircleAvatar(
                radius: 24,
                child: Icon(Icons.person),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      sliver: SliverToBoxAdapter(
        child: Text(
          title,
          style: context.textTheme.titleLarge,
        ),
      ),
    );
  }

  Widget _buildHorizontalMusicList(
    BuildContext context,
    WidgetRef ref,
    List<Music> musicList,
    String locale,
  ) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 230,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: musicList.length,
          itemBuilder: (context, index) {
            final music = musicList[index];
            return MusicCard(
              music: music,
              locale: locale,
              onTap: () => _playSong(context, music.id),
            );
          },
        ),
      ),
    );
  }
}
