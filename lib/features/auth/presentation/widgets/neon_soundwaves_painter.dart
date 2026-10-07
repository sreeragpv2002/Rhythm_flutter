import 'package:flutter/material.dart';

/// Custom painter for glowing neon sound wave ribbons and floating musical notes.
class NeonSoundwavesPainter extends CustomPainter {
  final double animationValue;
  final bool isDesktop;

  NeonSoundwavesPainter({
    this.animationValue = 0.0,
    this.isDesktop = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Ambient Glow Orbs in the background
    _drawGlowOrbs(canvas, size);

    // 2. Sound Wave Ribbons
    _drawSoundWaves(canvas, size);

    // 3. Floating Musical Notes
    _drawMusicNotes(canvas, size);
  }

  void _drawGlowOrbs(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Top-left purple/pink aura
    final tlPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFC026D3).withValues(alpha: 0.18),
          const Color(0xFF7E22CE).withValues(alpha: 0.10),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(w * (isDesktop ? 0.25 : 0.3), h * 0.25),
        radius: isDesktop ? 340 : 220,
      ));
    canvas.drawCircle(
      Offset(w * (isDesktop ? 0.25 : 0.3), h * 0.25),
      isDesktop ? 340 : 220,
      tlPaint,
    );

    // Bottom-center / right violet aura
    final brPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF9333EA).withValues(alpha: 0.16),
          const Color(0xFF3B82F6).withValues(alpha: 0.06),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(w * (isDesktop ? 0.7 : 0.6), h * (isDesktop ? 0.65 : 0.85)),
        radius: isDesktop ? 360 : 260,
      ));
    canvas.drawCircle(
      Offset(w * (isDesktop ? 0.7 : 0.6), h * (isDesktop ? 0.65 : 0.85)),
      isDesktop ? 360 : 260,
      brPaint,
    );
  }

  void _drawSoundWaves(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    if (isDesktop) {
      // Desktop wave cluster (sweeping behind central card from left to right)
      _drawWaveRibbon(
        canvas: canvas,
        start: Offset(-20, h * 0.38),
        c1: Offset(w * 0.18, h * 0.15),
        c2: Offset(w * 0.32, h * 0.52),
        end: Offset(w * 0.55, h * 0.30),
        c3: Offset(w * 0.72, h * 0.18),
        end2: Offset(w + 30, h * 0.42),
        primaryColor: const Color(0xFFD946EF),
        secondaryColor: const Color(0xFF818CF8),
        strokeWidth: 2.2,
      );

      _drawWaveRibbon(
        canvas: canvas,
        start: Offset(-30, h * 0.44),
        c1: Offset(w * 0.15, h * 0.22),
        c2: Offset(w * 0.30, h * 0.58),
        end: Offset(w * 0.52, h * 0.36),
        c3: Offset(w * 0.70, h * 0.24),
        end2: Offset(w + 40, h * 0.48),
        primaryColor: const Color(0xFFC084FC),
        secondaryColor: const Color(0xFF38BDF8),
        strokeWidth: 1.4,
        opacity: 0.65,
      );

      _drawWaveRibbon(
        canvas: canvas,
        start: Offset(-20, h * 0.48),
        c1: Offset(w * 0.12, h * 0.30),
        c2: Offset(w * 0.28, h * 0.64),
        end: Offset(w * 0.50, h * 0.42),
        c3: Offset(w * 0.68, h * 0.30),
        end2: Offset(w + 50, h * 0.54),
        primaryColor: const Color(0xFFF472B6),
        secondaryColor: const Color(0xFFA855F7),
        strokeWidth: 1.0,
        opacity: 0.45,
      );
    } else {
      // Mobile upper wave ribbons
      _drawMobileWave(
        canvas: canvas,
        startY: h * 0.18,
        midY: h * 0.10,
        endY: h * 0.24,
        w: w,
        color1: const Color(0xFFD946EF),
        color2: const Color(0xFF818CF8),
        strokeWidth: 2.0,
      );
      _drawMobileWave(
        canvas: canvas,
        startY: h * 0.21,
        midY: h * 0.13,
        endY: h * 0.27,
        w: w,
        color1: const Color(0xFFC084FC),
        color2: const Color(0xFF38BDF8),
        strokeWidth: 1.2,
        opacity: 0.6,
      );

      // Mobile bottom wave ribbons
      _drawMobileBottomWave(
        canvas: canvas,
        startY: h * 0.82,
        midY: h * 0.76,
        endY: h * 0.86,
        w: w,
        color1: const Color(0xFF818CF8),
        color2: const Color(0xFFF43F5E),
        strokeWidth: 1.8,
      );
      _drawMobileBottomWave(
        canvas: canvas,
        startY: h * 0.85,
        midY: h * 0.79,
        endY: h * 0.89,
        w: w,
        color1: const Color(0xFFA855F7),
        color2: const Color(0xFFE879F9),
        strokeWidth: 1.2,
        opacity: 0.6,
      );
    }
  }

  void _drawWaveRibbon({
    required Canvas canvas,
    required Offset start,
    required Offset c1,
    required Offset c2,
    required Offset end,
    required Offset c3,
    required Offset end2,
    required Color primaryColor,
    required Color secondaryColor,
    required double strokeWidth,
    double opacity = 0.85,
  }) {
    final path = Path()..moveTo(start.dx, start.dy);
    path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, end.dx, end.dy);
    path.cubicTo(
      (end.dx + c3.dx) / 2,
      (end.dy + c3.dy) / 2,
      c3.dx,
      c3.dy,
      end2.dx,
      end2.dy,
    );

    // Glow stroke (soft blurry wide stroke)
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 4.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
      ..shader = LinearGradient(
        colors: [
          primaryColor.withValues(alpha: opacity * 0.5),
          secondaryColor.withValues(alpha: opacity * 0.3),
        ],
      ).createShader(Rect.fromPoints(start, end2));
    canvas.drawPath(path, glowPaint);

    // Core sharp stroke
    final corePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        colors: [
          primaryColor.withValues(alpha: opacity),
          secondaryColor.withValues(alpha: opacity),
        ],
      ).createShader(Rect.fromPoints(start, end2));
    canvas.drawPath(path, corePaint);
  }

  void _drawMobileWave({
    required Canvas canvas,
    required double startY,
    required double midY,
    required double endY,
    required double w,
    required Color color1,
    required Color color2,
    required double strokeWidth,
    double opacity = 0.85,
  }) {
    final path = Path()..moveTo(-20, startY);
    path.cubicTo(w * 0.3, midY, w * 0.65, startY + 25, w + 20, endY);

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
      ..shader = LinearGradient(
        colors: [
          color1.withValues(alpha: opacity * 0.5),
          color2.withValues(alpha: opacity * 0.3),
        ],
      ).createShader(Rect.fromLTWH(0, midY, w, 60));
    canvas.drawPath(path, glowPaint);

    final corePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        colors: [
          color1.withValues(alpha: opacity),
          color2.withValues(alpha: opacity),
        ],
      ).createShader(Rect.fromLTWH(0, midY, w, 60));
    canvas.drawPath(path, corePaint);
  }

  void _drawMobileBottomWave({
    required Canvas canvas,
    required double startY,
    required double midY,
    required double endY,
    required double w,
    required Color color1,
    required Color color2,
    required double strokeWidth,
    double opacity = 0.85,
  }) {
    final path = Path()..moveTo(-20, startY);
    path.cubicTo(w * 0.35, midY, w * 0.75, endY + 15, w + 20, endY);

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
      ..shader = LinearGradient(
        colors: [
          color1.withValues(alpha: opacity * 0.4),
          color2.withValues(alpha: opacity * 0.2),
        ],
      ).createShader(Rect.fromLTWH(0, midY, w, 60));
    canvas.drawPath(path, glowPaint);

    final corePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        colors: [
          color1.withValues(alpha: opacity),
          color2.withValues(alpha: opacity),
        ],
      ).createShader(Rect.fromLTWH(0, midY, w, 60));
    canvas.drawPath(path, corePaint);
  }

  void _drawMusicNotes(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    if (isDesktop) {
      // Note 1: Left top ♪
      _drawNoteGlyph(
        canvas,
        Offset(w * 0.22, h * 0.21),
        '♪',
        26,
        const Color(0xFFE879F9),
        -0.2,
      );

      // Note 2: Left center-low ♫
      _drawNoteGlyph(
        canvas,
        Offset(w * 0.25, h * 0.30),
        '♫',
        30,
        const Color(0xFFFF52A2),
        0.15,
      );

      // Note 3: Subtle note near top center
      _drawNoteGlyph(
        canvas,
        Offset(w * 0.38, h * 0.12),
        '♪',
        18,
        const Color(0xFFC084FC).withValues(alpha: 0.6),
        0.3,
      );
    } else {
      // Mobile notes:
      // Note 1: Top left ♪
      _drawNoteGlyph(
        canvas,
        Offset(w * 0.16, h * 0.19),
        '♪',
        22,
        const Color(0xFFE879F9).withValues(alpha: 0.8),
        -0.2,
      );

      // Note 2: Top right ♫
      _drawNoteGlyph(
        canvas,
        Offset(w * 0.86, h * 0.24),
        '♫',
        26,
        const Color(0xFFFF52A2).withValues(alpha: 0.85),
        0.15,
      );

      // Note 3: Bottom right ♪
      _drawNoteGlyph(
        canvas,
        Offset(w * 0.88, h * 0.78),
        '♪',
        20,
        const Color(0xFFC084FC).withValues(alpha: 0.7),
        0.1,
      );
    }
  }

  void _drawNoteGlyph(
    Canvas canvas,
    Offset position,
    String glyph,
    double fontSize,
    Color color,
    double angle,
  ) {
    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate(angle);

    // Glowing background text
    final glowPainter = TextPainter(
      text: TextSpan(
        text: glyph,
        style: TextStyle(
          fontSize: fontSize,
          color: color.withValues(alpha: 0.6),
          shadows: [
            Shadow(
              color: color,
              blurRadius: 16,
            ),
            Shadow(
              color: color.withValues(alpha: 0.8),
              blurRadius: 28,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    glowPainter.paint(canvas, Offset(-glowPainter.width / 2, -glowPainter.height / 2));

    // Crisp foreground text
    final textPainter = TextPainter(
      text: TextSpan(
        text: glyph,
        style: TextStyle(
          fontSize: fontSize,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant NeonSoundwavesPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.isDesktop != isDesktop;
  }
}
