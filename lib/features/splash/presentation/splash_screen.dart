import 'dart:io' as io show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rhythm_flutter/core/constants/app_constants.dart';
import 'package:rhythm_flutter/core/extensions/context_extensions.dart';
import 'package:rhythm_flutter/core/widgets/gradient_background.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _handleStartup();
  }

  Future<void> _handleStartup() async {
    debugPrint('SplashScreen: _handleStartup started');
    
    // 1. Android 13+ Permission handling for Notifications (required for AudioService)
    if (!kIsWeb && io.Platform.isAndroid) {
      try {
        debugPrint('SplashScreen: Checking notification permissions');
        final status = await Permission.notification.status.timeout(
          const Duration(seconds: 2),
          onTimeout: () => PermissionStatus.denied,
        );
        if (status.isDenied) {
          debugPrint('SplashScreen: Requesting notification permissions');
          await Permission.notification.request().timeout(
            const Duration(seconds: 5),
            onTimeout: () => PermissionStatus.denied,
          );
        }
      } catch (e) {
        debugPrint('SplashScreen: Permission handling error: $e');
      }
    }

    // 2. Wait for splash duration
    debugPrint('SplashScreen: Waiting for splash duration');
    await Future.delayed(AppConstants.splashDuration);

    if (mounted) {
      debugPrint('SplashScreen: Navigating to /login');
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        useSplashGradient: true,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeInDown(
                duration: const Duration(milliseconds: 800),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.music_note_rounded,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FadeInUp(
                duration: const Duration(milliseconds: 800),
                delay: const Duration(milliseconds: 200),
                child: Text(
                  context.l10n.appName,
                  style: context.textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FadeInUp(
                duration: const Duration(milliseconds: 800),
                delay: const Duration(milliseconds: 400),
                child: Text(
                  context.l10n.splashSubtitle,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
