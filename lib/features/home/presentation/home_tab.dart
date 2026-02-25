import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rhythm_flutter/core/animations/app_animations.dart';
import 'package:rhythm_flutter/core/extensions/context_extensions.dart';
import 'package:rhythm_flutter/core/services/media_item_mapper.dart';
import 'package:rhythm_flutter/core/theme/spacing.dart';
import 'package:rhythm_flutter/core/widgets/shimmer_loading.dart';
import 'package:rhythm_flutter/features/home/presentation/widgets/music_card.dart';
import 'package:rhythm_flutter/features/home/providers/home_provider.dart';
import 'package:rhythm_flutter/features/home/data/models/home_feed.dart';
import 'package:rhythm_flutter/features/player/providers/audio_provider.dart';
import 'package:rhythm_flutter/core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeAsync = ref.watch(homeProvider);
    final handler = ref.read(audioHandlerProvider);
    final locale = context.l10n.localeName;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return homeAsync.when(
      loading: () => _buildShimmer(),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: AppSpacing.iconXl, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: AppSpacing.md),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: context.textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: () => ref.read(homeProvider.notifier).fetchHomeFeed(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (feed) {
        if (feed == null || feed.sections.isEmpty) {
          return Center(child: Text(context.l10n.noResults));
        }

        return RefreshIndicator(
          onRefresh: () => ref.read(homeProvider.notifier).fetchHomeFeed(),
          displacement: AppSpacing.xl,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverAppBar(
                floating: true,
                pinned: false,
                snap: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                surfaceTintColor: Colors.transparent,
                title: Text(
                  'Rhythm',
                  style: context.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                centerTitle: false,
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.xs),
              ),
              ...feed.sections.asMap().entries.map((entry) {
                final sectionIndex = entry.key;
                final section = entry.value;

                return SliverMainAxisGroup(
                  slivers: [
                    SliverToBoxAdapter(
                      child: SlideUpFadeIn(
                        delay: AppAnimations.stagger(sectionIndex),
                        duration: AppAnimations.normal,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            AppSpacing.sm,
                            AppSpacing.md,
                            AppSpacing.sm + 4,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                section.getDisplayTitle(locale),
                                style: context.textTheme.titleLarge?.copyWith(
                                  color: isDark ? Colors.white : null,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  context.push(
                                    '/section/${section.slug}',
                                    extra: section.getDisplayTitle(locale),
                                  );
                                },
                                child: Text(
                                  context.l10n.viewAll,
                                  style: TextStyle(
                                    color: isDark
                                        ? AppColors.primaryDark
                                        : AppColors.primaryLight,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 220,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          cacheExtent: 200,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          itemCount: math.min(8, section.musicIds.length),
                          itemBuilder: (context, index) {
                            final music = feed.getMusicById(section.musicIds[index]);
                            if (music == null) return const SizedBox.shrink();

                            return FadeScaleIn(
                              delay: AppAnimations.stagger(index, baseMs: 40),
                              duration: AppAnimations.normal,
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: index != math.min(8, section.musicIds.length) - 1
                                      ? AppSpacing.sm + 4
                                      : 0,
                                ),
                                child: MusicCard(
                                  music: music,
                                  locale: locale,
                                  onTap: () {
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
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: AppSpacing.sm),
                    ),
                  ],
                );
              }),
              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.xxl + AppSpacing.miniPlayerHeight),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Shimmer skeleton while loading
  Widget _buildShimmer() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: ShimmerBox(
            width: 100,
            height: 24,
            borderRadius: AppSpacing.radiusSm,
          ),
          centerTitle: false,
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xs)),
        ...List.generate(3, (sectionIdx) {
          return SliverMainAxisGroup(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.sm + 4,
                  ),
                  child: ShimmerBox(
                    width: 140,
                    height: 22,
                    borderRadius: AppSpacing.radiusSm,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 220,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    itemCount: 4,
                    itemBuilder: (_, idx) => Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm + 4),
                      child: ShimmerLoading.musicCard(),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),
            ],
          );
        }),
      ],
    );
  }
}
