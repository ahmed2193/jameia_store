import 'package:flutter/material.dart';

/// KeeTa design-token color system — extracted verbatim from the APK theme JSON
/// (`assets/Theme/base/base/{light,dark}.json`, v3.5.214).
///
/// 3-tier W3C token model: reference palettes (`_Ramp`s) → semantic system tokens
/// (the static getters on [AppColors]) → component (empty in source).
///
/// Brand color = yellow `#FFE41F` (light) / `#F5DA0F` (dark); foreground = black/white.
/// Raw `Color(0x..)` literals live ONLY in this token layer — never in feature code.
///
/// Light is the primary surface (KeeTa ships light-first). Full dark ramps are kept
/// for parity and surfaced through [KeetaColors] (the [ThemeExtension]).
class AppColors {
  AppColors._();

  // ── Brand (yellow) ─────────────────────────────────────────────────────────
  static const Color primary = Color(0xFFFFE41F); // yellow.c7
  static const Color primaryDark = Color(0xFFF5DA0F); // dark yellow.c7
  static const Color brandForeground = Color(0xFF000000);
  static const Color brandDarkBg = Color(0xFFFFF05B); // yellow.c5
  static const Color brandLightBg = Color(0xFFFFFDE0); // yellow.c1

  // ── Neutral semantic roles (light) ──────────────────────────────────────────
  static const Color primaryText = Color(0xFF000000); // neutral.c16
  static const Color secondaryText = Color(0xFF555555); // neutral.c12
  static const Color tertiaryText = Color(0xFF999999); // neutral.c8
  static const Color disabledText = Color(0xFFC2C2C2); // neutral.c6
  static const Color divider = Color(0xFFEBEBEB); // neutral.c4
  static const Color smallBackground = Color(0xFFF0F1F5); // neutral.c3
  static const Color mediumBackground = Color(0xFFF5F6FA); // neutral.c2
  static const Color white = Color(0xFFFFFFFF); // neutral.c1
  static const Color black = Color(0xFF000000); // neutral.c16

  // ── Accents ─────────────────────────────────────────────────────────────────
  static const Color accent1 = Color(0xFFFF5324); // red.c7 (primary red)
  static const Color accent1Dark = Color(0xFFF0390E); // red.c9
  static const Color accent1Light = Color(0xFFFFF5F2); // red.c1
  static const Color accent2 = Color(0xFF00B080); // green.c7
  static const Color accent2Dark = Color(0xFF00805D); // green.c9
  static const Color accent2Light = Color(0xFFE8FCF8); // green.c1
  static const Color accent3 = Color(0xFFCC8100); // gold.c7
  static const Color accent3Dark = Color(0xFFB87400); // gold.c9
  static const Color accent3Light = Color(0xFFFFF6E6); // gold.c1
  static const Color accent4 = Color(0xFFFFEA52); // yellow.c6
  static const Color accent4Dark = Color(0xFFFFF185); // yellow.c4
  static const Color accent4Light = Color(0xFFFFFDE0); // yellow.c1
  static const Color accent4Foreground = Color(0xFF6F2C03); // orange.c14

  // ── System states ─────────────────────────────────────────────────────────
  static const Color link = Color(0xFF1963CC); // blue.c9
  static const Color success = Color(0xFF00B080); // cyan/green
  static const Color successBg = Color(0xFFF1FEFA); // cyan.c1
  static const Color error = Color(0xFFF0390E); // magenta/red
  static const Color errorBg = Color(0xFFFFF5F2); // magenta.c1
  static const Color warn = Color(0xFFEE7F00); // orange.c9
  static const Color warnBg = Color(0xFFFFFEEB); // orange.c1

