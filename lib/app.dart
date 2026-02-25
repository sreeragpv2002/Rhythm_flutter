import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rhythm_flutter/features/player/providers/audio_provider.dart';
import 'package:rhythm_flutter/l10n/app_localizations.dart';
import 'package:rhythm_flutter/core/router/app_router.dart';
import 'package:rhythm_flutter/core/theme/app_theme.dart';
import 'package:rhythm_flutter/shared/providers/locale_provider.dart';
import 'package:rhythm_flutter/shared/providers/theme_provider.dart';

class RhythmApp extends ConsumerWidget {
  const RhythmApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeProvider);

    // Sync audio metadata when language changes
    ref.listen(localeProvider, (prev, next) {
      if (prev?.languageCode != next.languageCode) {
        // Use a small delay to ensure providers have updated via their own watchers
        Future.delayed(Duration.zero, () {
          final handler = ref.read(audioHandlerProvider);
          handler.updateQueueMetadata(next.languageCode);
        });
      }
    });

    return MaterialApp.router(
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
    );
  }
}
