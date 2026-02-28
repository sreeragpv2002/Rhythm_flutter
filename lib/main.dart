import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:media_kit/media_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rhythm_flutter/app.dart';
import 'package:rhythm_flutter/core/services/audio_handler.dart';
import 'package:rhythm_flutter/core/services/storage_service.dart';
import 'package:rhythm_flutter/core/config/app_config.dart';
import 'package:rhythm_flutter/features/player/providers/audio_provider.dart';

void main() async {
  debugPrint('Main: Starting application');
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Initialize MediaKit for desktop support
  MediaKit.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize SharedPreferences and StorageService
  final prefs = await SharedPreferences.getInstance();
  final storageService = StorageService(prefs);

  final apiBaseUrl = '${AppConfig.baseUrl}/en/api/v1';

  RhythmAudioHandler? audioHandler;

  try {
    debugPrint('Main: Initializing AudioService');

    audioHandler = await AudioService.init(
      builder: () => RhythmAudioHandler(apiBaseUrl, storageService),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.rhythm.audio',
        androidNotificationChannelName: 'Rhythm Music',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
      ),
    ).timeout(const Duration(seconds: 15));

    debugPrint('Main: AudioService initialized');
  } catch (e) {
    debugPrint('Main: AudioService initialization failed: $e');

    try {
      audioHandler = RhythmAudioHandler(apiBaseUrl, storageService);
      debugPrint('Main: Fallback RhythmAudioHandler created');
    } catch (fallbackError) {
      debugPrint('Main: Total initialization failure: $fallbackError');
    }
  }

  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storageService),
        if (audioHandler != null)
          audioHandlerProvider.overrideWithValue(audioHandler)
        else
          audioHandlerProvider.overrideWith(
            (ref) => RhythmAudioHandler(apiBaseUrl, storageService),
          ),
      ],
      child: const RhythmApp(),
    ),
  );

  FlutterNativeSplash.remove();
}