// Centralised raw sizes in logical pixels.
//
// Feature code reads `AppSize.s30` instead of writing `30` inline. The
// values are NOT scaled per-device — Flutter already lays out in logical
// pixels, and responsive scaling lives in `Breakpoints` + `SpaceTokens` /
// `RadiusTokens` (see `shared_v2/design/tokens/`). This class is the
// catalogue of sizes that DO NOT fit the token rhythm (icon sizes,
// supplier-logo sizes, FAB sizes, cacheWidth bitmap caps, etc.).
//
// Rules:
//   * never inline a raw `width: 30` / `height: 30` / `size: 28` / etc.
//     — look up an `AppSize.sNN` constant or add one here
//   * `cacheWidth` / `cacheHeight` for cached image bitmaps go through
//     `AppSize.cacheCap(...)` which multiplies by DPR and rounds.
//
// New raw sizes belong here only when the design system tokens cannot
// express them (e.g., one-off icon dimensions tied to a specific asset's
// aspect ratio). Prefer `context.space.xxx` / `context.radius.xxx` for
// rhythm-aligned values.

import 'package:flutter/widgets.dart';

class AppSize {
  AppSize._();

  // Spacing primitives that do not fit the design token rhythm.
  static const double s0_5 = 0.5;
  static const double s1 = 1.0;
  static const double s2 = 2.0;
  static const double s2_1 = 2.1;
  static const double s2_5 = 2.5;
  static const double s3 = 3.0;
  static const double s4 = 4.0;
  static const double s5 = 5.0;
  static const double s6 = 6.0;
  static const double s7 = 7.0;
  static const double s8 = 8.0;
  static const double s9 = 9.0;
  static const double s10 = 10.0;
  static const double s11 = 11.0;
  static const double s12 = 12.0;
  static const double s13 = 13.0;

  // Icon + image sizes used by the store screens.
  static const double s14 = 14.0;
  static const double s15 = 15.0;
  static const double s18 = 18.0;
  static const double s20 = 20.0;
  static const double s22 = 22.0;
  static const double s25 = 25.0;
  static const double s28 = 28.0;
  static const double s30 = 30.0;
  static const double s45 = 45.0;
  static const double s50 = 50.0;
  static const double s51 = 51.0;
  static const double s55 = 55.0;
  static const double s60 = 60.0;
  static const double s65 = 65.0;
  static const double s70 = 70.0;
  static const double s75 = 75.0;
  static const double s76 = 76.0;
  static const double s80 = 80.0;
  static const double s90 = 90.0;

  // Layout heights.
  static const double s16 = 16.0;
  static const double s17 = 17.0;
  static const double s19 = 19.0;
  static const double s46 = 46.0;
  static const double s64 = 64.0;
  static const double s23 = 23.0;
  static const double s24 = 24.0;
  static const double s26 = 26.0;
  static const double s27 = 27.0;
  static const double s32 = 32.0;
  static const double s34 = 34.0;
  static const double s35 = 35.0;
  static const double s36 = 36.0;
  static const double s38 = 38.0;
  static const double s40 = 40.0;
  static const double s42 = 42.0;
  static const double s44 = 44.0;
  static const double s48 = 48.0;
  static const double s52 = 52.0;
  static const double s54 = 54.0;
  static const double s56 = 56.0;
  static const double s68 = 68.0;
  static const double s78 = 78.0;
  static const double s84 = 84.0;
  static const double s85 = 85.0;
  static const double s88 = 88.0;
  static const double s96 = 96.0;
  static const double s82_5 = 82.5;
  static const double s100 = 100.0;
  static const double s108 = 108.0;
  static const double s110 = 110.0;
  static const double s120 = 120.0;
  static const double s128 = 128.0;
  static const double s130 = 130.0;
  static const double s140 = 140.0;
  static const double s138 = 138.0;
  static const double s150 = 150.0;
  static const double s158 = 158.0;
  static const double s170 = 170.0;
  static const double s180 = 180.0;
  static const double s200 = 200.0;
  static const double s220 = 220.0;
  static const double s250 = 250.0;
  static const double s280 = 280.0;
  static const double s300 = 300.0;
  static const double s350 = 350.0;
  static const double s439 = 439.0;
  static const double s480 = 480.0;
  static const double s500 = 500.0;
  static const double s520 = 520.0;
  static const double s550 = 550.0;
  static const double s800 = 800.0;
  static const int s1000 = 1000;

