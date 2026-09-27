import 'package:flutter/material.dart';

/// Hero design-token color system — extracted verbatim from the APK theme JSON
/// (`assets/Theme/base/base/{light,dark}.json`, v3.5.214).
///
/// 3-tier W3C token model: reference palettes (`_Ramp`s) → semantic system tokens
/// (the static getters on [AppColors]) → component (empty in source).
///
/// Brand color = yellow `#FFE41F` (light) / `#F5DA0F` (dark); foreground = black/white.
/// Raw `Color(0x..)` literals live ONLY in this token layer — never in feature code.
///
/// Light is the primary surface (Hero ships light-first). Full dark ramps are kept
/// for parity and surfaced through [HeroColors] (the [ThemeExtension]).
class AppColors {
  AppColors._();

  // ── Brand (yellow) ─────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF22C55E); // Hero green (green-500)
  static const Color primaryDark = Color(
    0xFF16A34A,
  ); // green-600 (pressed/border)
  static const Color brandForeground = Color(
    0xFFFFFFFF,
  ); // shiny white — text / icons on any primary-green fill
  static const Color brandDarkBg = Color(0xFF4ADE80); // green-400 brand tint
  static const Color brandLightBg = Color(0xFFDCFCE7); // green-100 brand tint

  /// Deep brand green (the "Hero" wordmark of the logo, green-700): brand
  /// text on white (5:1) — the search screens' highlights and links.
  static const Color brandDeep = Color(0xFF15803D);

  /// Chosen / applied surface: Hero's selected-choice mint (#EFFFF4);
  /// lighter than [brandLightBg].
  static const Color brandWash = Color(0xFFF0FDF4);

  /// Press highlight: [primary] at 10 %, the one brand touch tint.
  static const Color pressTint = Color(0x1A22C55E);

  /// The dark rim around the white "sticker" letters of the buy buttons and
  /// deal tags (`StickerText`): near-black green, so it reads on the brand
  /// green and on the red deal tag alike.
  static const Color stickerOutline = Color(0xFF0B2E13);

  // ── Neutral semantic roles (light) ──────────────────────────────────────────
  // Hero's rendered Mach screens use #222222 primary / #808080 secondary
  // (verified across every bundle.css.json) — softer than the theme-JSON
  // #000/#555. We match the rendered values; `black` below stays true #000.
  static const Color primaryText = Color(
    0xFF111827,
  ); // slate-900 ink (Hero Text)
  static const Color secondaryText = Color(0xFF808080);
  static const Color tertiaryText = Color(0xFF999999); // neutral.c8
  static const Color disabledText = Color(0xFFC2C2C2); // neutral.c6
  static const Color divider = Color(0xFFEBEBEB); // neutral.c4
  static const Color smallBackground = Color(
    0xFFF1F5F9,
  ); // slate-100 (subtle surface)
  static const Color mediumBackground = Color(
    0xFFF8FAFC,
  ); // slate-50 (page background)
  static const Color white = Color(0xFFFFFFFF); // neutral.c1
  static const Color black = Color(0xFF000000); // neutral.c16

  /// The offline banner: a calm dark neutral (slate-800) — offline is a
  /// state, not an error, so never red. White text on it is 14.7:1.
  static const Color offlineSurface = Color(0xFF1F2937);

  // ── Accents ─────────────────────────────────────────────────────────────────
  static const Color accent1 = Color(0xFFFF5324); // red.c7 (primary red)
  static const Color accent1Dark = Color(0xFFF0390E); // red.c9
  static const Color accent1Light = Color(0xFFFFF5F2); // red.c1
  static const Color accent2 = Color(0xFF00B080); // green.c7
  static const Color accent2Dark = Color(0xFF00805D); // green.c9
  static const Color accent2Light = Color(0xFFE8FCF8); // green.c1
  static const Color accent3 = Color(0xFFF99022); // Hero accent orange
  static const Color accent3Dark = Color(0xFFE07D12); // accent orange (pressed)
  static const Color accent3Light = Color(
    0xFFFEF1E1,
  ); // accent orange (light bg)
  static const Color accent4 = Color(0xFFFFEA52); // yellow.c6
  static const Color accent4Dark = Color(0xFFFFF185); // yellow.c4
  static const Color accent4Light = Color(0xFFFFFDE0); // yellow.c1
  static const Color accent4Foreground = Color(0xFF6F2C03); // orange.c14

