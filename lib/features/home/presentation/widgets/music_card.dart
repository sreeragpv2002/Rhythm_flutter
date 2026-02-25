import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:rhythm_flutter/core/theme/app_colors.dart';
import 'package:rhythm_flutter/core/theme/spacing.dart';
import 'package:rhythm_flutter/features/home/data/models/music.dart';

/// Horizontal music card for the home feed.
///
/// Displays thumbnail with glassmorphism overlay, title, and artist.
/// Adds a subtle scale animation on tap.
class MusicCard extends StatefulWidget {
  final Music music;
  final String locale;
  final VoidCallback? onTap;

  const MusicCard({
    super.key,
    required this.music,
    required this.locale,
    this.onTap,
  });

  @override
  State<MusicCard> createState() => _MusicCardState();
}

class _MusicCardState extends State<MusicCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) {
        _scaleController.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _scaleController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: SizedBox(
          width: AppSpacing.thumbnailLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Thumbnail with glassmorphism overlay ──
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: SizedBox(
                  width: AppSpacing.thumbnailLg,
                  height: 140,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      widget.music.thumbUrl != null
                          ? CachedNetworkImage(
                              imageUrl: widget.music.thumbUrl!,
                              fit: BoxFit.cover,
                              memCacheWidth: (AppSpacing.thumbnailLg * 2).toInt(),
                              placeholder: (_, __) => _placeholder(context),
                              errorWidget: (_, __, ___) => _placeholder(context),
                            )
                          : _placeholder(context),

                      // Glassmorphism overlay at bottom
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.5),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.sm + 4),

              // ── Title ──
              Text(
                widget.music.getDisplayTitle(widget.locale),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 2),

              // ── Artist ──
              Text(
                widget.music.getDisplayArtists(widget.locale),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.55)
                      : AppColors.textSecondaryLight,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
      child: Center(
        child: Icon(
          Icons.music_note_rounded,
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          size: AppSpacing.iconXl,
        ),
      ),
    );
  }
}
