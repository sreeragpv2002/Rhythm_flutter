import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rhythm_flutter/core/animations/app_animations.dart';
import 'package:rhythm_flutter/core/extensions/context_extensions.dart';
import 'package:rhythm_flutter/core/theme/spacing.dart';
import 'package:rhythm_flutter/features/home/data/models/home_feed.dart';
import 'package:rhythm_flutter/features/home/presentation/widgets/music_card.dart';
import 'package:rhythm_flutter/features/home/providers/home_provider.dart';
import 'package:rhythm_flutter/features/home/providers/favorites_provider.dart';
import 'package:rhythm_flutter/features/player/providers/audio_provider.dart';
import 'package:go_router/go_router.dart';

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
    final screenWidth = MediaQuery.of(context).size.width;

    // Desktop vs Mobile thresholds
    final bool isDesktop = screenWidth > 900;
    final bool isTablet = screenWidth > 600 && screenWidth <= 900;

    // Responsive grid column count
    final int crossAxisCount = isDesktop ? 5 : (isTablet ? 3 : 2);
    final double horizontalPadding = isDesktop ? AppSpacing.xl * 2 : AppSpacing.md;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: homeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('${context.l10n.error}: $err')),
        data: (feed) {
          if (feed == null) return const SizedBox.shrink();
          
          final section = feed.sections.firstWhere(
            (s) => s.slug == slug,
            orElse: () => HomeSection(title: title, slug: slug, items: []),
          );

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Responsive Header ──
              SliverAppBar(
                expandedHeight: isDesktop ? 200 : kToolbarHeight,
                floating: false,
                pinned: true,
                elevation: 0,
                scrolledUnderElevation: 2,
                backgroundColor: isDark
                    ? Colors.black.withValues(alpha: 0.8)
                    : Colors.white.withValues(alpha: 0.8),
                centerTitle: !isDesktop,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  onPressed: () => context.pop(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: EdgeInsetsDirectional.only(
                    start: isDesktop ? horizontalPadding : 56,
                    bottom: 16,
                  ),
                  title: Text(
                    section.getDisplayTitle(locale),
                    style: context.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ),

              // ── Responsive Content Grid ──
              SliverPadding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: AppSpacing.lg,
                ),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: isDesktop ? AppSpacing.lg : AppSpacing.md,
                    crossAxisSpacing: isDesktop ? AppSpacing.lg : AppSpacing.md,
                    childAspectRatio: isDesktop ? 0.8 : 0.72,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final music = feed.getMusicById(section.musicIds[index]);
                      if (music == null) return const SizedBox.shrink();

                      return FadeScaleIn(
                        delay: AppAnimations.stagger(index, baseMs: 40),
                        child: MusicCard(
                          music: music,
                          locale: locale,
                          isFavorite: ref.watch(favoritesProvider).contains(music.id),
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

              // Bottom Spacing for Player
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