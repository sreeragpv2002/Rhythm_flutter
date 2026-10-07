import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rhythm_flutter/features/auth/presentation/widgets/ambient_particles_background.dart';
import 'package:rhythm_flutter/features/auth/presentation/widgets/desktop_ambient_widgets.dart';
import 'package:rhythm_flutter/features/auth/presentation/widgets/headphones_visual_art.dart';
import 'package:rhythm_flutter/features/auth/presentation/widgets/login_card.dart';
import 'package:rhythm_flutter/features/auth/presentation/widgets/neon_soundwaves_painter.dart';
import 'package:rhythm_flutter/features/auth/presentation/widgets/player_mockup_art.dart';
import 'package:rhythm_flutter/features/auth/presentation/widgets/rhythm_brand_header.dart';
import 'package:rhythm_flutter/features/auth/providers/auth_provider.dart';

/// Redesigned continue / welcome screen supporting both Desktop and Mobile experiences
/// with high-end glassmorphism, animated floating particles, glowing neon sound waves,
/// and seamless Google & Guest authentication.
class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF090614),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 900;
          if (isDesktop) {
            return _DesktopLoginLayout(
              isLoading: authState.isLoading,
              errorMessage: authState.error,
              onGoogleLogin: () =>
                  ref.read(authProvider.notifier).loginWithGoogle(),
              onGuestLogin: () =>
                  ref.read(authProvider.notifier).loginAnonymously(),
            );
          } else {
            return _MobileLoginLayout(
              isLoading: authState.isLoading,
              errorMessage: authState.error,
              onGoogleLogin: () =>
                  ref.read(authProvider.notifier).loginWithGoogle(),
              onGuestLogin: () =>
                  ref.read(authProvider.notifier).loginAnonymously(),
            );
          }
        },
      ),
    );
  }
}

/// Desktop presentation layout
class _DesktopLoginLayout extends StatelessWidget {
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onGoogleLogin;
  final VoidCallback onGuestLogin;

  const _DesktopLoginLayout({
    required this.isLoading,
    required this.errorMessage,
    required this.onGoogleLogin,
    required this.onGuestLogin,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Stack(
      children: [
        // 1. Cosmic Deep Gradient Background
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0D081F),
                  Color(0xFF07050F),
                  Color(0xFF090614),
                ],
              ),
            ),
          ),
        ),

        // 2. Floating Ambient Particles
        Positioned.fill(
          child: AmbientParticlesBackground(
            width: size.width,
            height: size.height,
            isDesktop: true,
          ),
        ),

        // 3. Custom Painted Soundwaves & Ambient Lights
        Positioned.fill(
          child: CustomPaint(
            painter: NeonSoundwavesPainter(isDesktop: true),
          ),
        ),

        // 4. Left Headphone Art (positioned behind the card on the left side)
        Positioned(
          left: (size.width * 0.5 - 640).clamp(-120.0, 60.0),
          top: (size.height * 0.5 - 280).clamp(40.0, 180.0),
          child: IgnorePointer(
            child: HeadphonesVisualArt(
              width: (size.width * 0.38).clamp(360.0, 520.0),
              height: (size.height * 0.65).clamp(440.0, 600.0),
            ),
          ),
        ),

        // 5. Right Mockup Player Art (positioned behind the card on the right side)
        Positioned(
          right: (size.width * 0.5 - 620).clamp(-120.0, 50.0),
          top: (size.height * 0.5 - 260).clamp(50.0, 170.0),
          child: IgnorePointer(
            child: PlayerMockupArt(
              width: (size.width * 0.36).clamp(340.0, 480.0),
              height: (size.height * 0.62).clamp(420.0, 560.0),
            ),
          ),
        ),

        // 6. Scrollable Foreground Elements (Header, Login Card, Bottom Bar)
        Positioned.fill(
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: size.height - MediaQuery.paddingOf(context).vertical,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      // Top Desktop Navigation Header
                      const DesktopHeader(),

                      // Centered Frosted Glass Login Card
                      Expanded(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 20,
                            ),
                            child: LoginCard(
                              maxWidth: 420,
                              isLoading: isLoading,
                              errorMessage: errorMessage,
                              onGoogleLogin: onGoogleLogin,
                              onGuestLogin: onGuestLogin,
                            ),
                          ),
                        ),
                      ),

                      // Bottom Bar: Feature Badges on Left, "Music Lives Here" on Right
                      const DesktopBottomBar(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Mobile presentation layout
class _MobileLoginLayout extends StatelessWidget {
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onGoogleLogin;
  final VoidCallback onGuestLogin;

  const _MobileLoginLayout({
    required this.isLoading,
    required this.errorMessage,
    required this.onGoogleLogin,
    required this.onGuestLogin,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Stack(
      children: [
        // 1. Cosmic Deep Gradient Background
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0F0824),
                  Color(0xFF080512),
                  Color(0xFF0C0719),
                ],
              ),
            ),
          ),
        ),

        // 2. Floating Ambient Particles
        Positioned.fill(
          child: AmbientParticlesBackground(
            width: size.width,
            height: size.height,
            isDesktop: false,
          ),
        ),

        // 3. Custom Painted Soundwaves & Glowing Notes
        Positioned.fill(
          child: CustomPaint(
            painter: NeonSoundwavesPainter(isDesktop: false),
          ),
        ),

        // 4. Scrollable Mobile Container
        Positioned.fill(
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: size.height - MediaQuery.paddingOf(context).vertical,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: Column(
                      children: [
                        const SizedBox(height: 24),

                        // Top Mobile Brand Header
                        const MobileHeader(),

                        const SizedBox(height: 18),

                        // Centered Frosted Glass Login Card
                        Expanded(
                          child: Center(
                            child: LoginCard(
                              maxWidth: 390,
                              isLoading: isLoading,
                              errorMessage: errorMessage,
                              onGoogleLogin: onGoogleLogin,
                              onGuestLogin: onGuestLogin,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Bottom Mobile Feature Tags
                        Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildFooterItem('Listen'),
                              _buildBulletDot(),
                              _buildFooterItem('Organize'),
                              _buildBulletDot(),
                              _buildFooterItem('Enjoy'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooterItem(String label) {
    return Text(
      label,
      style: GoogleFonts.outfit(
        color: Colors.white.withValues(alpha: 0.60),
        fontSize: 13,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.6,
      ),
    );
  }

  Widget _buildBulletDot() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        width: 3.5,
        height: 3.5,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.35),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
