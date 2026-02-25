import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rhythm_flutter/core/animations/app_animations.dart';
import 'package:rhythm_flutter/core/extensions/context_extensions.dart';
import 'package:rhythm_flutter/core/services/media_item_mapper.dart';
import 'package:rhythm_flutter/core/theme/spacing.dart';
import 'package:rhythm_flutter/features/home/data/models/home_feed.dart';
import 'package:rhythm_flutter/features/home/presentation/widgets/music_card.dart';
import 'package:rhythm_flutter/features/home/providers/home_provider.dart';
import 'package:rhythm_flutter/features/player/providers/audio_provider.dart';

class SectionDetailScreen extends ConsumerWidget {
  final String slug;
  final String title;

  const SectionDetailScreen({
    super.key,
    required this.slug,
    required this.title,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeAsync = ref.watch(homeProvider);
    final locale = context.l10n.localeName;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: homeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('${context.l10n.error}: $err')),
        data: (feed) {
          final section = feed.sections.firstWhere(
            (s) => s.slug == slug,
            orElse: () => HomeSection(title: title, slug: slug, items: []),
          );

          if (section.musicIds.isEmpty) {
            return Center(child: Text(context.l10n.noSongsFound));
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                floating: true,
                pinned: true,
                backgroundColor: isDark ? Colors.black : Colors.white,
                elevation: 0,
                title: Text(
                  section.getDisplayTitle(locale),
                  style: context.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.md),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: AppSpacing.md,
                    crossAxisSpacing: AppSpacing.md,
                    childAspectRatio: 0.75,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final music = feed.getMusicById(section.musicIds[index]);
                      if (music == null) return const SizedBox.shrink();

                      return FadeScaleIn(
                        delay: AppAnimations.stagger(index, baseMs: 50),
                        child: MusicCard(
                          music: music,
                          locale: locale,
                          onTap: () {
                            final handler = ref.read(audioHandlerProvider);
                            final sectionMusic = section.musicIds
                                .map((id) => feed.getMusicById(id))
                                .whereType<dynamic>()
                                .toList();
                            final mediaItems = sectionMusic
                                .map((m) => musicToMediaItem(m, locale))
                                .toList();
                            handler.loadPlaylist(mediaItems, initialIndex: index);
                          },
                        ),
                      );
                    },
                    childCount: section.musicIds.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.miniPlayerHeight + AppSpacing.xl),
              ),
            ],
          );
        },
      ),
    );
  }
}
