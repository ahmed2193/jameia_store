/// KeeTa spacing & radius tokens — from the APK theme JSON.
///
/// `reference.spacing` is a linear 1px scale s1..s48 = 1..48. `system.spacing`
/// names a few semantic values. `system.borderRadius` exposes 8 named radii.
class AppSpacing {
  AppSpacing._();

  // Semantic spacing (system.spacing) — light & dark identical.
  static const double pageMargin = 9; // horizontal.pageMargin (spacing.s9)
  static const double primaryModule = 20; // vertical.primaryModule (s20)
  static const double primaryHeading = 8; // vertical.primaryHeading (s8)
  static const double secondaryModule = 16; // vertical.secondaryModule (s16)

  // Common rhythm steps off the raw 1px scale (sN == N).
  static const double s2 = 2;
  static const double s4 = 4;
  static const double s6 = 6;
  static const double s8 = 8;
  static const double s10 = 10;
  static const double s12 = 12;
  static const double s14 = 14;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;
  static const double s40 = 40;
  static const double s48 = 48;

  /// Raw reference scale accessor: `AppSpacing.s(n)` == n px (1..48).
  static double s(int n) => n.toDouble();
}

/// KeeTa `system.borderRadius` — 8 named radii (light values; dark is +1 in source).
class AppRadius {
  AppRadius._();

  static const double r1 = 32; // borderRadius.r32
  static const double r2 = 24; // r24
  static const double r3 = 16; // r16
  static const double r4 = 13; // r13
  static const double r5 = 10; // r10
  static const double r6 = 6; // r6
  static const double r7 = 2; // r2
  static const double r8 = 1; // r1

  // Friendly aliases.
  static const double pill = 999;
  static const double card = 12; // KeeTa cards render at 12dp (bundle.css.json)
  static const double chip = 6; // r6
  static const double sheet = 24; // r2 — bottom sheets
}
