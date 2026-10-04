/// Process-lifetime constants. Real secrets/base URLs should come from a
/// `.env` (flutter_dotenv) or `--dart-define` in a production app — kept inline
/// here to keep the starter runnable with zero setup.
class AppConstants {
  AppConstants._();

  static const String appName = 'Hero';

  /// The translation files (`<languageCode>.json`): EasyLocalization reads
  /// the app's language from here, the invoice PDF the one it is written in.
  static const String translationsDir = 'assets/i18n';

  // ── Networking ─────────────────────────────────────────────────────────────
  // The API host is build-time config: `AppEnv.apiBaseUrl` (`--dart-define`).
  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 20);
  static const Duration sendTimeout = Duration(seconds: 20);

  /// How long one outside road service may take to draw a route before the
  /// next is asked (the live map waits on it): a slow public server never
  /// holds the map for the full request timeouts.
  static const Duration roadRouteBudget = Duration(seconds: 6);

  /// Google Maps Platform key for the HTTP Places/geocoding endpoints, injected
  /// at build time: `flutter run --dart-define=MAPS_API_KEY=<key>`. Empty by
  /// default so NO secret ships in source; a web-service key can't be restricted
  /// by app signature, so a leaked literal is billable by anyone. When empty the
  /// LBS layer skips the billed Places calls and falls back to the native
  /// geocoder + offline [HeroGeocode].
  static const String mapsApiKey = String.fromEnvironment('MAPS_API_KEY');

  // ── Storage keys (shared_preferences) ──────────────────────────────────────
  // Auth tokens are NOT prefs keys: they live in the keychain via `SessionStore`.
  static const String kOnboardingSeen = 'onboarding_seen';

  // ── Timing (business/bootstrap delays — NOT motion; motion lives in AppMotion)
  static const Duration fakeNetworkLatency = Duration(milliseconds: 400);

  /// 1-second wall-clock tick for countdowns (flash sale) — a business timer,
  /// not motion, so it lives here (motion durations live in `AppMotion`).
  static const Duration tick = Duration(seconds: 1);

  /// Default countdown window for a Home flash-sale rail (6h), in seconds.
  static const int flashSaleWindowSeconds = 6 * 60 * 60;

  /// Reachability re-check cadence WHILE OFFLINE (business timer, not motion):
  /// short, so the app notices the connection coming back quickly.
  static const Duration connectivityPoll = Duration(seconds: 3);

  /// Reachability re-check cadence while online: only catches a connection
  /// that drops while the customer is idle (a failed request re-checks at
  /// once). Two probes a minute stay far under the 300 / 60 s rate limit.
  static const Duration connectivityPollOnline = Duration(seconds: 30);

  /// Longest one reachability probe waits for its host.
  static const Duration connectivityProbeTimeout = Duration(seconds: 5);

  /// How long the monitor must keep reporting "unreachable" before the app
  /// says it is offline — a Wi-Fi ↔ mobile handover never flickers the banner.
  static const Duration offlineDebounce = Duration(milliseconds: 1500);

  /// How long the "Back online" confirmation stays before the banner closes.
  static const Duration backOnlineHold = Duration(seconds: 2);

  /// Shortest time the banner says "Reconnecting…" after a tap, so a check
  /// that fails at once (airplane mode) is still seen to run.
  static const Duration connectivityRetryDwell = Duration(milliseconds: 700);

  /// Longest random wait before a screen refreshes on reconnect, so the
  /// screens that come back together do not hit the backend in one instant.
  static const Duration reconnectJitter = Duration(milliseconds: 600);

  /// A screen whose first load failed for want of a connection, while the
  /// app did not know it was offline, checks the connection and — reachable
  /// after all — loads again by itself. At most one such wave of automatic
  /// retries (the loads that failed together) in this window, so a backend
  /// that is down is never hammered and a load never loops.
  static const Duration readRetryGap = Duration(seconds: 15);

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
  static const double promoDivider =
      36; // free-shipping vertical divider height
  static const double searchBar = 38; // search field height
  static const double topActionTap = 40; // top-bar icon tap target
  static const double iconCircle =
      56; // category icon circle diameter (≈56–58dp)
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
  static const double dealRailCol =
      104; // Super-Deals 2-row column width (1Day dp)
  static const double dealRailH =
      460; // Super-Deals rail (2 stacked cards, fits 1-line title @1.3x)
  static const double railCardW =
      120; // Trends product-rail card width (1Day dp)
  static const double railCardH = 250; // Trends product-rail card height
  static const double flashCardW = 100; // Flash-sale tile width (1Day dp)

  // Grid column counts.
  static const int homeIconGridCols = 5; // fashion flat icon grid
  static const int subCatGridCols = 4; // sub-tab module grid (4-col)
  static const int masonryCols = 2; // For-You waterfall

  // ── Button height system ([FACT] `dimen/sui_dimen_button_*_height`) ─────────
  static const double buttonHeight =
      44; // [FACT] sui_dimen_button_height = 44dp
  static const double buttonBottom =
      40; // [FACT] sui_dimen_button_bottom_height = 40dp
  static const double buttonHeightSmall =
      36; // [FACT] sui_dimen_button_small_height = 36dp
  static const double buttonDialog =
      36; // [FACT] sui_dimen_button_dialog_height = 36dp
  static const double buttonHeightLittle =
      28; // [FACT] sui_dimen_button_little_height = 28dp
  static const double buttonHeightMini =
      24; // [FACT] sui_dimen_button_mini_height = 24dp
  static const double buttonHeightPetty =
      20; // [FACT] sui_dimen_button_petty_height = 20dp
  static const double buttonBottomMinWidth =
      100; // [FACT] bottom CTA min width = 100dp
  static const double buttonLittlePadH =
      12; // [FACT] little CTA horizontal padding = 12dp
  static const double buttonStrokeW =
      0.5; // [FACT] sui_dimen_button_stroke_width = 0.5dp

  // ── Inputs / labels ─────────────────────────────────────────────────────────
  static const double inputHeight = 44; // [FACT] sui_text_input_height = 44dp
  static const double labelStroke =
      1; // [FACT] sui_dimen_label_stroke_width = 1dp
  static const double labelStrokeBold =
      1.5; // [FACT] sui_dimen_label_stroke_width2 = 1.5dp
  static const double labelMiniHeight =
      16; // [FACT] sui_dimen_label_mini_height = 16dp
  static const double cardSelectStrokeW =
      1; // [FACT] bg_item_goods_card_corner selected hairline = 1dp

  // ── Tabs / sub-tabs ─────────────────────────────────────────────────────────
  static const double tabLayoutHeight =
      36; // [FACT] sui_info_flow_tab_layout_height = 36dp

  // ── Slider (price-range filter) ─────────────────────────────────────────────
  static const double sliderThumbRadius =
      10; // [FACT] mtrl_slider_thumb_radius = 10dp
  static const double sliderTrackHeight =
      4; // [FACT] mtrl_slider_track_height = 4dp

  // ── Dividers ────────────────────────────────────────────────────────────────
  static const double dividerThickness =
      1; // [FACT] m3_comp_divider_thickness = 1dp
  static const double dividerHairline = 0.6; // [FACT] divider = 0.6dp
  static const double hairline =
      0.5; // [FACT] #goods_detail_v_dividerline = 0.5dp

  // ── Badges ──────────────────────────────────────────────────────────────────
  static const double badgeWithText =
      16; // [FACT] mtrl_badge_with_text_size = 16dp
  static const double badgeDot = 8; // [FACT] mtrl_badge_size = 8dp (dot)
  static const double redDot = 16; // [FACT] #goods_detail_red_dot_view = 16dp

  /// Empty-state glyph diameter (bag / wishlist / coupons empty views, 72dp).
  static const double emptyGlyph = 72;

  // ── Touch targets / sheets ──────────────────────────────────────────────────
  static const double minTouchTarget =
      48; // [FACT] mtrl_min_touch_target_size = 48dp
  static const double sheetHandleWidth =
      32; // [FACT] m3_comp_sheet_bottom_docked_drag_handle_width = 32dp
  static const double sheetHandleHeight =
      4; // [FACT] m3_comp_sheet_bottom_docked_drag_handle_height = 4dp

  // ── Layout convention aliases ───────────────────────────────────────────────
  /// Standardized outer page gutter (dp). 1Day keeps a consistent ≈12dp
  /// page edge inset for top-level home sections (strips, free-shipping,
  /// masonry sliver, deal modules); in-card padding stays at 8dp.
  /// Use this alias at section call sites to kill the 8↔12 gutter drift
  /// (sizing_spacing.md #35).
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
