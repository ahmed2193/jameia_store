/// Process-lifetime constants. Real secrets/base URLs should come from a
/// `.env` (flutter_dotenv) or `--dart-define` in a production app — kept inline
/// here to keep the starter runnable with zero setup.
class AppConstants {
  AppConstants._();

  static const String appName = 'JameiaMart';

  /// Full-screen splash artwork (dark-navy product shot). Painted by the Flutter
  /// splash screen; the Android ≤11 / iOS native frames use the same image.
  static const String splashImage = 'assets/images/splash_screen.png';

  // ── Networking ─────────────────────────────────────────────────────────────
  static const String baseUrl = 'https://fooddelivery.mykeeta.com';
  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 20);

  /// Google Maps Platform key for the HTTP Places/geocoding endpoints, injected
  /// at build time: `flutter run --dart-define=MAPS_API_KEY=<key>`. Empty by
  /// default so NO secret ships in source; a web-service key can't be restricted
  /// by app signature, so a leaked literal is billable by anyone. When empty the
  /// LBS layer skips the billed Places calls and falls back to the native
  /// geocoder + offline [KeetaGeocode].
  static const String mapsApiKey = String.fromEnvironment('MAPS_API_KEY');

  // ── Storage keys (shared_preferences) ──────────────────────────────────────
  static const String kAuthToken = 'auth_token';
  static const String kOnboardingSeen = 'onboarding_seen';

  // ── Timing (business/bootstrap delays — NOT motion; motion lives in AppMotion)
  // 1.8s ≥ the 1.6s splash Ken-Burns (AppMotion.splashKenBurns) so the art
  // settles before the shell replaces the splash.
  static const Duration splashMinDuration = Duration(milliseconds: 1800);
  static const Duration fakeNetworkLatency = Duration(milliseconds: 400);

  /// 1-second wall-clock tick for countdowns (flash sale) — a business timer,
  /// not motion, so it lives here (motion durations live in `AppMotion`).
  static const Duration tick = Duration(seconds: 1);

  /// Default countdown window for a Home flash-sale rail (6h), in seconds.
  static const int flashSaleWindowSeconds = 6 * 60 * 60;

  /// Home hero carousel auto-advance dwell (business timer, not motion).
  static const Duration heroAutoAdvance = Duration(seconds: 4);

  /// Home search-pill trending-hint rotation dwell (business timer, not motion).
  static const Duration searchHintRotate = Duration(seconds: 3);

  /// Connectivity poll cadence for [ConnectivityCubit] (business timer, not
  /// motion). Reachability is re-checked at this interval to flip the offline
  /// banner online/offline.
  static const Duration connectivityPoll = Duration(seconds: 3);

  /// Search/filter typeahead debounce (business timer, not motion).
  static const Duration searchDebounce = Duration(milliseconds: 300);

  // ── Currency ────────────────────────────────────────────────────────────────
  /// The single display currency code (English). The catalog is priced in
  /// Kuwaiti Dinar; in Arabic the symbol "د.ك" is used instead — resolve the
  /// locale-aware label via `context.currencyCode` (see context_extensions).
  static const String kCurrencyCode = 'KD';

  /// KD is a 3-decimal currency (1 KD = 1000 fils) — prices render to 3 places.
  static const int kCurrencyDecimals = 3;
}

/// SUI spacing scale ([FACT] `dimen/sui_space_*`, dp) — a dense scale where
/// **12 / 16dp are the dominant gutters**. Use these instead of raw numbers.
class SuiSpace {
  SuiSpace._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12; // dominant gutter
  static const double l = 16; // dominant gutter
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  // Dense-scale exact steps ([FACT] `dimen/sui_space_*`) — named so call sites
  // never fall back to raw literals between the semantic tiers above.
  /// 1dp hairline gap ([FACT] `dimen/sui_space_1`).
  static const double s1 = 1;

  /// 3dp micro gap ([FACT] `dimen/sui_space_3`).
  static const double s3 = 3;

  /// 5dp gap ([FACT] `dimen/sui_space_5`).
  static const double s5 = 5;

  /// 6dp gap ([FACT] `dimen/sui_space_6`).
  static const double s6 = 6;

  /// 9dp gap ([FACT] `dimen/sui_space_9`).
  static const double s9 = 9;

