class AppConstants {
  AppConstants._();

  static const String appVersion = '1.0.0';
  static const Duration splashDuration = Duration(milliseconds: 2500);
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration pageTransitionDuration = Duration(milliseconds: 250);

  // SharedPreferences keys
  static const String localeKey = 'app_locale';
  static const String themeKey = 'app_theme';
  static const String isLoggedInKey = 'is_logged_in';
  static const String hasProfileKey = 'has_profile';
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
}
