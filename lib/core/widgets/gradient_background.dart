import 'package:flutter/material.dart';
import 'package:rhythm_flutter/core/theme/app_colors.dart';

/// Full-screen gradient background container.
///
/// Adapts between light and dark palettes automatically.
/// Use [useSplashGradient] for the splash/onboarding screens.
class GradientBackground extends StatelessWidget {
  final Widget child;
  final bool useSplashGradient;

  const GradientBackground({
    super.key,
    required this.child,
    this.useSplashGradient = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: useSplashGradient
            ? AppColors.splashGradient
            : isDark
                ? AppColors.backgroundGradientDark
                : AppColors.backgroundGradientLight,
      ),
      child: child,
    );
  }
}
