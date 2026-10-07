import 'dart:ui';
import 'package:flutter/material.dart';

/// Renders the blurred background music player interface on the right side of the desktop login screen.
class PlayerMockupArt extends StatelessWidget {
  final double width;
  final double height;

  const PlayerMockupArt({
    super.key,
    this.width = 460,
    this.height = 540,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
        child: Opacity(
          opacity: 0.55,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.topCenter,
            child: Container(
              width: 380,
              height: 480,
              margin: const EdgeInsets.only(top: 20, right: 20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF140D26).withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.2),
                    blurRadius: 40,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top mock header
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEC4899),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 80,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.more_horiz,
                        color: Colors.white.withValues(alpha: 0.3),
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Mock featured album banner with waveform
                  Container(
                    height: 130,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF831843),
                          Color(0xFF4C1D95),
                          Color(0xFF1E1B4B),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(24, (i) {
                          final h = 14.0 + (i % 7) * 10.0;
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2.2),
                            width: 3.2,
                            height: h,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Mock list items
                  _buildMockSongRow('Neon Horizon', 'Synthetics', '3:45'),
                  const SizedBox(height: 10),
                  _buildMockSongRow('Midnight Echoes', 'Vibe Collective', '4:12'),
                  const SizedBox(height: 10),
                  _buildMockSongRow('Electric Pulse', 'Cyber Beats', '2:58'),

                  const Spacer(),

                  // Mini player bar at bottom of mock
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: const Color(0xFFC026D3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.music_note, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 80,
                              height: 9,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Container(
                              width: 50,
                              height: 7,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        const Icon(Icons.play_circle_fill, color: Colors.white70, size: 28),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMockSongRow(String title, String artist, String duration) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.music_note, color: Colors.white38, size: 16),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 90,
              height: 9,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 5),
            Container(
              width: 55,
              height: 7,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
        const Spacer(),
        Container(
          width: 26,
          height: 7,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}
