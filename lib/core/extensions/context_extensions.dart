import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

extension ContextExtensions on BuildContext {
  /// Quick access to localizations: `context.l10n.appName`
  AppLocalizations get l10n => AppLocalizations.of(this)!;

  /// Quick access to theme: `context.theme`
  ThemeData get theme => Theme.of(this);

  /// Quick access to color scheme: `context.colorScheme`
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Quick access to text theme: `context.textTheme`
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Quick access to media query: `context.mediaQuery`
  MediaQueryData get mediaQuery => MediaQuery.of(this);

  /// Screen width
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Screen height
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Is RTL direction
  bool get isRtl => Directionality.of(this) == TextDirection.rtl;
}
