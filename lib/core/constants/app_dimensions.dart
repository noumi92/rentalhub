class AppDimensions {
  // Heights & Radius
  static const double headerHeight = 230.0;
  // Compact header (title-only screens, no hero card): rulebook §4.3
  // defines one hero height (230); compact is the single second height.
  static const double headerCompactHeight = 100.0;
  static const double headerBottomRadius = 28.0;
  static const double cardOverlapMargin = -28.0;
  // Rulebook §4.3: content cards overlap the header by -28.
  static const double headerOverlapOffset = -28.0;
  static const double cardRadius = 20.0;
  static const double buttonRadius = 16.0;
  static const double buttonHeight = 54.0;

  // Paddings
  static const double paddingHorizontal = 20.0;
  static const double paddingVertical = 16.0;
  static const double spaceBetweenCards = 14.0;

  // Minimum touch target
  static const double minTouchTarget = 48.0;
}
