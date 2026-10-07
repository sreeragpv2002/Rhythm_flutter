import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rhythm_flutter/features/auth/presentation/widgets/rhythm_equalizer_icon.dart';

/// Top bar header for Desktop layout.
class DesktopHeader extends StatelessWidget {
  const DesktopHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: Logo + "Rhythm" + "Feel the Music"
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const RhythmEqualizerIcon(size: 32),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Rhythm',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    'Feel the Music',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFE879F9).withValues(alpha: 0.85),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Right: "Your Music. Your Space. —"
          Text(
            'Your Music. Your Space. —',
            style: GoogleFonts.outfit(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 13,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Centered Top Header for Mobile layout.
class MobileHeader extends StatelessWidget {
  const MobileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const RhythmEqualizerIcon(size: 38),
        const SizedBox(height: 10),
        Text(
          'Rhythm',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Feel the Music',
          style: GoogleFonts.outfit(
            color: const Color(0xFFE879F9).withValues(alpha: 0.85),
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}
