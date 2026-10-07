import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// One of the three bottom feature badges on Desktop: Listen, Organize, Enjoy.
class FeatureBadgeItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const FeatureBadgeItem({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Rounded glass icon box
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: Colors.white.withValues(alpha: 0.85),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        // Title & subtitle
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.outfit(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
