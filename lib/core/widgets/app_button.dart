import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rhythm_flutter/core/extensions/context_extensions.dart';
import 'package:rhythm_flutter/core/theme/spacing.dart';

/// Primary action button with gradient fill, loading state, and outlined variant.
///
/// Uses 8pt spacing grid for all dimensions.
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;
  final double? width;
  final double height;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.width,
    this.height = AppSpacing.buttonHeight,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    final child = isLoading
        ? const SizedBox(
            height: AppSpacing.iconMd,
            width: AppSpacing.iconMd,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Colors.white,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(
                text,
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isOutlined ? colorScheme.primary : Colors.white,
                ),
              ),
            ],
          );

    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: !isOutlined && onPressed != null
          ? BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            )
          : null,
      child: isOutlined
          ? OutlinedButton(
              onPressed: isLoading ? null : () {
                HapticFeedback.lightImpact();
                onPressed?.call();
              },
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                side: BorderSide(color: colorScheme.primary, width: 2),
              ),
              child: child,
            )
          : ElevatedButton(
              onPressed: isLoading ? null : () {
                HapticFeedback.lightImpact();
                onPressed?.call();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
              child: child,
            ),
    );
  }
}
