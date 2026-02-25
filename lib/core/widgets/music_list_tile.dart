import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:rhythm_flutter/core/theme/spacing.dart';

/// Shared, reusable music list tile widget.
///
/// Used in Search results, Related Songs, and anywhere a song is shown
/// in vertical list format. Consolidates duplicated list tile code.
class MusicListTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? imageUrl;
  final String? trailing;
  final VoidCallback? onTap;
  final bool? isFavorite;
  final VoidCallback? onFavoriteToggle;
  final double thumbnailSize;

  const MusicListTile({
    super.key,
    required this.title,
    required this.subtitle,
    this.imageUrl,
    this.trailing,
    this.onTap,
    this.isFavorite,
    this.onFavoriteToggle,
    this.thumbnailSize = AppSpacing.thumbnailMd,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            // ── Thumbnail ──
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: SizedBox(
                width: thumbnailSize,
                height: thumbnailSize,
                child: imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: imageUrl!,
                        fit: BoxFit.cover,
                        memCacheWidth: (thumbnailSize * 2).toInt(),
                        placeholder: (_, __) => _placeholder(colorScheme),
                        errorWidget: (_, __, ___) => _placeholder(colorScheme),
                      )
                    : _placeholder(colorScheme),
              ),
            ),
            const SizedBox(width: AppSpacing.sm + 4),

            // ── Text ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark ? Colors.white : colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: (isDark ? Colors.white : colorScheme.onSurface)
                          .withValues(alpha: 0.55),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // ── Trailing ──
            if (trailing != null)
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.sm),
                child: Text(
                  trailing!,
                  style: TextStyle(
                    color: (isDark ? Colors.white : colorScheme.onSurface)
                        .withValues(alpha: 0.4),
                    fontSize: 12,
                  ),
                ),
              ),

            // ── Favorite Toggle ──
            if (onFavoriteToggle != null)
              IconButton(
                icon: Icon(
                  isFavorite == true ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  size: 20,
                  color: isFavorite == true ? const Color(0xFFFF6B6B) : (isDark ? Colors.white : colorScheme.onSurface).withValues(alpha: 0.35),
                ),
                onPressed: onFavoriteToggle,
              ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.primary.withValues(alpha: 0.1),
      child: Icon(
        Icons.music_note_rounded,
        color: colorScheme.primary.withValues(alpha: 0.3),
        size: AppSpacing.iconMd,
      ),
    );
  }
}
