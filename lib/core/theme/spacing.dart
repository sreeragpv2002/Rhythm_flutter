/// 8-point spacing grid — the single source of truth for all
/// padding, margins, gaps, and border-radii in the app.
class AppSpacing {
  AppSpacing._();

  // ── Spacing scale (8pt increments) ──
  static const double xs = 4;    // 0.5 unit
  static const double sm = 8;    // 1 unit
  static const double md = 16;   // 2 units
  static const double lg = 24;   // 3 units
  static const double xl = 32;   // 4 units
  static const double xxl = 48;  // 6 units
  static const double xxxl = 64; // 8 units

  // ── Border radii ──
  static const double radiusSm = 8;
  static const double radiusMd = 16;
  static const double radiusLg = 24;
  static const double radiusXl = 32;

  // ── Icon sizes ──
  static const double iconSm = 16;
  static const double iconMd = 24;
  static const double iconLg = 32;
  static const double iconXl = 48;

  // ── Component heights (on the 8pt grid) ──
  static const double buttonHeight = 56;
  static const double inputHeight = 56;
  static const double miniPlayerHeight = 64;
  static const double bottomNavHeight = 64;
  static const double thumbnailSm = 48;
  static const double thumbnailMd = 56;
  static const double thumbnailLg = 160;
}
