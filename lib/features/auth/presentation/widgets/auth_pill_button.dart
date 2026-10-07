import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rhythm_flutter/features/auth/presentation/widgets/social_auth_buttons.dart';

/// The white pill button for Google sign-in matching the mockup.
class GooglePillButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const GooglePillButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  State<GooglePillButton> createState() => _GooglePillButtonState();
}

class _GooglePillButtonState extends State<GooglePillButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.isLoading ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: AnimatedScale(
        scale: _isHovered ? 1.015 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE040FB).withValues(alpha: _isHovered ? 0.35 : 0.20),
                blurRadius: _isHovered ? 20 : 14,
                spreadRadius: _isHovered ? 2 : 0,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.25),
                blurRadius: 8,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: widget.isLoading
                  ? null
                  : () {
                      HapticFeedback.lightImpact();
                      widget.onPressed?.call();
                    },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: widget.isLoading
                    ? const Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0F172A)),
                          ),
                        ),
                      )
                    : Row(
                        children: [
                          const GoogleIcon(size: 22),
                          Expanded(
                            child: Center(
                              child: Text(
                                'Continue with Google',
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF0F172A),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: Color(0xFF0F172A),
                            size: 19,
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The frosted dark pill button for Guest sign-in matching the mockup.
class GuestPillButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const GuestPillButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  State<GuestPillButton> createState() => _GuestPillButtonState();
}

class _GuestPillButtonState extends State<GuestPillButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.isLoading ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: AnimatedScale(
        scale: _isHovered ? 1.015 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: _isHovered ? 0.12 : 0.07),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withValues(alpha: _isHovered ? 0.25 : 0.14),
              width: 1.2,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: const Color(0xFF9333EA).withValues(alpha: 0.2),
                      blurRadius: 16,
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: widget.isLoading
                  ? null
                  : () {
                      HapticFeedback.lightImpact();
                      widget.onPressed?.call();
                    },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: widget.isLoading
                    ? const Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      )
                    : Row(
                        children: [
                          Icon(
                            Icons.person_outline_rounded,
                            color: Colors.white.withValues(alpha: 0.9),
                            size: 22,
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                'Continue as Guest',
                                style: GoogleFonts.outfit(
                                  color: Colors.white.withValues(alpha: 0.92),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white.withValues(alpha: 0.75),
                            size: 19,
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
