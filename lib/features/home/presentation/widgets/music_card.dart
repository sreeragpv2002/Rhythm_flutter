import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:rhythm_flutter/core/extensions/context_extensions.dart';
import 'package:rhythm_flutter/features/home/data/models/music.dart';

class MusicCard extends StatelessWidget {
  final Music music;
  final String locale;
  final VoidCallback onTap;

  const MusicCard({
    super.key,
    required this.music,
    required this.locale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'music_${music.id}',
              child: Container(
                height: 140,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: music.thumbUrl != null
                    ? CachedNetworkImage(
                        imageUrl: music.thumbUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder: (context, url) => Center(
                          child: Opacity(
                            opacity: 0.1,
                            child: Icon(Icons.music_note,
                                size: 40, color: colorScheme.primary),
                          ),
                        ),
                        errorWidget: (context, url, error) => const Center(
                          child: Icon(Icons.broken_image_rounded,
                              size: 40, color: Colors.white24),
                        ),
                      )
                    : const Center(child: Icon(Icons.music_note, size: 40)),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              music.getDisplayTitle(locale),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              music.getDisplayArtists(locale),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
