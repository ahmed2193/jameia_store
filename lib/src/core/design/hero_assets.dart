// GENERATED-BY-EXTRACTION — real Hero raster assets.
//
// String paths to the REAL Hero images/animations extracted from the decoded
// Hero APK (Mach UI bundles + loose APK assets), plus the vector glyphs drawn
// for this app. Grouped by screen so feature code references them by name
// (e.g. `HeroAssets.globalCartFull`) instead of raw, hash-suffixed file paths.
//
// Folders:
//   assets/images/hero/osg_home        — basket / rider glyphs
//   assets/images/hero/shop            — wishlist hearts
//   assets/images/hero/order_confirm   — address "Save as" label icons
//   assets/images/hero/mine            — profile / "Mine"
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
  // The green basket is [globalCartFull] (an empty basket: [globalCart]); the
  // delivery rider is [globalRider]. Offer-card glyphs, drawn for the "Buy
  // more, save more" sheet: a rounded tile each, colour baked in.
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

  // ── OSG home cart / global cart ─────────────────────────────────────────────
  static const String globalCart =
      '$_img/osg_home/icon_global_cart_16rkbq2.png';
  static const String globalCartFull =
      '$_img/osg_home/icon_global_cart_full_psp7nc.png';
  static const String globalRider =
      '$_img/osg_home/icon_global_rider_1iobtvo.png';

  // ── Shop / SKU detail ───────────────────────────────────────────────────────
  static const String shopRedHeart = '$_img/shop/icon_red_heart_eurbqf.png';
  static const String shopEmptyHeart =
      '$_img/shop/icon_empty_heart_1cq6pbt.png';

  // ── Order confirm ───────────────────────────────────────────────────────────
  // Address "Save as" label icons (global variants) — used by the address edit form.
  static const String labelHome =
      '$_img/order_confirm/icon_home_global_1bf0u4k.png';
  static const String labelOffice =
      '$_img/order_confirm/icon_office_global_1lsklhx.png';
  static const String labelGathering =
      '$_img/order_confirm/icon_gathering_global_g2vf0g.png';
  static const String labelOther =
      '$_img/order_confirm/icon_others_global_tz8aol.png';

  // ── Mine / profile ──────────────────────────────────────────────────────────
  static const String mineScanQrCode = '$_img/mine/scan_qrcode_w1z5l3.png';

  // ── Login / passport ────────────────────────────────────────────────────────
  static const String loginGoogle = '$_img/login/login_icon_google_1xvfrhj.png';
  static const String loginApple = '$_img/login/login_icon_apple_oi0jl5.png';
  static const String loginFacebook =
      '$_img/login/login_icon_facebook_eoiu3a.png';

  // ── Home popups / overlays (assets/images/hero/popup) ──────────────────────
  /// Centered-modal close button (coupon pop / image-text / video pop).
  static const String popupClose = '$_img/popup/icon_fall_sky_close_monzly.png';
}