  // ── Campaign (light-only block in source) ───────────────────────────────────
  static const Color finalPrice = Color(0xFFF0390E); // campaign price red
  static const Color finalPriceBg = Color(0xFFFFF1F0); // price.lightBg
  // promotionTag — dark/medium/light backgrounds with their own fg-on colors.
  static const Color promotionTagBg = Color(0xFFFFE41F); // promotionTag.darkBg
  static const Color promotionTagFg = Color(0xFF662200); // fgOnDark
  static const Color promotionTagMediumBg = Color(0xFFFFEE6B); // mediumBg
  static const Color promotionTagFgOnMedium = Color(0xFF662200); // fgOnMedium
  static const Color promotionTagLightBg = Color(0xFFFFF6B0); // lightBg
  static const Color promotionTagFgOnLight = Color(0xFF662200); // fgOnLight
  // freeDelivery — fg-on-white + light/medium backgrounds with their fg-on colors.
  static const Color freeDelivery = Color(0xFF00A175); // fgOnWhite (green)
  static const Color freeDeliveryBg = Color(0xFFE2F6F0); // lightBg
  static const Color freeDeliveryFgOnLight = Color(0xFF008C65); // fgOnLight
  static const Color freeDeliveryMediumBg = Color(0xFFC3EADE); // mediumBg
  static const Color freeDeliveryFgOnMedium = Color(0xFF006348); // fgOnMedium

  // ── Overlays (literal hex+alpha) ────────────────────────────────────────────
  static const Color overlayPrimary = Color(0x99000000); // black 60%
  static const Color overlayDivider = Color(0x14000000); // black 8%
  static const Color overlayOnContent = Color(0x08000000); // black 3%

  // ── Full reference ramps (light) ────────────────────────────────────────────
  /// neutral c1..c16 (light).
  static const List<Color> neutral = [
    Color(0xFFFFFFFF), Color(0xFFF5F6FA), Color(0xFFF0F1F5), Color(0xFFEBEBEB),
    Color(0xFFD9D9D9), Color(0xFFC2C2C2), Color(0xFFB3B3B3), Color(0xFF999999),
    Color(0xFF888888), Color(0xFF777777), Color(0xFF666666), Color(0xFF555555),
    Color(0xFF444444), Color(0xFF333333), Color(0xFF1A1A1A), Color(0xFF000000),
  ];

  /// yellow c1..c14 (light) — brand ramp.
  static const List<Color> yellow = [
    Color(0xFFFFFDE0), Color(0xFFFFFBC2), Color(0xFFFFF9A3), Color(0xFFFFF185),
    Color(0xFFFFF05B), Color(0xFFFFEA52), Color(0xFFFFE41F), Color(0xFFF5DA0F),
    Color(0xFFE5CB00), Color(0xFFD6BA00), Color(0xFFCCAD00), Color(0xFFB89900),
    Color(0xFFA38300), Color(0xFF7A6200),
  ];

  /// red c1..c14 (light).
  static const List<Color> red = [
    Color(0xFFFFF5F2), Color(0xFFFFD0C2), Color(0xFFFFB59E), Color(0xFFFF9D80),
    Color(0xFFFF8566), Color(0xFFFF6842), Color(0xFFFF5324), Color(0xFFFA420F),
    Color(0xFFF0390E), Color(0xFFE5370D), Color(0xFFDB2C00), Color(0xFFCC2A04),
    Color(0xFFBD2400), Color(0xFFA31F00),
  ];

  /// green c1..c14 (light).
  static const List<Color> green = [
    Color(0xFFE8FCF8), Color(0xFFD3FAEE), Color(0xFFB1F0DD), Color(0xFF87E0C8),
    Color(0xFF49CCA8), Color(0xFF17C293), Color(0xFF00B080), Color(0xFF00996F),
    Color(0xFF00805D), Color(0xFF007A59), Color(0xFF007052), Color(0xFF00664A),
    Color(0xFF005C43), Color(0xFF004D38),
  ];

  /// orange c1..c14 (light).
  static const List<Color> orange = [
    Color(0xFFFFFEEB), Color(0xFFFFEBD4), Color(0xFFFFDFBA), Color(0xFFFFD29E),
    Color(0xFFFFB969), Color(0xFFFFA845), Color(0xFFF49427), Color(0xFFEE8915),
    Color(0xFFEE7F00), Color(0xFFCC6D00), Color(0xFFB86200), Color(0xFFAD5C00),
    Color(0xFF8F4C00), Color(0xFF6F2C03),
  ];

