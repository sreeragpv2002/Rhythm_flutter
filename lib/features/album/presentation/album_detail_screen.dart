import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rhythm_flutter/core/animations/app_animations.dart';
import 'package:rhythm_flutter/core/extensions/context_extensions.dart';
import 'package:rhythm_flutter/core/theme/app_colors.dart';
import 'package:rhythm_flutter/core/theme/spacing.dart';
import 'package:rhythm_flutter/core/theme/scroll_physics.dart';
import 'package:rhythm_flutter/core/widgets/shimmer_loading.dart';
import 'package:rhythm_flutter/features/album/data/models/album_detail.dart';
import 'package:rhythm_flutter/features/album/providers/album_provider.dart';
import 'package:rhythm_flutter/features/home/data/models/music.dart';
import 'package:rhythm_flutter/features/home/providers/favorites_provider.dart';
import 'package:rhythm_flutter/features/player/providers/audio_provider.dart';

class AlbumDetailScreen extends ConsumerWidget {
  final String albumId;

  const AlbumDetailScreen({
    super.key,
    required this.albumId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albumAsync = ref.watch(albumDetailProvider(albumId));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 860;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0B14) : const Color(0xFFF7F7FC),
      body: albumAsync.when(
        loading: () => _AlbumLoadingSkeleton(isDesktop: isDesktop),
        error: (err, stack) => _AlbumErrorView(
          errorMessage: err.toString(),
          onRetry: () => ref.refresh(albumDetailProvider(albumId)),
        ),
        data: (album) {
          if (isDesktop) {
            return _DesktopAlbumView(album: album);
          }
          return _MobileAlbumView(album: album);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 📱 Mobile Album View (Sliver Collapsing Layout)
// ─────────────────────────────────────────────────────────────────────────────

class _MobileAlbumView extends ConsumerWidget {
  final AlbumDetail album;

  const _MobileAlbumView({required this.album});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = context.l10n.localeName;
    final currentMedia = ref.watch(currentMediaItemProvider).value;
    final isPlaying = ref.watch(playbackStateProvider).value?.playing ?? false;
    final favorites = ref.watch(favoritesProvider);
    final handler = ref.read(audioHandlerProvider);

    return CustomScrollView(
      physics: AppScrollPhysics.adaptive,
      slivers: [
        // ── Sliver App Bar with Dynamic Glow Header ──
        SliverAppBar(
          expandedHeight: 380,
          pinned: true,
          stretch: true,
          elevation: 0,
          backgroundColor: isDark
              ? const Color(0xFF0E0E1B).withValues(alpha: 0.95)
              : Colors.white.withValues(alpha: 0.95),
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: _CircleIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onPressed: () => context.pop(),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: _CircleIconButton(
                icon: Icons.share_rounded,
                onPressed: () {
                  if (album.url != null && album.url!.isNotEmpty) {
                    Clipboard.setData(ClipboardData(text: album.url!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Album link copied to clipboard!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.parallax,
            titlePadding: const EdgeInsets.only(left: 56, right: 56, bottom: 16),
            title: Text(
              album.displayTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            background: Stack(
              fit: StackFit.expand,
              children: [
                // Ambient Blurry Backdrop
                if (album.imageUrl != null)
                  Positioned.fill(
                    child: Opacity(
                      opacity: isDark ? 0.35 : 0.2,
                      child: CachedNetworkImage(
                        imageUrl: album.imageUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ),

                // Gradient Overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          isDark
                              ? const Color(0xFF0B0B14).withValues(alpha: 0.8)
                              : const Color(0xFFF7F7FC).withValues(alpha: 0.8),
                          isDark ? const Color(0xFF0B0B14) : const Color(0xFFF7F7FC),
                        ],
                        stops: const [0.0, 0.6, 1.0],
                      ),
                    ),
                  ),
                ),

                // Hero Artwork & Info
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 48, 20, 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Album Artwork with Ambient Shadow
                        _AlbumCoverArtwork(
                          imageUrl: album.imageUrl,
                          size: 170,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 14),

                        // Album Title
                        Text(
                          album.displayTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : Colors.black87,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Artists
                        if (album.displayArtists.isNotEmpty)
                          Text(
                            album.displayArtists,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : Colors.black54,
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

        // ── Badges & Action Bar ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // Metadata Chips Row (Year, Language, Songs Count, Duration)
                _MetadataBadgesRow(album: album, isDark: isDark),

                const SizedBox(height: 16),

                // Action Buttons Row (Play All, Shuffle)
                _AlbumActionButtons(
                  album: album,
                  locale: locale,
                  isDark: isDark,
                ),

                const SizedBox(height: 20),

                // Primary Artists Horizontal Row (if available)
                if (album.primaryArtists.isNotEmpty) ...[
                  _ArtistsAvatarRow(
                    artists: album.primaryArtists,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 20),
                ],

                // Tracklist Header
                Row(
                  children: [
                    Text(
                      'TRACKS (${album.songs.length})',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: (isDark ? Colors.white : Colors.black)
                            .withValues(alpha: 0.5),
                      ),
                    ),
                    const Spacer(),
                    if (album.formattedTotalDuration.isNotEmpty)
                      Text(
                        album.formattedTotalDuration,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: (isDark ? Colors.white : Colors.black)
                              .withValues(alpha: 0.4),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),

        // ── Songs List ──
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final song = album.songs[index];
                final isCurrent = currentMedia?.id == song.id.toString();
                final isFav = favorites.contains(song.id);

                return FadeScaleIn(
                  delay: AppAnimations.stagger(index, baseMs: 30),
                  child: _AlbumTrackTile(
                    index: index + 1,
                    song: song,
                    isCurrentSong: isCurrent,
                    isPlaying: isCurrent && isPlaying,
                    isFavorite: isFav,
                    isDark: isDark,
                    onTap: () {
                      final mediaItems = album.toMediaItems(locale);
                      handler.loadPlaylist(
                        mediaItems,
                        initialIndex: index,
                        source: QueueSource.album,
                      );
                    },
                    onFavoriteToggle: () async {
                      await ref
                          .read(favoritesProvider.notifier)
                          .toggleFavorite(song.id);
                      if (currentMedia?.id == song.id.toString()) {
                        final updatedIsFav =
                            ref.read(favoritesProvider).contains(song.id);
                        handler.updateMediaItemFavorite(
                            song.id.toString(), updatedIsFav);
                      }
                    },
                  ),
                );
              },
              childCount: album.songs.length,
            ),
          ),
        ),

        // ── Copyright & Info Footer ──
        SliverToBoxAdapter(
          child: _AlbumFooterInfo(album: album, isDark: isDark),
        ),

        // Player padding
        const SliverToBoxAdapter(
          child: SizedBox(height: AppSpacing.miniPlayerHeight + AppSpacing.xxl),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 💻 Desktop Album View (Dual Column Layout)
// ─────────────────────────────────────────────────────────────────────────────

class _DesktopAlbumView extends ConsumerWidget {
  final AlbumDetail album;

  const _DesktopAlbumView({required this.album});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = context.l10n.localeName;
    final currentMedia = ref.watch(currentMediaItemProvider).value;
    final isPlaying = ref.watch(playbackStateProvider).value?.playing ?? false;
    final favorites = ref.watch(favoritesProvider);
    final handler = ref.read(audioHandlerProvider);

    return SafeArea(
      child: Column(
        children: [
          // Top Navigation Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                _CircleIconButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onPressed: () => context.pop(),
                ),
                const SizedBox(width: 16),
                Text(
                  'Album Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const Spacer(),
                _CircleIconButton(
                  icon: Icons.share_rounded,
                  onPressed: () {
                    if (album.url != null && album.url!.isNotEmpty) {
                      Clipboard.setData(ClipboardData(text: album.url!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Album link copied to clipboard!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),

          // Two-column Content
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Album Showcase & Controls (Fixed / Scrollable)
                SizedBox(
                  width: 380,
                  child: SingleChildScrollView(
                    physics: AppScrollPhysics.adaptive,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _AlbumCoverArtwork(
                          imageUrl: album.imageUrl,
                          size: 260,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 20),

                        Text(
                          album.displayTitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : Colors.black87,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),

                        if (album.displayArtists.isNotEmpty)
                          Text(
                            album.displayArtists,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        const SizedBox(height: 16),

                        _MetadataBadgesRow(album: album, isDark: isDark),
                        const SizedBox(height: 24),

                        _AlbumActionButtons(
                          album: album,
                          locale: locale,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 24),

                        if (album.primaryArtists.isNotEmpty) ...[
                          _ArtistsAvatarRow(
                            artists: album.primaryArtists,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 20),
                        ],
                      ],
                    ),
                  ),
                ),

                // Vertical Divider
                Container(
                  width: 1,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06),
                ),

                // Right Column: Tracklist & Release Info
                Expanded(
                  child: ListView.builder(
                    physics: AppScrollPhysics.adaptive,
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                    itemCount: album.songs.length + 1,
                    itemBuilder: (context, index) {
                      if (index == album.songs.length) {
                        return _AlbumFooterInfo(album: album, isDark: isDark);
                      }

                      final song = album.songs[index];
                      final isCurrent = currentMedia?.id == song.id.toString();
                      final isFav = favorites.contains(song.id);

                      return _AlbumTrackTile(
                        index: index + 1,
                        song: song,
                        isCurrentSong: isCurrent,
                        isPlaying: isCurrent && isPlaying,
                        isFavorite: isFav,
                        isDark: isDark,
                        onTap: () {
                          final mediaItems = album.toMediaItems(locale);
                          handler.loadPlaylist(
                            mediaItems,
                            initialIndex: index,
                            source: QueueSource.album,
                          );
                        },
                        onFavoriteToggle: () async {
                          await ref
                              .read(favoritesProvider.notifier)
                              .toggleFavorite(song.id);
                          if (currentMedia?.id == song.id.toString()) {
                            final updatedIsFav =
                                ref.read(favoritesProvider).contains(song.id);
                            handler.updateMediaItemFavorite(
                                song.id.toString(), updatedIsFav);
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 🖼️ Reusable Subwidgets & Micro-components
// ─────────────────────────────────────────────────────────────────────────────

class _AlbumCoverArtwork extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final bool isDark;

  const _AlbumCoverArtwork({
    required this.imageUrl,
    required this.size,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                .withValues(alpha: 0.35),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                memCacheWidth: (size * 2).toInt(),
                placeholder: (_, __) => _placeholder(),
                errorWidget: (_, __, ___) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: isDark ? const Color(0xFF1F1F35) : const Color(0xFFE2E2EE),
      child: Center(
        child: Icon(
          Icons.album_rounded,
          size: size * 0.4,
          color: isDark ? Colors.white24 : Colors.black26,
        ),
      ),
    );
  }
}

class _MetadataBadgesRow extends StatelessWidget {
  final AlbumDetail album;
  final bool isDark;

  const _MetadataBadgesRow({
    required this.album,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        if (album.displayYear.isNotEmpty)
          _BadgeChip(
            icon: Icons.calendar_today_rounded,
            label: album.displayYear,
            isDark: isDark,
          ),
        if (album.language.isNotEmpty)
          _BadgeChip(
            icon: Icons.translate_rounded,
            label: album.displayLanguage,
            isDark: isDark,
          ),
        _BadgeChip(
          icon: Icons.queue_music_rounded,
          label: '${album.songs.length} Tracks',
          isDark: isDark,
        ),
        if (album.explicitContent)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: Colors.redAccent.withValues(alpha: 0.4),
                width: 0.7,
              ),
            ),
            child: const Text(
              'EXPLICIT',
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
      ],
    );
  }
}

class _BadgeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _BadgeChip({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.06),
          width: 0.6,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlbumActionButtons extends ConsumerWidget {
  final AlbumDetail album;
  final String locale;
  final bool isDark;

  const _AlbumActionButtons({
    required this.album,
    required this.locale,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final handler = ref.read(audioHandlerProvider);

    return Row(
      children: [
        // ── Play All Button ──
        Expanded(
          flex: 3,
          child: GestureDetector(
            onTap: () {
              if (album.songs.isNotEmpty) {
                final mediaItems = album.toMediaItems(locale);
                handler.loadPlaylist(
                  mediaItems,
                  initialIndex: 0,
                  source: QueueSource.album,
                );
              }
            },
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryLight.withValues(alpha: 0.4),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_arrow_rounded, color: Colors.white, size: 26),
                  SizedBox(width: 6),
                  Text(
                    'PLAY ALL',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // ── Shuffle Button ──
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: () {
              if (album.songs.isNotEmpty) {
                final mediaItems =
                    List.of(album.toMediaItems(locale))..shuffle();
                handler.loadPlaylist(
                  mediaItems,
                  initialIndex: 0,
                  source: QueueSource.album,
                );
              }
            },
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.15)
                      : Colors.black.withValues(alpha: 0.1),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shuffle_rounded,
                    color: isDark ? Colors.white : Colors.black87,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'SHUFFLE',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ArtistsAvatarRow extends StatelessWidget {
  final List<AlbumArtist> artists;
  final bool isDark;

  const _ArtistsAvatarRow({
    required this.artists,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ARTISTS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.45),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: AppScrollPhysics.adaptive,
            itemCount: artists.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final artist = artists[index];
              return GestureDetector(
                onTap: () {
                  if (artist.id.isNotEmpty) {
                    context.push('/artist/${artist.id}');
                  }
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: isDark
                          ? const Color(0xFF222238)
                          : const Color(0xFFE5E5F0),
                      backgroundImage: artist.avatarUrl != null &&
                              artist.avatarUrl!.isNotEmpty
                          ? CachedNetworkImageProvider(artist.avatarUrl!)
                          : null,
                      child: (artist.avatarUrl == null || artist.avatarUrl!.isEmpty)
                          ? Icon(
                              Icons.person_rounded,
                              size: 22,
                              color: isDark ? Colors.white38 : Colors.black38,
                            )
                          : null,
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: 68,
                      child: Text(
                        artist.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AlbumTrackTile extends StatefulWidget {
  final int index;
  final Music song;
  final bool isCurrentSong;
  final bool isPlaying;
  final bool isFavorite;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;

  const _AlbumTrackTile({
    required this.index,
    required this.song,
    required this.isCurrentSong,
    required this.isPlaying,
    required this.isFavorite,
    required this.isDark,
    required this.onTap,
    required this.onFavoriteToggle,
  });

  @override
  State<_AlbumTrackTile> createState() => _AlbumTrackTileState();
}

class _AlbumTrackTileState extends State<_AlbumTrackTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final locale = context.l10n.localeName;
    final primaryColor = widget.isDark
        ? AppColors.primaryDark
        : AppColors.primaryLight;

    return MouseRegion(
      onEnter: (_) {
        if (mounted) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (mounted) setState(() => _isHovered = false);
      },
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isCurrentSong
                ? primaryColor.withValues(alpha: widget.isDark ? 0.15 : 0.1)
                : (_isHovered
                    ? (widget.isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.03))
                    : Colors.transparent),
            borderRadius: BorderRadius.circular(10),
            border: widget.isCurrentSong
                ? Border.all(
                    color: primaryColor.withValues(alpha: 0.3),
                    width: 0.8,
                  )
                : null,
          ),
          child: Row(
            children: [
              // ── Track Number or Equalizer ──
              SizedBox(
                width: 28,
                child: Center(
                  child: widget.isCurrentSong
                      ? _MiniEqualizer(
                          isPlaying: widget.isPlaying,
                          color: primaryColor,
                        )
                      : Text(
                          '${widget.index}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: (widget.isDark
                                    ? Colors.white
                                    : Colors.black)
                                .withValues(alpha: 0.35),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 10),

              // ── Song Details (Title + Singers) ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.song.getDisplayTitle(locale),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: widget.isCurrentSong
                            ? primaryColor
                            : (widget.isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.song.getDisplayArtists(locale),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: (widget.isDark ? Colors.white : Colors.black)
                            .withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Duration Label ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  _formatDuration(Duration(seconds: widget.song.duration)),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: (widget.isDark ? Colors.white : Colors.black)
                        .withValues(alpha: 0.4),
                  ),
                ),
              ),

              // ── Favorite Heart Button ──
              IconButton(
                iconSize: 19,
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  widget.isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: widget.isFavorite
                      ? const Color(0xFFFF6B6B)
                      : (widget.isDark ? Colors.white : Colors.black)
                          .withValues(alpha: 0.3),
                ),
                onPressed: widget.onFavoriteToggle,
              ),

              // ── Context Menu ──
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  size: 18,
                  color: (widget.isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.4),
                ),
                color: widget.isDark ? const Color(0xFF1E1E2E) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'play_next',
                    child: Row(
                      children: const [
                        Icon(Icons.playlist_play_rounded, size: 20),
                        SizedBox(width: 10),
                        Text('Play Next'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'view_song',
                    child: Row(
                      children: const [
                        Icon(Icons.info_outline_rounded, size: 20),
                        SizedBox(width: 10),
                        Text('Song Details'),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'view_song') {
                    context.push('/player/${widget.song.rawStringId}');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _MiniEqualizer extends StatefulWidget {
  final bool isPlaying;
  final Color color;

  const _MiniEqualizer({
    required this.isPlaying,
    required this.color,
  });

  @override
  State<_MiniEqualizer> createState() => _MiniEqualizerState();
}

class _MiniEqualizerState extends State<_MiniEqualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    if (widget.isPlaying) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _MiniEqualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final val = _controller.value;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _bar(4 + (val * 10)),
            const SizedBox(width: 2),
            _bar(12 - (val * 8)),
            const SizedBox(width: 2),
            _bar(6 + (val * 8)),
          ],
        );
      },
    );
  }

  Widget _bar(double height) {
    return Container(
      width: 2.5,
      height: widget.isPlaying ? height.clamp(3.0, 16.0) : 6.0,
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _CircleIconButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark
            ? Colors.black.withValues(alpha: 0.45)
            : Colors.white.withValues(alpha: 0.8),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.08),
          width: 0.8,
        ),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(
          icon,
          size: 18,
          color: isDark ? Colors.white : Colors.black87,
        ),
        onPressed: onPressed,
      ),
    );
  }
}

class _AlbumFooterInfo extends StatelessWidget {
  final AlbumDetail album;
  final bool isDark;

  const _AlbumFooterInfo({
    required this.album,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),
          const SizedBox(height: 14),
          if (album.description != null && album.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                album.description!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.5),
                ),
              ),
            ),
          Text(
            '${album.songCount} Songs • ${album.displayLanguage} • ${album.displayYear}',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: (isDark ? Colors.white : Colors.black)
                  .withValues(alpha: 0.35),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 💀 Loading Skeleton & Error View
// ─────────────────────────────────────────────────────────────────────────────

class _AlbumLoadingSkeleton extends StatelessWidget {
  final bool isDesktop;

  const _AlbumLoadingSkeleton({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Center(
              child: Container(
                width: isDesktop ? 220 : 160,
                height: isDesktop ? 220 : 160,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFE5E5F0),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 200,
              height: 20,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFE5E5F0),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: 140,
              height: 14,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFE5E5F0),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 30),
            ...List.generate(
              6,
              (index) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ShimmerLoading.listTile(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlbumErrorView extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;

  const _AlbumErrorView({
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.album_outlined,
              size: 56,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
            const SizedBox(height: 16),
            Text(
              'Could not load album',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryLight,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