  // ── Backend accent families the palette above lacks ───────────────────────
  // The Hero backend tints home blocks with one of seven families (emerald,
  // amber, rose, violet, sky, orange, zinc). Five map onto existing tokens;
  // violet and the light sky wash had no counterpart.
  static const Color accentViolet = Color(0xFF7C3AED);
  static const Color accentVioletLight = Color(0xFFF3EEFF);
  static const Color accentSkyLight = Color(0xFFE8F1FD);

  // ── Hero Pro paywall ────────────────────────────────────────────────────
  // Pro is violet (`accentViolet` / `accentVioletLight`); the paywall's second
  // accent — the "Save N%" badge and the headline on the violet hero band — is
  // a lime with no counterpart in the palette above.
  static const Color proLime = Color(0xFFD4F53C);

  // The website's Pro identity (jm3eia.store `.pro-gradient`
  // 135deg #4F46E5 → #7C3AED (= accentViolet) → #A21CAF, accent #FBBF24 for
  // the crown and the glow). Used for the member card, the success moment and
  // the violet hero band so the app and the site read as one brand.
  static const Color proIndigo = Color(0xFF4F46E5);
  static const Color proFuchsia = Color(0xFFA21CAF);
  static const Color proAmber = Color(0xFFFBBF24);
  static const List<Color> proGradient = [proIndigo, accentViolet, proFuchsia];

  // ── System states ─────────────────────────────────────────────────────────
  static const Color link = Color(0xFF1963CC); // blue.c9
  static const Color success = Color(0xFF00B080); // cyan/green
  static const Color successBg = Color(0xFFF1FEFA); // cyan.c1
  static const Color error = Color(0xFFF0390E); // magenta/red
  static const Color errorBg = Color(0xFFFFF5F2); // magenta.c1

  /// Red text on [errorBg] / white that meets AA for small bold text (5.7:1);
  /// [error] itself is 3.7:1 there.
  static const Color errorDeep = Color(0xFFBD2400);
  static const Color warn = Color(0xFFEE7F00); // orange.c9
  static const Color warnBg = Color(0xFFFFFEEB); // orange.c1

  // ── Campaign (light-only block in source) ───────────────────────────────────
  static const Color finalPrice = Color(0xFFF0390E); // campaign price red
  static const Color finalPriceBg = Color(0xFFFFF1F0); // price.lightBg
  // promotionTag — dark/medium/light backgrounds with their own fg-on colors.
  static const Color promotionTagBg = Color(0xFFFFE41F); // promotionTag.darkBg
  static const Color promotionTagFg = Color(0xFF662200); // fgOnDark
  static const Color promotionTagLightBg = Color(0xFFFFF6B0); // lightBg
  static const Color promotionTagFgOnLight = Color(0xFF662200); // fgOnLight
  // freeDelivery — fg-on-white + light/medium backgrounds with their fg-on colors.
  static const Color freeDelivery = Color(0xFF00A175); // fgOnWhite (green)
  static const Color freeDeliveryBg = Color(0xFFE2F6F0); // lightBg
  static const Color freeDeliveryFgOnLight = Color(0xFF008C65); // fgOnLight

  // ── Hero grocery PDP green (product-detail screen only) ──────────────────
  // The live Hero product-detail page uses a vivid spring-green accent for the
  // add-to-cart CTA, the floating "+" add buttons, the kcal badge and the
  // flash-deal bolt — distinct from Hero's yellow brand, which stays everywhere
  // else. Scoped to the product-detail surface.
  static const Color martGreen = Color(0xFF16B364); // add-to-cart / "+" / bolt
  static const Color martGreenDark = Color(0xFF0E9552); // pressed / border
  static const Color martGreenLight = Color(0xFFE7F8EF); // kcal / bolt chip bg

  // ── Overlays (literal hex+alpha) ────────────────────────────────────────────
  static const Color overlayPrimary = Color(0x99000000); // black 60%
  static const Color overlayDivider = Color(0x14000000); // black 8%
  static const Color popupScrim = Color(0xBF000000); // black 75% (popup digest)

  /// The dim behind the blocking busy overlay (black 45 %): the page stays
  /// readable behind the white loader disc.
  static const Color busyScrim = Color(0x73000000);

