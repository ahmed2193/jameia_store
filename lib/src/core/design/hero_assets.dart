// Asset paths of the Hero app, grouped by screen so feature code references
// them by name (e.g. `HeroAssets.brandGoogle`) instead of raw file paths.
//
// Everything here is our own art (the drawn Hero SVGs, the bag, the app icon,
// the welcome-gift animation) except the official brand marks, taken as is
// from each owner's brand kit: never redrawn, tinted or recoloured.
//
// Folders:
//   assets/images/brands     — official Google / Apple marks (1x, 2x, 3x)
//   assets/images/hero/popup — the first-order welcome-gift animation
//   assets/svg/              — drawn glyphs, plates, states, the official
//                              Facebook / Instagram / X marks, Kuwait's flag
class HeroAssets {
  HeroAssets._();

  static const String _img = 'assets/images/hero';

  // ── Hero Pro dome ────────────────────────────────────────────────────────
  // The Hero shopping bag (brand green, the caped-bag mark + "hero" / "هيرو"
  // printed on it) beside an orange. 533 × 631: decode it at the size shown.
  static const String heroBag = 'assets/images/hero_bag.png';

  // ── Basket bars + the cart's deals sheet ───────────────────────────────────
  // The basket is [cartBasket] / [cartBasketFull]. Offer-card glyphs, drawn
  // for the "Buy more, save more" sheet: a rounded tile each, colour baked in.
  static const String offerDelivery = 'assets/svg/offer_delivery.svg';
  static const String offerVoucher = 'assets/svg/offer_voucher.svg';
  static const String offerGift = 'assets/svg/offer_gift.svg';

  // ── First-order free delivery (home bar + its dialog) ────────────────────
  /// A Hero rider seen from the side on a white scooter, riding towards the
  /// end edge (mirror it in RTL): white helmet, the amber cape flowing back
  /// over the green delivery box with the bag on it. Drawn for the brand-deep
  /// green bar (64 × 44); the speed lines behind it are painted, not drawn.
  static const String promoRider = 'assets/svg/promo_rider.svg';

  // ── Checkout glyphs (drawn for the Hero-style checkout, colour baked in) ──
  // The "Coupons & offers" disc of the Instant-savings card, the offer ticket
  // of the vouchers page, the express badge (19×13), and the wallet /
  // points plates (22 dp).
  static const String checkoutVoucherDisc =
      'assets/svg/checkout_voucher_disc.svg';
  static const String checkoutTicket = 'assets/svg/checkout_ticket.svg';
  static const String checkoutExpressBolt =
      'assets/svg/checkout_express_bolt.svg';
  static const String checkoutWallet = 'assets/svg/checkout_wallet.svg';
  static const String checkoutPoints = 'assets/svg/checkout_points.svg';

  // ── Brand / logo (home) ─────────────────────────────────────────────────────
  /// The Hero app icon (square: the bag in its cape on the green tile) — the
  /// store badge at the head of home, the login and about logo. 512 px (from
  /// tool/splash/render_app_icons_test.dart): decode it at the size shown.
  static const String appLogo = 'assets/launcher/app_icon_square.png';

  // ── Sign-in + About: official brand marks (never tinted or recoloured) ───
  // Drawn with `BrandMark` (core/widgets). The Google and Apple marks are
  // rasters with 2x / 3x variants (24 dp at 1x); the rest are SVGs.
  /// Google's "G" (the 2025 gradient mark), transparent.
  static const String brandGoogle = 'assets/images/brands/google_g.png';

  /// Apple's logo (black on white, from Apple's sign-in button kit).
  static const String brandApple = 'assets/images/brands/apple_logo.png';

  /// Facebook's mark: the blue circle with the white "f" (Meta's pack).
  static const String brandFacebook = 'assets/svg/brand_facebook.svg';

  /// Instagram's glyph (official, black).
  static const String brandInstagram = 'assets/svg/brand_instagram.svg';

  /// X's logo (official, black).
  static const String brandX = 'assets/svg/brand_x.svg';

  // ── Flags ────────────────────────────────────────────────────────────────
  /// Kuwait's flag (2:1, official colours). Never mirrored in RTL.
  static const String flagKuwait = 'assets/svg/flag_kw.svg';

  // ── Home popups / overlays (assets/images/hero/popup) ──────────────────────
  /// The first-order free-delivery welcome gift: the badge pops in over the
  /// ticket, once (no loop), then holds. 640 × 844, transparent, text baked
  /// in per language. The `…Still` PNGs are the held last frame, for reduced
  /// motion.
  static const String popupFirstOrderFreeDeliveryEn =
      '$_img/popup/popup_first_order_free_delivery_en.gif';
  static const String popupFirstOrderFreeDeliveryAr =
      '$_img/popup/popup_first_order_free_delivery_ar.gif';
  static const String popupFirstOrderFreeDeliveryEnStill =
      '$_img/popup/popup_first_order_free_delivery_en_still.png';
  static const String popupFirstOrderFreeDeliveryArStill =
      '$_img/popup/popup_first_order_free_delivery_ar_still.png';

  // ── Order tracking / details (docs/motion/asset_manifest.md rows 30–33) ──
  /// Delivered stage art, the "sent" mark of a review, the order-help thanks.
  static const String stateSuccess = 'assets/svg/state_success.svg';

  /// An order (or page) that is not there any more.
  static const String stateNotFound = 'assets/svg/state_not_found.svg';

  /// A product photo that is missing.
  static const String imagePlaceholder = 'assets/svg/image_placeholder.svg';

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

  // Line icons are Hero font glyphs (`HeroIcons`), never SVGs here.

  // ── Colour plates (colours baked in) ────────────────────────────────────
  /// Hero Pro crown plate (24).
  static const String proCrown = 'assets/svg/pro_crown.svg';

  /// Percent-off plate (24).
  static const String offerPercent = 'assets/svg/offer_percent.svg';

  /// The basket of the basket bars (32): empty and with produce.
  static const String cartBasket = 'assets/svg/cart_basket.svg';
  static const String cartBasketFull = 'assets/svg/cart_basket_full.svg';

  /// The address picker's pins (48 × 58, tip at 53, no shadow: the picker
  /// paints one on the ground as the pin lifts). The pin is the live map's
  /// home pin — the door the rider comes to; outside the delivery area it
  /// turns grey with a warning sign.
  static const String mapPinPicker = 'assets/svg/map_pin_picker.svg';
  static const String mapPinAway = 'assets/svg/map_pin_away.svg';

  /// Live rider map markers. The rider is seen from above, riding north (the
  /// map turns it with the road): white helmet, the Hero cape flowing over
  /// the green delivery box (48). The pins (48 × 58, shadow included): the
  /// store holds the Hero mark, home a house on the cape's amber.
  static const String mapRider = 'assets/svg/map_rider.svg';
  static const String mapStorePin = 'assets/svg/map_store_pin.svg';
  static const String mapHomePin = 'assets/svg/map_home_pin.svg';

  /// The order page's live-map card: a Hero map tile, the road from the
  /// store to home, the rider on it (120 × 88).
  static const String trackingLiveMap = 'assets/svg/tracking_live_map.svg';
}
