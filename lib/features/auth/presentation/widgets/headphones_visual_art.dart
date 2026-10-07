import 'package:flutter/material.dart';
import 'package:rhythm_flutter/features/auth/presentation/widgets/rhythm_equalizer_icon.dart';

/// Renders the atmospheric glowing headphones on dark reflective rock surface (Desktop Left Artwork).
class HeadphonesVisualArt extends StatelessWidget {
  final double width;
  final double height;

  const HeadphonesVisualArt({
    super.key,
    this.width = 460,
    this.height = 540,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. Ambient Ground / Rock Glow
          Positioned(
            left: 20,
            bottom: 30,
            width: width * 0.85,
            height: height * 0.35,
            child: CustomPaint(
              painter: _ReflectiveGroundPainter(),
            ),
          ),

          // 2. Headphone Body & Headband Arc
          Positioned.fill(
            child: CustomPaint(
              painter: _HeadphoneStructurePainter(),
            ),
          ),

          // 3. Glowing Ear Cup with Neon Ring and Equalizer Logo
          Positioned(
            left: width * 0.14,
            top: height * 0.46,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [
                    Color(0xFF1B0F33),
                    Color(0xFF0F0820),
                    Color(0xFF070410),
                  ],
                ),
                border: Border.all(
                  color: const Color(0xFFE040FB),
                  width: 3.5,
                ),
                boxShadow: [
                  // Intense neon purple glow
                  BoxShadow(
                    color: const Color(0xFFC026D3).withValues(alpha: 0.8),
                    blurRadius: 28,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.5),
                    blurRadius: 50,
                    spreadRadius: 8,
                  ),
                  const BoxShadow(
                    color: Color(0xFF00E5FF),
                    blurRadius: 10,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: const Center(
                child: RhythmEqualizerIcon(
                  size: 52,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeadphoneStructurePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Headband Arc Path (curving gracefully from top-left over to the ear-cup)
    final headbandPath = Path();
    headbandPath.moveTo(w * 0.08, h * 0.55);
    headbandPath.cubicTo(
      w * 0.05, h * 0.15,
      w * 0.40, h * 0.08,
      w * 0.52, h * 0.38,
    );

    // Headband outer glow
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 26
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16)
      ..shader = const LinearGradient(
        colors: [
          Color(0x60A855F7),
          Color(0x30EC4899),
          Color(0x10000000),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(headbandPath, glowPaint);

    // Headband solid structure (sleek dark metallic cushion)
    final bandPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF3B2D54),
          Color(0xFF1E1630),
          Color(0xFF120C1F),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(headbandPath, bandPaint);

    // Metallic rim highlight along the band
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFE879F9),
          Color(0xFFA855F7),
          Color(0x00A855F7),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(headbandPath, rimPaint);

    // Ear-cup outer cushion/housing silhouette
    final cupHousingPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = const RadialGradient(
        center: Alignment(-0.2, -0.2),
        colors: [
          Color(0xFF2E1C4E),
          Color(0xFF160E29),
          Color(0xFF090514),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(w * 0.29, h * 0.59),
        radius: 95,
      ));
    canvas.drawCircle(Offset(w * 0.29, h * 0.59), 92, cupHousingPaint);

    // Subtle dark outer bevel ring
    final bevelPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = const Color(0xFF332050);
    canvas.drawCircle(Offset(w * 0.29, h * 0.59), 92, bevelPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ReflectiveGroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Rocky reflective surface silhouette
    final groundPath = Path();
    groundPath.moveTo(0, h * 0.6);
    groundPath.lineTo(w * 0.2, h * 0.45);
    groundPath.lineTo(w * 0.45, h * 0.55);
    groundPath.lineTo(w * 0.7, h * 0.40);
    groundPath.lineTo(w, h * 0.7);
    groundPath.lineTo(w, h);
    groundPath.lineTo(0, h);
    groundPath.close();

    // Dark rock fill with purple reflection
    final rockPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF6B21A8).withValues(alpha: 0.35),
          const Color(0xFF1E1035).withValues(alpha: 0.8),
          const Color(0xFF0D0618),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(groundPath, rockPaint);

    // Specular wet neon reflection highlights
    final highlightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..shader = LinearGradient(
        colors: [
          const Color(0xFFD946EF).withValues(alpha: 0.7),
          const Color(0xFF8B5CF6).withValues(alpha: 0.4),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(groundPath, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
