// GENERATED-BY-EXTRACTION — real Hero raster assets.
//
// String paths to the REAL Hero images/animations extracted from the decoded
// Hero APK (Mach UI bundles + loose APK assets), plus the vector glyphs drawn
// for this app. Grouped by screen so feature code references them by name
// (e.g. `HeroAssets.globalRider`) instead of raw, hash-suffixed file paths.
//
// Folders:
//   assets/images/hero/osg_home        — the delivery rider
//   assets/images/hero/login           — passport login
//   assets/images/hero/popup           — modal close button
//   assets/svg/                          — offer + checkout glyphs
class HeroAssets {
  HeroAssets._();

  static const String _img = 'assets/images/hero';

  // ── Hero-store top (ported from the source store screen) ───────────────
  // Promo-card art (the shopping bag).
  static const String heroBag = 'assets/images/market_image.png';

  // ── Basket bars + the cart's deals sheet ───────────────────────────────────
  // The basket is [cartBasket] / [cartBasketFull]; the delivery rider is
  // [globalRider]. Offer-card glyphs, drawn for the "Buy more, save more"
  // sheet: a rounded tile each, colour baked in.
  static const String offerDelivery = 'assets/svg/offer_delivery.svg';
  static const String offerVoucher = 'assets/svg/offer_voucher.svg';
  static const String offerGift = 'assets/svg/offer_gift.svg';

  // ── Checkout glyphs (drawn for the Hero-style checkout, colour baked in) ──
  // The "Coupons & offers" disc of the Instant-savings card, the offer ticket
  // of the vouchers page, the "Enter coupon code" tag, the express badge
  // (19×13), and the payment / points plates (22 dp).
  static const String checkoutVoucherDisc =
      'assets/svg/checkout_voucher_disc.svg';
  static const String checkoutTicket = 'assets/svg/checkout_ticket.svg';
  static const String checkoutCodeTag = 'assets/svg/checkout_code_tag.svg';
  static const String checkoutExpressBolt =
      'assets/svg/checkout_express_bolt.svg';
  static const String checkoutWallet = 'assets/svg/checkout_wallet.svg';
  static const String checkoutCash = 'assets/svg/checkout_cash.svg';
  static const String checkoutPoints = 'assets/svg/checkout_points.svg';

  // ── Brand / logo (home) ─────────────────────────────────────────────────────
  /// The Hero app icon (square: the bag in its cape on the green tile) — the
  /// store badge at the head of home, the login and about logo. 512 px (from
  /// tool/splash/render_app_icons_test.dart): decode it at the size shown.
  static const String appLogo = 'assets/launcher/app_icon_square.png';

  // ── OSG home: the delivery rider (the cart's delivery note) ─────────────────
  static const String globalRider =
      '$_img/osg_home/icon_global_rider_1iobtvo.png';

  // ── Login / passport ────────────────────────────────────────────────────────
  static const String loginGoogle = '$_img/login/login_icon_google_1xvfrhj.png';
  static const String loginApple = '$_img/login/login_icon_apple_oi0jl5.png';
  static const String loginFacebook =
      '$_img/login/login_icon_facebook_eoiu3a.png';

  // ── Home popups / overlays (assets/images/hero/popup) ──────────────────────
  /// Centered-modal close button (coupon pop / image-text / video pop).
  static const String popupClose = '$_img/popup/icon_fall_sky_close_monzly.png';

  // ── Order tracking / details (docs/motion/asset_manifest.md rows 30–33) ──
  /// Delivered stage art, the "sent" mark of a review, the order-help thanks.
  static const String stateSuccess = 'assets/svg/state_success.svg';

  /// An order (or page) that is not there any more.
  static const String stateNotFound = 'assets/svg/state_not_found.svg';

  /// "Paid" / "added" confirmations (small check plate).
  static const String statusSuccess = 'assets/svg/status_success.svg';

  /// "Needs the internet" (the offline snack bar tone glyph).
  static const String statusOffline = 'assets/svg/status_offline.svg';

  /// The delivery-time row (ASAP or a booked window).
  static const String sharedClock = 'assets/svg/shared_clock.svg';

  /// A product photo that is missing.
  static const String imagePlaceholder = 'assets/svg/image_placeholder.svg';