  // ── Reference-exact extras (golden card / sku / newborn / separators) ───────
  static const Color couponRibbon = Color(
    0xFFD90012,
  ); // golden ribbon (atom c1cd40)
  static const Color skuOptionFg = Color(
    0xFF713901,
  ); // sku spec chip / price brown (be15a6)
  static const Color dotSep = Color(0xFFC2C2C2); // 2dp dot separator (c82c4a)
  static const Color vBarSep = Color(0xFFA5A5A5); // 1×15 vertical bar (je25a6)
  static const Color tabIndicator = Color(
    0xFF0D0D0D,
  ); // shop sub-cat tab underline (near-black)
  static const Color subtitleOverlay = Color(
    0xCCFFFFFF,
  ); // 80% white subtitle over image

  // ── Presentation extras (relocated from inline literals — value-identical) ───
  // Neutral text/border greys used across account, search, home & checkout.
  static const Color labelGrey = Color(
    0xFF4D4D4D,
  ); // 12dp secondary label / meta

  // Solid accents / fills.
  static const Color chatBubbleMine = Color(
    0xFFC6E484,
  ); // IM chat outgoing bubble green
  static const Color logoutRed = Color(
    0xFFE31727,
  ); // settings log-out action red
  static const Color unreadBadgeBg = Color(
    0xFFFFDE38,
  ); // customer-service unread badge bg
  static const Color deliveryCodeBg = Color(
    0xFFFFF6CB,
  ); // delivery-code panel highlight
  static const Color couponBadgeRed = Color(
    0xFFF14E24,
  ); // checkout coupon count badge red
  static const Color tooltipFill = Color(
    0xFF333333,
  ); // checkout savings-hint bubble + tail (solid, not an alpha scrim)
  static const Color brandTileBorder = Color(
    0xFFF0F0F0,
  ); // popular-brands tile hairline
  static const Color trackingLineTodo = Color(
    0xFFDEDFE4,
  ); // tracking connector (inactive)

  // Collection page hero (offers, flash deals, best sellers): warm beige band.
  static const Color collectionCream = Color(0xFFF3EDE5);

  // Voucher ticket (home popup) — cream fill, brown ink, tan condition text.
  static const Color voucherCream = Color(0xFFFFFEF5); // amount panel fill
  static const Color voucherBrown = Color(0xFF6A2F00); // amount / title ink
  static const Color voucherTanFaint = Color(
    0x33A77D5B,
  ); // tear-line perforation (tan 20%)

  // Black-alpha scrims / hairlines (literal alpha over #000000).
  static const Color scrimTransparent = Color(
    0x00000000,
  ); // fully-transparent gradient stop
  static const Color shadowInk10 = Color(
    0x1A000000,
  ); // 10% soft shadow / thin separator

  // Ink-tint (#222222) overlays / dots.
  static const Color dotInactive = Color(
    0x4C222222,
  ); // page-indicator inactive dot
  static const Color rowDividerInk = Color(
    0x14222222,
  ); // address-list row hairline

  // Misc overlays.
  static const Color popupCloseScrim = Color(
    0x33FFFFFF,
  ); // popup close-button fallback bg
  static const Color bannerScrimTransparent = Color(
    0x001A160C,
  ); // banner gradient top (0%)
  static const Color bannerScrim50 = Color(
    0x801A160C,
  ); // banner gradient bottom (~50%)
  static const Color bannerTagBg = Color(0x7F1A160C); // shop-banner tag chip bg

  // ── Full reference ramps (light) ────────────────────────────────────────────

  /// green c1..c14 (light).
  static const List<Color> green = [
    Color(0xFFE8FCF8),
    Color(0xFFD3FAEE),
    Color(0xFFB1F0DD),
    Color(0xFF87E0C8),
    Color(0xFF49CCA8),
    Color(0xFF17C293),
    Color(0xFF00B080),
    Color(0xFF00996F),
    Color(0xFF00805D),
    Color(0xFF007A59),
    Color(0xFF007052),
    Color(0xFF00664A),
    Color(0xFF005C43),
    Color(0xFF004D38),
  ];

  /// orange c1..c14 (light).
  static const List<Color> orange = [
    Color(0xFFFFFEEB),
    Color(0xFFFFEBD4),
    Color(0xFFFFDFBA),
    Color(0xFFFFD29E),
    Color(0xFFFFB969),
    Color(0xFFFFA845),
    Color(0xFFF49427),
    Color(0xFFEE8915),
    Color(0xFFEE7F00),
    Color(0xFFCC6D00),
    Color(0xFFB86200),
    Color(0xFFAD5C00),
    Color(0xFF8F4C00),
    Color(0xFF6F2C03),
  ];

