import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:rhythm_flutter/features/auth/presentation/widgets/auth_pill_button.dart';
import 'package:rhythm_flutter/features/auth/presentation/widgets/rhythm_equalizer_icon.dart';

/// The central frosted glassmorphic card for Rhythm authentication.
class LoginCard extends StatelessWidget {
  final VoidCallback onGoogleLogin;
  final VoidCallback onGuestLogin;
  final bool isLoading;
  final String? errorMessage;
  final double maxWidth;

  const LoginCard({
    super.key,
    required this.onGoogleLogin,
    required this.onGuestLogin,
    this.isLoading = false,
    this.errorMessage,
    this.maxWidth = 420,
  });

  @override
  Widget build(BuildContext context) {
    return FadeInUp(
      duration: const Duration(milliseconds: 650),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              // Subtle ambient purple glow behind card
              BoxShadow(
                color: const Color(0xFF9333EA).withValues(alpha: 0.22),
                blurRadius: 48,
                spreadRadius: -2,
                offset: const Offset(0, 8),
              ),
              // Deep elevation shadow
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.55),
                blurRadius: 36,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 38),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF1F143D).withValues(alpha: 0.42),
                      const Color(0xFF0D081F).withValues(alpha: 0.70),
                      const Color(0xFF160F2E).withValues(alpha: 0.50),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.13),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 1. Equalizer Logo
                    const RhythmEqualizerIcon(size: 46),
                    const SizedBox(height: 22),

                    // 2. "Welcome to" Title
                    Text(
                      'Welcome to',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                        height: 1.15,
                      ),
                    ),

                    // 3. "Rhythm" Brand Title with hot pink to purple gradient
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          Color(0xFFFF52A2), // Vivid Pink
                          Color(0xFFE040FB), // Magenta
                          Color(0xFFA855F7), // Purple
                        ],
                      ).createShader(bounds),
                      child: Text(
                        'Rhythm',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          height: 1.15,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 4. Subtitle
                    Text(
                      'A simple and beautiful music player\nfor your everyday vibe.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        color: Colors.white.withValues(alpha: 0.68),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w400,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 5. Button 1: Continue with Google
                    GooglePillButton(
                      isLoading: isLoading,
                      onPressed: onGoogleLogin,
                    ),
                    const SizedBox(height: 14),

                    // 6. Button 2: Continue as Guest
                    GuestPillButton(
                      isLoading: isLoading,
                      onPressed: onGuestLogin,
                    ),

                    // 7. Error message banner if any
                    if (errorMessage != null && errorMessage!.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: Color(0xFFFCA5A5),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                errorMessage!,
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFFFCA5A5),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
