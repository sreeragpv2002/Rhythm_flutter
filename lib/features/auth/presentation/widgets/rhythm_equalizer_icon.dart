import 'package:flutter/material.dart';

/// The signature Rhythm 5-bar equalizer logo with pink-to-purple gradient and glow.
class RhythmEqualizerIcon extends StatelessWidget {
  final double size;
  final bool animate;

  const RhythmEqualizerIcon({
    super.key,
    this.size = 44,
    this.animate = false,
  });

  @override
  Widget build(BuildContext context) {
    // 5 bars relative heights: [0.42, 0.76, 1.0, 0.72, 0.38]
    const barRatios = [0.42, 0.76, 1.0, 0.72, 0.38];
    final barWidth = size * 0.11;
    final spacing = size * 0.08;

    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE040FB).withValues(alpha: 0.35),
            blurRadius: size * 0.5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: SizedBox(
        height: size,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (int i = 0; i < 5; i++) ...[
              if (i > 0) SizedBox(width: spacing),
              Container(
                width: barWidth,
                height: size * barRatios[i],
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(barWidth / 2),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFFF52A2), // Bright hot pink / magenta
                      Color(0xFFE040FB), // Neon purple
                      Color(0xFF8B5CF6), // Violet
                    ],
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x66FF52A2),
                      blurRadius: 4,
                      offset: Offset(0, -1),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
