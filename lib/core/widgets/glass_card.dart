import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:rhythm_flutter/core/theme/glass_decoration.dart';
import 'package:rhythm_flutter/core/theme/spacing.dart';

/// A frosted-glass card with customizable blur, opacity, and border radius.
///
/// Use this instead of raw `Container` + color throughout the app.
/// ```dart
/// GlassCard(
///   child: Text('Hello'),
/// )
/// ```
class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = AppSpacing.radiusMd,
    this.blur = 12,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: GlassDecoration.blur(sigma: blur),
          child: Container(
            padding: padding ?? const EdgeInsets.all(AppSpacing.md),
            decoration: GlassDecoration.card(
              context,
              borderRadius: borderRadius,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