  /// Address label glyphs (home / office / gathering / other).
  static const String addressLabelHome = 'assets/svg/address_label_home.svg';
  static const String addressLabelOffice =
      'assets/svg/address_label_office.svg';
  static const String addressLabelGathering =
      'assets/svg/address_label_gathering.svg';
  static const String addressLabelOther = 'assets/svg/address_label_other.svg';

  // ── Screen states (docs/motion/asset_manifest.md "Per-screen decisions") ──
  // 160×120 plates: an 88 dp disc (centre 80, 58) over a soft floor shadow,
  // drawn by `StateArt`.
  /// A load that failed (the error + retry state).
  static const String stateError = 'assets/svg/state_error.svg';

  /// No connection and nothing saved to show.
  static const String stateOffline = 'assets/svg/state_offline.svg';

  /// A customer route asked for sign-in.
  static const String stateSignedOut = 'assets/svg/state_signed_out.svg';

  /// A search that matched nothing.
  static const String stateSearchEmpty = 'assets/svg/state_search_empty.svg';

  /// A service the store does not run right now (programme, assistant, Pro).
  static const String stateUnavailable = 'assets/svg/state_unavailable.svg';

  /// Empty shelves: no products, brands, categories or recipes.
  static const String emptyShelf = 'assets/svg/empty_shelf.svg';

  /// No saved address yet.
  static const String emptyAddresses = 'assets/svg/empty_addresses.svg';

  /// A wallet / points history with no line yet.
  static const String emptyLedger = 'assets/svg/empty_ledger.svg';

  /// An empty inbox.
  static const String emptyNotifications = 'assets/svg/empty_notifications.svg';

  /// No offer / coupon to show.
  static const String emptyCoupons = 'assets/svg/empty_coupons.svg';

  /// An empty basket.
  static const String emptyBasket = 'assets/svg/empty_basket.svg';

  /// Pro welcome moment (160 × 120): the Pro hero and the welcome sheet.
  static const String proWelcome = 'assets/svg/pro_welcome.svg';

  /// "The rider asks for this code at the door" (160 × 120). Directional:
  /// draw it with `matchTextDirection: true`.
  static const String deliveryCodeHandover =
      'assets/svg/delivery_code_handover.svg';

  // ── Assistant props (96 dp, next to the painted mascot) ─────────────────
  /// A "nothing said yet" bubble whose tail points at the mascot.
  /// Directional (`matchTextDirection: true`).
  static const String assistantPropBubble =
      'assets/svg/assistant_prop_bubble.svg';

  /// "Allow the microphone" (mic + lock badge).
  static const String assistantPropMic = 'assets/svg/assistant_prop_mic.svg';

  /// A person from the team reaching toward the mascot. Directional
  /// (`matchTextDirection: true`).
  static const String assistantPropHandoff =
      'assets/svg/assistant_prop_handoff.svg';

  /// The hold → slide-up-to-lock hint of the voice button (64 dp).
  static const String assistantHoldToTalk =
      'assets/svg/assistant_hold_to_talk.svg';

  // ── Mono line icons (24 dp, `#111827`: tint with `HeroSvgGlyph.mono`) ───
  /// The account person (Mine tab, guest avatar, servings).
  static const String tabAccount = 'assets/svg/tab_account.svg';

  /// The assistant (mascot gumdrop + sparkle).
  static const String assistantAi = 'assets/svg/assistant_ai.svg';

  /// Recipes / meals (a pot).
  static const String recipePot = 'assets/svg/recipe_pot.svg';

  /// "Choose options" (three jar sizes).
  static const String productOptions = 'assets/svg/product_options.svg';

  /// The "All" entry of the category rail and chips.
  static const String categoryAll = 'assets/svg/category_all.svg';

  /// A reward tier medal (48 dp; tint per tier).
  static const String rewardsBadge = 'assets/svg/rewards_badge.svg';

  // ── Colour plates (colours baked in) ────────────────────────────────────
  /// Hero Pro crown plate (24).
  static const String proCrown = 'assets/svg/pro_crown.svg';

  /// Percent-off plate (24).
  static const String offerPercent = 'assets/svg/offer_percent.svg';

  /// The basket of the basket bars (32): empty and with produce.
  static const String cartBasket = 'assets/svg/cart_basket.svg';
  static const String cartBasketFull = 'assets/svg/cart_basket_full.svg';

  /// The address-map pin (40 × 48, no shadow: the widget paints it).
  static const String mapPin = 'assets/svg/map_pin.svg';
}
