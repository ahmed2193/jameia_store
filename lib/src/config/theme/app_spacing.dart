/// Jameia spacing & radius tokens — from the APK theme JSON.
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

  // Additional spacing steps (seeded from the architecture magic-value sweep).
  static const double s0_36 = 0.36;
  static const double s0_5 = 0.5;
  static const double s1 = 1.0;
  static const double s1_5 = 1.5;
  static const double s3 = 3.0;
  static const double s5 = 5.0;
  static const double s7 = 7.0;
  static const double s9 = 9.0;
  static const double s13 = 13.0;
  static const double s15 = 15.0;
  static const double s18 = 18.0;
  static const double s22 = 22.0;
  static const double s28 = 28.0;
  static const double s30 = 30.0;
  static const double s34 = 34.0;
  static const double s39 = 39.0;
  static const double s42 = 42.0;
  static const double s44 = 44.0;
  static const double s51 = 51.0;
  static const double s52 = 52.0;
  static const double s56 = 56.0;
  static const double s60 = 60.0;
  static const double s64 = 64.0;
  static const double s120 = 120.0;

  /// Raw reference scale accessor: `AppSpacing.s(n)` == n px (1..48).
  static double s(int n) => n.toDouble();
}

/// Jameia `system.borderRadius` — 8 named radii (light values; dark is +1 in source).
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
  static const double card =
      12; // Jameia cards render at 12dp (bundle.css.json)
  static const double chip = 6; // r6
  static const double sheet = 24; // r2 — bottom sheets
}
