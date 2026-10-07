import 'package:flutter/material.dart';
import 'package:rhythm_flutter/features/auth/presentation/widgets/feature_badge_item.dart';
import 'package:rhythm_flutter/features/auth/presentation/widgets/music_lives_here_widget.dart';

/// The bottom bar of the desktop login screen containing feature badges and signature script.
class DesktopBottomBar extends StatelessWidget {
  const DesktopBottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 48, vertical: 28),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Left: 3 Feature Badges
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FeatureBadgeItem(
                icon: Icons.music_note_rounded,
                title: 'Listen',
                subtitle: 'Your favourite music',
              ),
              SizedBox(width: 32),
              FeatureBadgeItem(
                icon: Icons.favorite_border_rounded,
                title: 'Organize',
                subtitle: 'Create your vibe',
              ),
              SizedBox(width: 32),
              FeatureBadgeItem(
                icon: Icons.graphic_eq_rounded,
                title: 'Enjoy',
                subtitle: 'A better listening experience',
              ),
            ],
          ),

          // Right: "Music Lives Here" cursive script
          MusicLivesHereWidget(),
        ],
      ),
    );
  }
}