  // Additional raw dimensions (seeded from the architecture magic-value sweep).
  static const double s1_2 = 1.2;
  static const double s1_4 = 1.4;
  static const double s1_5 = 1.5;
  static const double s1_9 = 1.9;
  static const double s2_2 = 2.2;
  static const double s7_5 = 7.5;
  static const double s22_5 = 22.5;
  static const double s49 = 49.0;
  static const double s58 = 58.0;
  static const double s72 = 72.0;
  static const double s92 = 92.0;
  static const double s94 = 94.0;
  static const double s104 = 104.0;
  static const double s141 = 141.0;
  static const double s160 = 160.0;
  static const double s210 = 210.0;
  static const double s230 = 230.0;
  static const double s240 = 240.0;
  static const double s260 = 260.0;
  static const double s320 = 320.0;

  // Line-height ratios (TextStyle.height).
  static const double lh0_5 = 0.5;
  static const double lh1_05 = 1.05;
  static const double lh1_1 = 1.1;
  static const double lh1_2 = 1.2;
  static const double lh1_25 = 1.25;
  static const double lh1_35 = 1.35;
  static const double lh1_4 = 1.4;
  static const double lh1_5 = 1.5;

  // Font sizes used outside the typography token rhythm.
  static const double font8 = 8.0;
  static const double font9 = 9.0;
  static const double font10 = 10.0;
  static const double font11 = 11.0;
  static const double font12 = 12.0;
  static const double font13 = 13.0;
  static const double font14 = 14.0;
  static const double font15 = 15.0;
  static const double font16 = 16.0;
  static const double font17 = 17.0;
  static const double font18 = 18.0;
  static const double font20 = 20.0;
  static const double font24 = 24.0;
  static const double font30 = 30.0;
  static const double font40 = 40.0;

  // Border-radius primitives.
  static const double r1 = 1.0;
  static const double r2 = 2.0;
  static const double r3 = 3.0;
  static const double r4 = 4.0;
  static const double r4_8 = 4.8;
  static const double r5 = 5.0;
  static const double r6 = 6.0;
  static const double r8 = 8.0;
  static const double r10 = 10.0;
  static const double r11 = 11.0;
  static const double r12 = 12.0;
  static const double r13 = 13.0;
  static const double r14 = 14.0;
  static const double r15 = 15.0;
  static const double r16 = 16.0;
  static const double r18 = 18.0;
  static const double r23 = 23.0;
  static const double r25 = 25.0;

  // Image bitmap cacheWidth/cacheHeight caps. These are intrinsic to the
  // asset's natural resolution, not the screen — DPR-aware caps go through
  // `cacheCap()`.
  static const int bitmapJameiaCard = 600; // ≈540 px on 1080 phones, DPR 2 ok
  static const int bitmapPrimeBadge = 120; // 60×70 SizedBox, DPR 2 ok

  /// Returns `(logical * dpr).round()` for `Image.asset(cacheWidth: ...)`
  /// when the displayed size is known. Use this so the bitmap cache holds
  /// pixels at display size, not source size.
  static int cacheCap(double logical, double devicePixelRatio) =>
      (logical * devicePixelRatio).round();
}

extension AppSizeMediaQuery on BuildContext {
  /// `30.cacheCapFor(context)` returns DPR-multiplied int — useful for
  /// `Image.asset(cacheWidth: ...)`.
  double get _dpr => MediaQuery.devicePixelRatioOf(this);
  int cacheCapFor(double logical) => AppSize.cacheCap(logical, _dpr);
}