  /// blue c1..c14 (light).
  static const List<Color> blue = [
    Color(0xFFE6F4FF), Color(0xFFD4E9FF), Color(0xFFC2DEFF), Color(0xFFABD0FF),
    Color(0xFF8FC3FF), Color(0xFF75B6FF), Color(0xFF5CAAFF), Color(0xFF458EF5),
    Color(0xFF1963CC), Color(0xFF135AC4), Color(0xFF0D49A9), Color(0xFF08398E),
    Color(0xFF042973), Color(0xFF001D66),
  ];

  /// gold c1..c14 (light) — accent3 ramp.
  static const List<Color> gold = [
    Color(0xFFFFF6E6), Color(0xFFFAE6C4), Color(0xFFFFCB70), Color(0xFFFFB83D),
    Color(0xFFFFAD1F), Color(0xFFEB9B13), Color(0xFFCC8100), Color(0xFFCC8A18),
    Color(0xFFB87400), Color(0xFFA86B00), Color(0xFF9E6400), Color(0xFF945E00),
    Color(0xFF8A5700), Color(0xFF7A4E00),
  ];

  /// cyan c1..c14 (light) — success ramp (mixes cyan/green in source).
  static const List<Color> cyan = [
    Color(0xFFF1FEFA), Color(0xFFD7FAE0), Color(0xFFB7F7C6), Color(0xFF9DF2B3),
    Color(0xFF8CEBA3), Color(0xFF77E38E), Color(0xFF00B080), Color(0xFF28C658),
    Color(0xFF00805D), Color(0xFF0D9E2A), Color(0xFF098D23), Color(0xFF04781F),
    Color(0xFF025F19), Color(0xFF00450D),
  ];

  /// purple c1..c14 (light). NOTE: c12 = #8F0038 is a verbatim source anomaly
  /// (breaks ramp ordering) — kept exactly as in the token file.
  static const List<Color> purple = [
    Color(0xFFF9F0FF), Color(0xFFF2E4FF), Color(0xFFE8D1FF), Color(0xFFD7B7FA),
    Color(0xFFC394F2), Color(0xFFB07EE8), Color(0xFF965EDC), Color(0xFF722ED1),
    Color(0xFF6429BB), Color(0xFF541EAB), Color(0xFF301063), Color(0xFF8F0038),
    Color(0xFF1F0A47), Color(0xFF120338),
  ];

  /// magenta c1..c14 (light). NOTE: c9 = #F0390E is a verbatim source anomaly
  /// (breaks ramp ordering) — kept exactly as in the token file.
  static const List<Color> magenta = [
    Color(0xFFFFF5F2), Color(0xFFFFD6E8), Color(0xFFFF8BD9), Color(0xFFFF9AC9),
    Color(0xFFFF78AD), Color(0xFFFF4F8F), Color(0xFFFF337D), Color(0xFFF51D53),
    Color(0xFFF0390E), Color(0xFFC0003A), Color(0xFFA60037), Color(0xFF8F0030),
    Color(0xFF73002F), Color(0xFF5A0026),
  ];
}

/// Resolved semantic token bundle for one brightness. Carried on the [ThemeData]
/// as a [ThemeExtension] so widgets read `Theme.of(context).extension<KeetaColors>()`
/// (or the `context.colors` shorthand) and automatically flip in dark mode.
@immutable
class KeetaColors extends ThemeExtension<KeetaColors> {
  const KeetaColors({
    required this.brandPrimary,
    required this.brandForeground,
    required this.primaryText,
    required this.secondaryText,
    required this.tertiaryText,
    required this.disabledText,
    required this.divider,
    required this.smallBackground,
    required this.mediumBackground,
    required this.surface,
    required this.link,
    required this.success,
    required this.error,
    required this.warn,
    required this.finalPrice,
    required this.freeDelivery,
    required this.overlay,
  });

  final Color brandPrimary;
  final Color brandForeground;
  final Color primaryText;
  final Color secondaryText;
  final Color tertiaryText;
  final Color disabledText;
  final Color divider;
  final Color smallBackground;
  final Color mediumBackground;
  final Color surface;
  final Color link;
  final Color success;
  final Color error;
  final Color warn;
  final Color finalPrice;
  final Color freeDelivery;
  final Color overlay;

