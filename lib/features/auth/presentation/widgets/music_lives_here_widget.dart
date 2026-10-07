import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// "Music Lives Here" signature cursive script with neon magenta brush underline.
class MusicLivesHereWidget extends StatelessWidget {
  const MusicLivesHereWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.09, // ~ -5 degrees tilt
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Music',
            style: GoogleFonts.caveat(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              height: 1.0,
              shadows: [
                Shadow(
                  color: Colors.white.withValues(alpha: 0.4),
                  blurRadius: 12,
                ),
                Shadow(
                  color: const Color(0xFFD946EF).withValues(alpha: 0.6),
                  blurRadius: 24,
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const SizedBox(width: 14),
              Text(
                'Lives Here',
                style: GoogleFonts.caveat(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  height: 1.0,
                  shadows: [
                    Shadow(
                      color: Colors.white.withValues(alpha: 0.4),
                      blurRadius: 12,
                    ),
                    Shadow(
                      color: const Color(0xFFD946EF).withValues(alpha: 0.6),
                      blurRadius: 24,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Neon purple/magenta brush stroke underline
          Padding(
            padding: const EdgeInsets.only(left: 36),
            child: Container(
              width: 110,
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF8B5CF6),
                    Color(0xFFE040FB),
                    Color(0xFFFF52A2),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE040FB).withValues(alpha: 0.9),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