  /// 10dp gap ([FACT] `dimen/sui_space_10`) — common module gutter.
  static const double s10 = 10;

  /// 11dp gap ([FACT] `dimen/sui_space_11`).
  static const double s11 = 11;

  /// 13dp gap ([FACT] `dimen/sui_space_13`).
  static const double s13 = 13;

  /// 14dp gap ([FACT] `dimen/sui_space_14`).
  static const double s14 = 14;

  /// 15dp gap ([FACT] `dimen/sui_space_15`).
  static const double s15 = 15;

  /// 18dp gap ([FACT] `dimen/sui_space_18`) — inter-tab gap.
  static const double s18 = 18;

  /// 19dp gap ([FACT] `dimen/sui_space_19`).
  static const double s19 = 19;

  /// 22dp gap ([FACT] `dimen/sui_space_22`).
  static const double s22 = 22;

  /// 26dp gap ([FACT] `dimen/sui_space_26`).
  static const double s26 = 26;

  /// 28dp gap ([FACT] `dimen/sui_space_28`).
  static const double s28 = 28;

  /// 30dp gap ([FACT] `dimen/sui_space_30`).
  static const double s30 = 30;

  /// 36dp gap ([FACT] `dimen/sui_space_36`).
  static const double s36 = 36;

  /// 40dp gap ([FACT] `dimen/sui_space_40`).
  static const double s40 = 40;

  /// 44dp gap ([FACT] `dimen/sui_space_44`) — primary control height.
  static const double s44 = 44;

  /// 46dp gap ([FACT] `dimen/sui_space_46`).
  static const double s46 = 46;

  /// 48dp gap ([FACT] `dimen/sui_space_48`) — min touch target.
  static const double s48 = 48;

  /// 50dp gap ([FACT] `dimen/sui_space_50`).
  static const double s50 = 50;

  /// 66dp gap ([FACT] `dimen/sui_space_66`).
  static const double s66 = 66;

  /// 300dp fixed block ([FACT] `dimen/sui_space_300`).
  static const double s300 = 300;

  // Additional layout rungs (component widths/heights that recur across feature
  // widgets — avatars, cards, thumbnails, banners). Same convention: a named
  // step so call sites never fall back to a raw literal.
  static const double s34 = 34;
  static const double s37 = 37; // compact PLP filter-chip strip height
  static const double s38 = 38;
  static const double s45 = 45; // compact PLP circle-row collapsed extent
  static const double s54 = 54;
  static const double s56 = 56;
  static const double s60 = 60;
  static const double s64 = 64;
  static const double s72 = 72;
  static const double s80 = 80;
  static const double s84 = 84; // compact PLP circle-row expanded extent
  static const double s90 = 90;
  static const double s92 = 92;
  static const double s96 = 96;
  static const double s116 = 116; // PLP filter-sheet section rail width
  static const double s140 = 140;
  static const double s200 = 200;
  static const double s220 = 220;
}

/// Icon glyph-size ramp (dp) — recurring `Icon(size:)` rungs. Mirrors the
/// [SuiSpace] / `AppTextStyles.size*` ramp convention so an inline icon size
/// references a named step instead of a raw magic number.
class SuiIcon {
  SuiIcon._();

  static const double size9 = 9;
  static const double size11 = 11;
  static const double size12 = 12;
  static const double size13 = 13;
  static const double size14 = 14;
  static const double size15 = 15;
  static const double size16 = 16;
  static const double size17 = 17;
  static const double size18 = 18;
  static const double size20 = 20;
  static const double size22 = 22;
  static const double size23 = 23;
  static const double size24 = 24;
  static const double size26 = 26;
  static const double size28 = 28;
  static const double size30 = 30;
  static const double size32 = 32;
  static const double size34 = 34;
  static const double size36 = 36;
  static const double size40 = 40;
  static const double size52 = 52;
  static const double size56 = 56;
  static const double size64 = 64;
  static const double size72 = 72;
}

/// SUI corner radii ([FACT] `dimen/.../radius`) — cards, sheets, buttons, chips.
class SuiRadius {
  SuiRadius._();

