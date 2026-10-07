import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Pure native Flutter floating ambient particles background.
/// Highly optimized, GPU accelerated, zero external package dependencies.
class AmbientParticlesBackground extends StatefulWidget {
  final double width;
  final double height;
  final bool isDesktop;

  const AmbientParticlesBackground({
    super.key,
    required this.width,
    required this.height,
    this.isDesktop = true,
  });

  @override
  State<AmbientParticlesBackground> createState() =>
      _AmbientParticlesBackgroundState();
}

class _AmbientParticlesBackgroundState extends State<AmbientParticlesBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final math.Random _random = math.Random(42);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _initParticles();
  }

  @override
  void didUpdateWidget(covariant AmbientParticlesBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isDesktop != widget.isDesktop ||
        (oldWidget.width - widget.width).abs() > 100 ||
        (oldWidget.height - widget.height).abs() > 100) {
      _initParticles();
    }
  }

  void _initParticles() {
    _particles.clear();
    final count = widget.isDesktop ? 55 : 30;
    const colors = [
      Color(0xFFE040FB), // Neon Purple
      Color(0xFFFF52A2), // Vivid Pink
      Color(0xFF8B5CF6), // Violet
      Color(0xFF38BDF8), // Neon Cyan
      Color(0xFFFFFFFF), // White star
    ];

    for (int i = 0; i < count; i++) {
      _particles.add(
        _Particle(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          radius: 1.2 + _random.nextDouble() * 2.8,
          speedX: (_random.nextDouble() - 0.5) * 0.04,
          speedY: -0.02 - _random.nextDouble() * 0.05,
          color: colors[_random.nextInt(colors.length)],
          opacity: 0.25 + _random.nextDouble() * 0.65,
          pulseSpeed: 1.0 + _random.nextDouble() * 2.5,
          phase: _random.nextDouble() * math.pi * 2,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.width <= 0 || widget.height <= 0) return const SizedBox.shrink();

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            size: Size(widget.width, widget.height),
            painter: _ParticlesPainter(
              particles: _particles,
              progress: _controller.value,
            ),
          );
        },
      ),
    );
  }
}

class _Particle {
  double x;
  double y;
  final double radius;
  final double speedX;
  final double speedY;
  final Color color;
  final double opacity;
  final double pulseSpeed;
  final double phase;

  _Particle({
    required this.x,
    required this.y,
    required this.radius,
    required this.speedX,
    required this.speedY,
    required this.color,
    required this.opacity,
    required this.pulseSpeed,
    required this.phase,
  });
}

class _ParticlesPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ParticlesPainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    for (final p in particles) {
      // Smooth continuous wrapping movement
      final currentX = ((p.x + p.speedX * progress * 10) % 1.0) * w;
      final currentY = ((p.y + p.speedY * progress * 10) % 1.0) * h;

      // Pulsing alpha
      final pulse = (math.sin(progress * math.pi * 2 * p.pulseSpeed + p.phase) + 1) / 2;
      final currentAlpha = (p.opacity * (0.5 + 0.5 * pulse)).clamp(0.0, 1.0);

      // Glow halo
      final glowPaint = Paint()
        ..color = p.color.withValues(alpha: currentAlpha * 0.45)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, p.radius * 2.5);
      canvas.drawCircle(Offset(currentX, currentY), p.radius * 1.8, glowPaint);

      // Core particle dot
      final corePaint = Paint()
        ..color = p.color.withValues(alpha: currentAlpha)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(currentX, currentY), p.radius, corePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter oldDelegate) => true;
}
