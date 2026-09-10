import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:rhythm_flutter/core/extensions/context_extensions.dart';
import 'package:rhythm_flutter/core/theme/app_colors.dart';
import 'package:rhythm_flutter/core/theme/spacing.dart';
import 'package:rhythm_flutter/features/home/data/models/home_feed.dart';

/// Senior-styled card widget for rendering items from the Home API (Song, Album, Playlist, Artist).
/// Includes desktop hover elevation, smooth scale animations, and play button overlay.
class HomeItemCard extends StatefulWidget {
  final HomeItem item;
  final VoidCallback? onTap;

  const HomeItemCard({
    super.key,
    required this.item,
    this.onTap,
  });

  @override
  State<HomeItemCard> createState() => _HomeItemCardState();
}

class _HomeItemCardState extends State<HomeItemCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressScaleController;
  late final Animation<double> _pressScaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _pressScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
    );
    _pressScaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _pressScaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressScaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArtist = widget.item.isArtist;

    return MouseRegion(
      onEnter: (_) {
        if (mounted) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (mounted) setState(() => _isHovered = false);
      },
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => _pressScaleController.forward(),
        onTapUp: (_) {
          _pressScaleController.reverse();
          widget.onTap?.call();
        },
        onTapCancel: () => _pressScaleController.reverse(),
        child: ScaleTransition(
          scale: _pressScaleAnimation,
          child: SizedBox(
            width: isArtist ? 100 : AppSpacing.thumbnailLg,
            child: Column(
              mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: isArtist
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.start,
                children: [
                  // ── Thumbnail / Avatar ──
                  if (isArtist)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _isHovered
                              ? (isDark
                                  ? AppColors.primaryDark
                                  : AppColors.primaryLight)
                              : Colors.transparent,
                          width: 2.0,
                        ),
                        boxShadow: _isHovered
                            ? [
                                BoxShadow(
                                  color: (isDark
                                          ? AppColors.primaryDark
                                          : AppColors.primaryLight)
                                      .withValues(alpha: 0.35),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: ClipOval(
                        child: _buildImage(context, isArtist: true),
                      ),
                    )
                  else
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                        boxShadow: _isHovered
                            ? [
                                BoxShadow(
                                  color: (isDark
                                          ? AppColors.primaryDark
                                          : AppColors.primaryLight)
                                      .withValues(alpha: 0.3),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(
                                      alpha: isDark ? 0.4 : 0.15),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                      alpha: isDark ? 0.25 : 0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                      ),
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                        child: SizedBox(
                          width: AppSpacing.thumbnailLg,
                          height: 140,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              _buildImage(context, isArtist: false),

                              // Bottom gradient shadow for contrast
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: 44,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withValues(alpha: 0.7),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // Type badge for albums & playlists
                              if (widget.item.isAlbum || widget.item.isPlaylist)
                                Positioned(
                                  top: 8,
                                  left: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black
                                          .withValues(alpha: 0.65),
                                      borderRadius: BorderRadius.circular(5),
                                      border: Border.all(
                                        color: Colors.white
                                            .withValues(alpha: 0.15),
                                        width: 0.5,
                                      ),
                                    ),
                                    child: Text(
                                      widget.item.type.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  ),
                                ),

                              // Floating Play Button on Hover or Song Badge
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: AnimatedScale(
                                  scale: (_isHovered || widget.item.isSong)
                                      ? 1.0
                                      : 0.0,
                                  duration: const Duration(milliseconds: 180),
                                  curve: Curves.easeOutBack,
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: AppColors.primaryGradient,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primaryLight
                                              .withValues(alpha: 0.45),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.play_arrow_rounded,
                                        size: 20,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: AppSpacing.sm),

                  // ── Title ──
                  Text(
                    widget.item.displayTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: isArtist ? TextAlign.center : TextAlign.start,
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 2),

                  // ── Subtitle ──
                  Text(
                    widget.item.displaySubtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: isArtist ? TextAlign.center : TextAlign.start,
                    style: context.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: (isDark ? Colors.white : Colors.black)
                          .withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
  }

  Widget _buildImage(BuildContext context, {required bool isArtist}) {
    final imageUrl = widget.item.displayImage;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        memCacheWidth: (AppSpacing.thumbnailLg * 2).toInt(),
        placeholder: (_, __) => _placeholder(context, isArtist: isArtist),
        errorWidget: (_, __, ___) => _placeholder(context, isArtist: isArtist),
      );
    }
    return _placeholder(context, isArtist: isArtist);
  }

  Widget _placeholder(BuildContext context, {required bool isArtist}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark
          ? AppColors.surfaceElevatedDark
          : AppColors.surfaceElevatedLight,
      child: Center(
        child: Icon(
          isArtist ? Icons.person_rounded : Icons.music_note_rounded,
          color: isDark ? Colors.white24 : Colors.black26,
          size: isArtist ? 42 : 34,
        ),
      ),
    );
  }
}
