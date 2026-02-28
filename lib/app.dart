import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rhythm_flutter/core/config/app_config.dart';
import 'package:rhythm_flutter/features/player/providers/audio_provider.dart';
import 'package:rhythm_flutter/l10n/app_localizations.dart';
import 'package:rhythm_flutter/core/router/app_router.dart';
import 'package:rhythm_flutter/core/theme/app_theme.dart';
import 'package:rhythm_flutter/shared/providers/locale_provider.dart';
import 'package:rhythm_flutter/shared/providers/theme_provider.dart';
import 'package:flutter/services.dart';
import 'package:rhythm_flutter/features/player/presentation/player_intents.dart';

class RhythmApp extends ConsumerWidget {
  const RhythmApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeProvider);

    // Sync audio metadata and base URL when language changes
    ref.listen(localeProvider, (prev, next) {
      if (prev?.languageCode != next.languageCode) {
        // Use a small delay to ensure providers have updated via their own watchers
        Future.delayed(Duration.zero, () {
          final handler = ref.read(audioHandlerProvider);
          
          // Update base URL for streaming
          final newApiUrl = AppConfig.apiUrl(next.languageCode);
          handler.updateBaseUrl(newApiUrl);
          
          // Update metadata in queue
          handler.updateQueueMetadata(next.languageCode);
        });
      }
    });

    final handler = ref.read(audioHandlerProvider);

    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        const SingleActivator(LogicalKeyboardKey.space): const PlayPauseIntent(),
        const SingleActivator(LogicalKeyboardKey.mediaPlayPause): const PlayPauseIntent(),
        const SingleActivator(LogicalKeyboardKey.mediaTrackNext): const SkipNextIntent(),
        const SingleActivator(LogicalKeyboardKey.mediaTrackPrevious): const SkipPreviousIntent(),
        const SingleActivator(LogicalKeyboardKey.arrowRight, control: true): const SkipNextIntent(),
        const SingleActivator(LogicalKeyboardKey.arrowLeft, control: true): const SkipPreviousIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          PlayPauseIntent: CallbackAction<PlayPauseIntent>(
            onInvoke: (_) {
              if (handler.player.playing) {
                handler.pause();
              } else {
                handler.play();
              }
              return null;
            },
          ),
          SkipNextIntent: CallbackAction<SkipNextIntent>(
            onInvoke: (_) {
              handler.skipToNext();
              return null;
            },
          ),
          SkipPreviousIntent: CallbackAction<SkipPreviousIntent>(
            onInvoke: (_) {
              handler.skipToPrevious();
              return null;
            },
          ),
        },
        child: MaterialApp.router(
          title: 'Rhythm',
          debugShowCheckedModeBanner: false,
          
          // Localization
          locale: locale,
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          
          // Routing
          routerConfig: router,
          
          // Theming
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,

          // Ensure there is always a focus node to capture shortcuts
          builder: (context, child) {
            return Focus(
              autofocus: true,
              debugLabel: 'GlobalFocus',
              child: child!,
            );
          },
        ),
      ),
    );
  }
}
