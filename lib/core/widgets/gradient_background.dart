import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

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
                ? const LinearGradient(
                    colors: [
                      AppColors.backgroundDark,
                      Color(0xFF121228),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  )
                : const LinearGradient(
                    colors: [
                      AppColors.backgroundLight,
                      Color(0xFFEDE9FE),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
      ),
      child: child,
    );
  }
}
