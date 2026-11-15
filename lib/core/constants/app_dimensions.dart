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
  // Audit 2026-11-15 DS-7: re-specced from 20 to 16 — 16 is the
  // de-facto horizontal screen padding (71 ad-hoc sites) and the
  // rulebook §4.4 spacing scale; the token now matches the app
  // instead of aspiring to a value nothing used. Do NOT migrate the
  // 71 ad-hoc 16s to the token in this pass — the number is one now.
  static const double paddingHorizontal = 16.0;
  static const double paddingVertical = 16.0;
  static const double spaceBetweenCards = 14.0;

  // Minimum touch target
  static const double minTouchTarget = 48.0;
}