  // Decoded from the APK drawables (see 1Day_APK_ANALYSIS/extracted/components.md).
  static const double chip = 4; // generic chip/badge
  static const double labelChip = 8; // `sui_label_activity_common`
  static const double card = 4; // `bg_item_goods_card_corner`
  static const double button = 2; // CTAs near-square (0–2dp)
  static const double sheet = 12; // `bg_dialog_top_radius_12`
  static const double sidebar = 20; // `radius_sidebar = 20dp`
  static const double squircle = 18; // category circles/tiles (rounded-square)
  static const double badge = 2; // discount badge (flash badge uses 0)
  static const double tag = 0; // `filter_tag_radius` / `sui_tag_label_radius`
  static const double pill = 999;

  /// PDP price-belt callout corner ([FACT] `dimen/detail_price_corner_size = 13dp`).
  static const double detailPrice = 13;

  /// Coupon-tag corner ([FACT] `drawable/bg_store_coupon_tag = 1dp`).
  static const double couponTag = 1;

  /// Flash-sale badge corner ([FACT] `components.md §1` — flash badge = 0dp).
  static const double flashBadge = 0;

  /// PDP add-to-bag CTA variant corner ([FACT] `dimen/bottom_button_radius = 2dp`).
  /// (Default CTA [button] stays 2dp for compatibility; 1Day default is 0dp.)
  static const double buttonPdp = 2;

  /// 8dp CTA variant ([FACT] `drawable/sui_button_dark_8dp_corner = 8dp`).
  static const double button8 = 8;

  /// 6dp small inline callout corner (assistant inline cards / micro chips).
  static const double callout = 6;

  /// 16dp medium-rounded corner — chat bubbles, rounded feature tiles.
  static const double bubble = 16;

  /// 24dp input-pill corner — chat composer / search composer field.
  static const double inputPill = 24;

  /// 28dp splash logo-container corner.
  static const double logoTile = 28;
}

/// SUI home-layout sizes ([FACT] `dimen/sui_space_*` + screenshot-derived
/// ratios). Home widgets read these instead of hard-coded numbers so the feed
/// stays breakpoint-faithful to 1Day.
class SuiSize {
  SuiSize._();

  static const double tabBar = 44; // top category tab-bar height
  static const double indicatorThickness = 2; // tab / sub-tab underline
  static const double tabGap = 18; // inter-tab horizontal gap
  static const double heroRatio = 0.52; // hero height = width * ratio
  static const double heroVisible = 164; // hero content height below the bar
  static const double heroCurveLip = 24; // hero convex bottom lip
  static const double promoBar = 60; // cream Free-Shipping / Flash bar
  static const double promoDivider = 36; // free-shipping vertical divider height
  static const double searchBar = 38; // search field height
  static const double topActionTap = 40; // top-bar icon tap target
  static const double iconCircle = 56; // category icon circle diameter (≈56–58dp)
  static const double categoryStrip = 180; // 2-row category strip height
  static const double gridCaptionH = 30; // icon-grid 2-line caption box height
  static const double stripCardW = 112; // editorial card-strip card width
  static const double stripCardRatio = 0.72; // strip card width/height ratio
  static const double stripCardH = 156; // = stripCardW / stripCardRatio
  static const double stripLabelBar = 30; // strip card bottom label-bar height
  static const double pillTab = 34; // For You / New In pill height
  static const double bottomNav = 56; // bottom-nav height

  // Horizontal rails (dp). Content-fitted for a full ProductCard (discounted
  // price row + 2-line title): the narrower analysis dp (104/120/100) overflow
  // at 1.0× — proven by test/home_rails_overflow_test.dart — so these hold the
  // verified geometry. (To go narrower, the rail card needs a compact variant.)
  static const double dealRailCol = 104; // Super-Deals 2-row column width (1Day dp)
  static const double dealRailH = 460; // Super-Deals rail (2 stacked cards, fits 1-line title @1.3x)
  static const double railCardW = 120; // Trends product-rail card width (1Day dp)
  static const double railCardH = 250; // Trends product-rail card height
  static const double flashCardW = 100; // Flash-sale tile width (1Day dp)

  // Grid column counts.
  static const int homeIconGridCols = 5; // fashion flat icon grid
  static const int subCatGridCols = 4; // sub-tab module grid (4-col)
  static const int masonryCols = 2; // For-You waterfall

