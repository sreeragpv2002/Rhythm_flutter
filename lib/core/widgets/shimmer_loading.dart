import 'package:flutter/material.dart';
import 'package:rhythm_flutter/core/theme/spacing.dart';

/// Skeleton shimmer loading effect for placeholder content.
///
/// Provides both a generic [ShimmerBox] and composed presets:
/// - [ShimmerLoading.musicCard] — matches MusicCard dimensions
/// - [ShimmerLoading.listTile] — matches MusicListTile dimensions
class ShimmerLoading extends StatelessWidget {
  final Widget child;

  const ShimmerLoading({super.key, required this.child});

  /// Horizontal music card placeholder (matches MusicCard)
  static Widget musicCard() {
    return const SizedBox(
      width: AppSpacing.thumbnailLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(
            width: AppSpacing.thumbnailLg,
            height: 140,
            borderRadius: AppSpacing.radiusMd,
          ),
          SizedBox(height: AppSpacing.sm + 4),
          ShimmerBox(width: 120, height: 14, borderRadius: AppSpacing.radiusSm),
          SizedBox(height: AppSpacing.xs),
          ShimmerBox(width: 80, height: 12, borderRadius: AppSpacing.radiusSm),
        ],
      ),
    );
  }

  /// List tile placeholder (matches MusicListTile)
  static Widget listTile() {
    return const Padding(
      padding: EdgeInsets.symmetric(
        vertical: AppSpacing.sm,
        horizontal: AppSpacing.md,
      ),
      child: Row(
        children: [
          ShimmerBox(
            width: AppSpacing.thumbnailMd,
            height: AppSpacing.thumbnailMd,
            borderRadius: AppSpacing.radiusSm,
          ),
          SizedBox(width: AppSpacing.sm + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: 160, height: 14, borderRadius: AppSpacing.radiusSm),
                SizedBox(height: AppSpacing.xs + 2),
                ShimmerBox(width: 100, height: 12, borderRadius: AppSpacing.radiusSm),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

/// A single animated shimmer rectangle.
class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      Colors.white.withValues(alpha: 0.04),
                      Colors.white.withValues(alpha: 0.1),
                      Colors.white.withValues(alpha: 0.04),
                    ]
                  : [
                      Colors.black.withValues(alpha: 0.04),
                      Colors.black.withValues(alpha: 0.08),
                      Colors.black.withValues(alpha: 0.04),
                    ],
              stops: [
                (_controller.value - 0.3).clamp(0.0, 1.0),
                _controller.value,
                (_controller.value + 0.3).clamp(0.0, 1.0),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        );
      },
    );
  }
}