  /// magenta c1..c14 (light). NOTE: c9 = #F0390E is a verbatim source anomaly
  /// (breaks ramp ordering) — kept exactly as in the token file.
  static const List<Color> magenta = [
    Color(0xFFFFF5F2),
    Color(0xFFFFD6E8),
    Color(0xFFFF8BD9),
    Color(0xFFFF9AC9),
    Color(0xFFFF78AD),
    Color(0xFFFF4F8F),
    Color(0xFFFF337D),
    Color(0xFFF51D53),
    Color(0xFFF0390E),
    Color(0xFFC0003A),
    Color(0xFFA60037),
    Color(0xFF8F0030),
    Color(0xFF73002F),
    Color(0xFF5A0026),
  ];
}

// ── Hero-store surfaces (ported verbatim from the source store screen) ──
// The Hero home hero/search/promo/categories block uses its own brand-orange
// palette (independent of Hero's yellow brand) so the ported top matches the
// Hero design 1:1. Kept as top-level consts in the token layer (mirrors
// Hero's app_colors.dart), never inlined in feature code.
const Color kHeroPillPin = Color(0xFFFF6108); // address-pill location pin
const Color kHeroPillChevron = Color(0xFFFF7300); // address-pill chevron
const Color kHeroSearchHint = Color(0xFF696969); // search hint + scan glyph
const Color kHeroPromoCream = Color(0xFFFDF5EB); // Hero card fill

/// Resolved semantic token bundle for one brightness. Carried on the [ThemeData]
/// as a [ThemeExtension] so widgets read `Theme.of(context).extension<HeroColors>()`
/// (or the `context.colors` shorthand) and automatically flip in dark mode.
@immutable
class HeroColors extends ThemeExtension<HeroColors> {
  const HeroColors({
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
    required this.offlineSurface,
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

  /// The offline banner surface (see [AppColors.offlineSurface]).
  final Color offlineSurface;

  static const HeroColors light = HeroColors(
    brandPrimary: Color(0xFF22C55E),
    brandForeground: Color(0xFFFFFFFF),
    primaryText: Color(0xFF111827),
    secondaryText: Color(0xFF808080),
    tertiaryText: Color(0xFF999999),
    disabledText: Color(0xFFC2C2C2),
    divider: Color(0xFFEBEBEB),
    smallBackground: Color(0xFFF1F5F9),
    mediumBackground: Color(0xFFF8FAFC),
    surface: Color(0xFFFFFFFF),
    link: Color(0xFF1963CC),
    success: Color(0xFF00B080),
    error: Color(0xFFF0390E),
    warn: Color(0xFFEE7F00),
    finalPrice: Color(0xFFF0390E),
    freeDelivery: Color(0xFF00A175),
    overlay: Color(0x99000000),
    offlineSurface: Color(0xFF1F2937),
  );

  static const HeroColors dark = HeroColors(
    brandPrimary: Color(0xFF22C55E),
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
    offlineSurface: Color(0xFF374151),
  );

  @override
  HeroColors copyWith({
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
    Color? offlineSurface,
  }) {
    return HeroColors(
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
      offlineSurface: offlineSurface ?? this.offlineSurface,
    );
  }

  @override
  HeroColors lerp(ThemeExtension<HeroColors>? other, double t) {
    if (other is! HeroColors) return this;
    return HeroColors(
      brandPrimary: Color.lerp(brandPrimary, other.brandPrimary, t)!,
      brandForeground: Color.lerp(brandForeground, other.brandForeground, t)!,
      primaryText: Color.lerp(primaryText, other.primaryText, t)!,
      secondaryText: Color.lerp(secondaryText, other.secondaryText, t)!,
      tertiaryText: Color.lerp(tertiaryText, other.tertiaryText, t)!,
      disabledText: Color.lerp(disabledText, other.disabledText, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      smallBackground: Color.lerp(smallBackground, other.smallBackground, t)!,
      mediumBackground: Color.lerp(
        mediumBackground,
        other.mediumBackground,
        t,
      )!,
      surface: Color.lerp(surface, other.surface, t)!,
      link: Color.lerp(link, other.link, t)!,
      success: Color.lerp(success, other.success, t)!,
      error: Color.lerp(error, other.error, t)!,
      warn: Color.lerp(warn, other.warn, t)!,
      finalPrice: Color.lerp(finalPrice, other.finalPrice, t)!,
      freeDelivery: Color.lerp(freeDelivery, other.freeDelivery, t)!,
      overlay: Color.lerp(overlay, other.overlay, t)!,
      offlineSurface: Color.lerp(offlineSurface, other.offlineSurface, t)!,
    );
  }
}