  // ── Button height system ([FACT] `dimen/sui_dimen_button_*_height`) ─────────
  static const double buttonHeight = 44; // [FACT] sui_dimen_button_height = 44dp
  static const double buttonBottom = 40; // [FACT] sui_dimen_button_bottom_height = 40dp
  static const double buttonHeightSmall = 36; // [FACT] sui_dimen_button_small_height = 36dp
  static const double buttonDialog = 36; // [FACT] sui_dimen_button_dialog_height = 36dp
  static const double buttonHeightLittle = 28; // [FACT] sui_dimen_button_little_height = 28dp
  static const double buttonHeightMini = 24; // [FACT] sui_dimen_button_mini_height = 24dp
  static const double buttonHeightPetty = 20; // [FACT] sui_dimen_button_petty_height = 20dp
  static const double buttonBottomMinWidth = 100; // [FACT] bottom CTA min width = 100dp
  static const double buttonLittlePadH = 12; // [FACT] little CTA horizontal padding = 12dp
  static const double buttonStrokeW = 0.5; // [FACT] sui_dimen_button_stroke_width = 0.5dp

  // ── Inputs / labels ─────────────────────────────────────────────────────────
  static const double inputHeight = 44; // [FACT] sui_text_input_height = 44dp
  static const double labelStroke = 1; // [FACT] sui_dimen_label_stroke_width = 1dp
  static const double labelStrokeBold = 1.5; // [FACT] sui_dimen_label_stroke_width2 = 1.5dp
  static const double labelMiniHeight = 16; // [FACT] sui_dimen_label_mini_height = 16dp
  static const double cardSelectStrokeW = 1; // [FACT] bg_item_goods_card_corner selected hairline = 1dp

  // ── Tabs / sub-tabs ─────────────────────────────────────────────────────────
  static const double tabLayoutHeight = 36; // [FACT] sui_info_flow_tab_layout_height = 36dp

  // ── Slider (price-range filter) ─────────────────────────────────────────────
  static const double sliderThumbRadius = 10; // [FACT] mtrl_slider_thumb_radius = 10dp
  static const double sliderTrackHeight = 4; // [FACT] mtrl_slider_track_height = 4dp

  // ── Dividers ────────────────────────────────────────────────────────────────
  static const double dividerThickness = 1; // [FACT] m3_comp_divider_thickness = 1dp
  static const double dividerHairline = 0.6; // [FACT] divider = 0.6dp
  static const double hairline = 0.5; // [FACT] #goods_detail_v_dividerline = 0.5dp

  // ── Badges ──────────────────────────────────────────────────────────────────
  static const double badgeWithText = 16; // [FACT] mtrl_badge_with_text_size = 16dp
  static const double badgeDot = 8; // [FACT] mtrl_badge_size = 8dp (dot)
  static const double redDot = 16; // [FACT] #goods_detail_red_dot_view = 16dp

  /// Empty-state glyph diameter (bag / wishlist / coupons empty views, 72dp).
  static const double emptyGlyph = 72;

  // ── Touch targets / sheets ──────────────────────────────────────────────────
  static const double minTouchTarget = 48; // [FACT] mtrl_min_touch_target_size = 48dp
  static const double sheetHandleWidth = 32; // [FACT] m3_comp_sheet_bottom_docked_drag_handle_width = 32dp
  static const double sheetHandleHeight = 4; // [FACT] m3_comp_sheet_bottom_docked_drag_handle_height = 4dp

  // ── Layout convention aliases ───────────────────────────────────────────────
  /// Standardized outer page gutter (dp). 1Day keeps a consistent ≈12dp
  /// page edge inset for top-level home sections (strips, free-shipping,
  /// masonry sliver, deal modules); in-card padding stays at SuiSpace.s(8).
  /// Use this alias at section call sites to kill the 8↔12 gutter drift
  /// (sizing_spacing.md #35). Value mirrors SuiSpace.m.
  static const double pageGutter = 12;

  /// Masonry / product-card image aspect (W÷H). 3:4 portrait, matches the
  /// 1Day waterfall (sizing_spacing.md #23). Optional centralization token —
  /// the feature already uses 3/4 inline and is 1:1 correct.
  static const double productImageRatio = 0.75;