  static const KeetaColors light = KeetaColors(
    brandPrimary: Color(0xFFFFE41F),
    brandForeground: Color(0xFF000000),
    primaryText: Color(0xFF000000),
    secondaryText: Color(0xFF555555),
    tertiaryText: Color(0xFF999999),
    disabledText: Color(0xFFC2C2C2),
    divider: Color(0xFFEBEBEB),
    smallBackground: Color(0xFFF0F1F5),
    mediumBackground: Color(0xFFF5F6FA),
    surface: Color(0xFFFFFFFF),
    link: Color(0xFF1963CC),
    success: Color(0xFF00B080),
    error: Color(0xFFF0390E),
    warn: Color(0xFFEE7F00),
    finalPrice: Color(0xFFF0390E),
    freeDelivery: Color(0xFF00A175),
    overlay: Color(0x99000000),
  );

  static const KeetaColors dark = KeetaColors(
    brandPrimary: Color(0xFFF5DA0F),
    brandForeground: Color(0xFFFFFFFF),
    primaryText: Color(0xFFFFFFFF),
    secondaryText: Color(0xFF999999),
    tertiaryText: Color(0xFF555555),
    disabledText: Color(0xFF333333),
    divider: Color(0xFF222222),
    smallBackground: Color(0xFF1A1A1A),
    mediumBackground: Color(0xFF121212),
    surface: Color(0xFF000000),
    link: Color(0xFF75B6FF),
    success: Color(0xFF5CDBBD),
    error: Color(0xFFFF4F8F),
    warn: Color(0xFFFF8F5C),
    finalPrice: Color(0xFFF0390E),
    freeDelivery: Color(0xFF00A175),
    overlay: Color(0x99FFFFFF),
  );

  @override
  KeetaColors copyWith({
    Color? brandPrimary,
    Color? brandForeground,
    Color? primaryText,
    Color? secondaryText,
    Color? tertiaryText,
    Color? disabledText,
    Color? divider,
    Color? smallBackground,
    Color? mediumBackground,
    Color? surface,
    Color? link,
    Color? success,
    Color? error,
    Color? warn,
    Color? finalPrice,
    Color? freeDelivery,
    Color? overlay,
  }) {
    return KeetaColors(
      brandPrimary: brandPrimary ?? this.brandPrimary,
      brandForeground: brandForeground ?? this.brandForeground,
      primaryText: primaryText ?? this.primaryText,
      secondaryText: secondaryText ?? this.secondaryText,
      tertiaryText: tertiaryText ?? this.tertiaryText,
      disabledText: disabledText ?? this.disabledText,
      divider: divider ?? this.divider,
      smallBackground: smallBackground ?? this.smallBackground,
      mediumBackground: mediumBackground ?? this.mediumBackground,
      surface: surface ?? this.surface,
      link: link ?? this.link,
      success: success ?? this.success,
      error: error ?? this.error,
      warn: warn ?? this.warn,
      finalPrice: finalPrice ?? this.finalPrice,
      freeDelivery: freeDelivery ?? this.freeDelivery,
      overlay: overlay ?? this.overlay,
    );
  }

  @override
  KeetaColors lerp(ThemeExtension<KeetaColors>? other, double t) {
    if (other is! KeetaColors) return this;
    return KeetaColors(
      brandPrimary: Color.lerp(brandPrimary, other.brandPrimary, t)!,
      brandForeground: Color.lerp(brandForeground, other.brandForeground, t)!,
      primaryText: Color.lerp(primaryText, other.primaryText, t)!,
      secondaryText: Color.lerp(secondaryText, other.secondaryText, t)!,
      tertiaryText: Color.lerp(tertiaryText, other.tertiaryText, t)!,
      disabledText: Color.lerp(disabledText, other.disabledText, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      smallBackground: Color.lerp(smallBackground, other.smallBackground, t)!,
      mediumBackground: Color.lerp(mediumBackground, other.mediumBackground, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      link: Color.lerp(link, other.link, t)!,
      success: Color.lerp(success, other.success, t)!,
      error: Color.lerp(error, other.error, t)!,
      warn: Color.lerp(warn, other.warn, t)!,
      finalPrice: Color.lerp(finalPrice, other.finalPrice, t)!,
      freeDelivery: Color.lerp(freeDelivery, other.freeDelivery, t)!,
      overlay: Color.lerp(overlay, other.overlay, t)!,
    );
  }
}