  // ── PDP buy-bar / CTA geometry ([FACT] layouts_decoded.md §1) ────────────────
  /// PDP sticky bottom buy bar height ([FACT] #goods_detail_ct_footer_buy, 52dp).
  static const double buyBar = 52;

  /// PDP / add-bag CTA button height ([FACT] 0dp×40dp CTA row).
  static const double ctaButton = 40;

  /// Sign-in primary/secondary/guest button height ([FACT] match × 45dp).
  static const double authButton = 45;

  /// PDP sticky section-tab strip / toolbar offset ([FACT] 44dp).
  static const double pdpTabStrip = 44;

  /// PDP half-screen / pop-mode close bar height ([FACT] 66dp).
  static const double popModeCloseBar = 66;

  /// PDP buy-bar support / store / wishlist icon box ([FACT] 32×32dp).
  static const double barIcon = 32;

  /// PDP buy-bar cart-with-badge tap box ([FACT] 44×44dp).
  static const double cartIcon = 44;

  /// Toolbar nav-back / action icon glyph size ([FACT] 24×24dp).
  static const double navBackIcon = 24;

  /// Floating 'free shipping' pill height ([FACT] wrap × 16dp).
  static const double freeShipPill = 16;

  /// Float-price mini add-bag button ([FACT] #flFloatPriceAddBag, 44×28dp).
  static const double miniAddBagW = 44;
  static const double miniAddBagH = 28;

  /// Product-card flash-sale flag ([FACT] view_discount_flash, 23×25dp).
  static const double flashFlagW = 23;
  static const double flashFlagH = 25;

  /// Quick add-bag overlay on card image ([FACT] 24×24dp).
  static const double quickAddBag = 24;

  /// Product-card wishlist '...' button box ([FACT] #gl_wish_view_more, 20×20dp).
  static const double wishMore = 20;

  /// Product-card image→price-row vertical gap ([FACT] #ll_price marginTop, 8dp).
  static const double cardPriceGap = 8;

  // ── Cart / checkout geometry ([FACT] layouts_decoded.md §2,§3) ───────────────
  /// Cart top gradient/status banner height ([FACT] #cartStatusBg, 110dp).
  static const double cartStatusBanner = 110;

  /// Cart swipe-to-delete end-action reveal width ([FACT] swipeItemWidth=60dp).
  static const double swipeAction = 60;

  /// Checkout / cart-summary line-item thumbnail ([FACT] rv_item_goods, 63.8dp).
  static const double checkoutThumb = 63.8;

  /// Cart line-item product thumbnail ([INFERENCE] ~88dp square; SCGoodsRootLayoutV2 internals are Kotlin-drawn).
  static const double cartItemImage = 88;

  // ── Sign-in 'or' divider ([FACT] layouts_decoded.md §5) ─────────────────────
  /// Sign-in 'or'-divider rule length ([FACT] View 90×1dp per side).
  static const double orDividerLine = 90;

  // ── Floating cart button (PLP / store add-to-bag affordance) ────────────────
  /// White cart circle diameter.
  static const double cartFabCircle = 52;

  /// FAB Stack bounds — room for the count badge + "SAVE" pill overflow.
  static const double cartFabBoundsW = 60;
  static const double cartFabBoundsH = 70;

  // ── Store rail / banner geometry (live layout + StoreSkeleton) ──────────────
  /// Store horizontal product-rail height.
  static const double storeRailH = 244;

  /// Store rail card width.
  static const double storeRailCardW = 150;

  /// Store banner-hero height.
  static const double storeBannerH = 190;
}

/// Image decode-width budgets (px) for [ProductImage.memWidth], keyed per
/// surface so a 56dp tile doesn't decode at hero resolution. Targets match the
/// 1Day APK analysis (display-side px on a ~3× phone):
/// tile 56dp≈168px → 160 · strip 96–132dp≈300px → 320 · card ~270px → 600 ·
/// hero full-bleed ≈1080px → 1080. Oversized decode is the top Android
/// list-jank + GC-pressure cause; pass the right token at each call site.
class SuiImage {
  SuiImage._();

  static const int memTile = 160; // icon circles / small thumbnails
  static const int memStrip = 320; // editorial strip & rail cards
  static const int memCard = 600; // masonry / catalog product cards (default)
  static const int memHero = 1080; // full-bleed hero banners
}
