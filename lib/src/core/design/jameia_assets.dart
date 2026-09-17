// GENERATED-BY-EXTRACTION — real Jameia raster assets.
//
// String paths to the REAL Jameia images/animations extracted from the decoded
// Jameia APK (Mach UI bundles + loose APK assets). Grouped by screen so feature
// code references them by name (e.g. `JameiaAssets.riderMarkerMotorbike`) instead
// of raw, hash-suffixed file paths.
//
// Folders:
//   assets/images/jameia/osg_home        — global (overseas) home page
//   assets/images/jameia/home            — sailor C home page
//   assets/images/jameia/shop            — shop / SKU detail
//   assets/images/jameia/order_status    — order tracking map + progress nodes
//   assets/images/jameia/order_confirm   — checkout / order confirm
//   assets/images/jameia/mine            — profile / "Mine"
//   assets/images/jameia/login           — passport login
//   assets/animations/                  — brand loader, slides, splash lottie
class JameiaAssets {
  JameiaAssets._();

  static const String _img = 'assets/images/jameia';
  static const String _anim = 'assets/animations';

  // ── Jameia-store top (ported from jm3eia jameia_store) ──────────────────────
  // Locale-specific orange hero banner (wordmark + tagline + bag baked in; the
  // AR export is pre-mirrored). Promo-card art + the search scan-line glyph.
  static const String jameiaBannerAr = 'assets/images/jameia_banner_ar.png';
  static const String jameiaBannerEn = 'assets/images/jameia_banner_en.png';
  static const String jameiaBag = 'assets/images/market_image.png';
  static const String jameiaScooter = 'assets/images/scooter_icon.png';
  static const String jameiaScanLine = 'assets/svg/scan_line.svg';

  // ── Brand / logo (home) ─────────────────────────────────────────────────────
  static const String logo = '$_img/osg_home/logo_1g6o6ut.png';
  static const String logoWhite = '$_img/osg_home/logo_white_1sfau7x.png';
  static const String homeBg = '$_img/osg_home/home_bg_kq3v01.png';
  static const String homeHeaderDefaultBg =
      '$_img/home/home_header_default_bg_1ty0v27.png';

  // ── Home placeholders (1:1 / 4:3 / 16:9 / kingkong / banners) ───────────────
  static const String placeholder1x1 =
      '$_img/home/icon_placeholder_1_1_1gujzic.png';
  static const String placeholder4x3 =
      '$_img/home/icon_placeholder_4_3_1ed7d2y.png';
  static const String placeholder16x9 =
      '$_img/home/icon_placeholder_16_9_1sxn8a4.png';
  static const String placeholderColor4x3 =
      '$_img/home/icon_placeholder_color_4_3_y7dtst.png';
  static const String jameiaPlaceholder =
      '$_img/home/jameia_placeholder_1g3a941.png';
  static const String kingkongPlaceholder =
      '$_img/home/kingkong_placeholder_new_1iqp0ao.png';
  static const String verticalBannerPlaceholder =
      '$_img/home/vertical_banner_placeholder_wakeeb.png';
  static const String homeEmpty = '$_img/home/empty_1dbhqkz.png';
  static const String homeEmptyList = '$_img/home/empty_list_1gqvy22.png';
  static const String homeGuideNotService =
      '$_img/home/guide_not_service_vf8g9z.png';
  static const String promotionBubble =
      '$_img/home/promotion-bubble_1vroin.png';

  // ── OSG home cart / global cart ─────────────────────────────────────────────
  static const String globalCart =
      '$_img/osg_home/icon_global_cart_16rkbq2.png';
  static const String globalCartFull =
      '$_img/osg_home/icon_global_cart_full_psp7nc.png';
  static const String cartButtonAdd =
      '$_img/osg_home/icon_cart_button_add_vrxhu7.png';
  static const String cartButtonAddFirst =
      '$_img/osg_home/icon_cart_button_add_first_1tue6ic.png';
  static const String cartButtonDec =
      '$_img/osg_home/icon_cart_button_dec_15akn5.png';
  static const String cartButtonDel =
      '$_img/osg_home/icon_cart_button_del_39s7z1.png';
  static const String cartOpLoadingGif =
      '$_img/osg_home/icon_cart_op_loading_1nw15pw.gif';
  static const String globalRider =
      '$_img/osg_home/icon_global_rider_1iobtvo.png';
  static const String userLocationIcon =
      '$_img/osg_home/user_location_icon_sha4nv.png';
  static const String locationIcon = '$_img/osg_home/icon_location_1jjfl86.png';
  static const String locationIconWhite =
      '$_img/osg_home/icon_location_white_lo5bl0.png';
  static const String searchBlack =
      '$_img/osg_home/icon_search_black_tzhqp8.png';

  /// Free-delivery progress bar frames (0..10) on the OSG home cart strip.
  static const List<String> cartProgress = <String>[
    '$_img/osg_home/cart_progress_0_12aj5a8.png',
    '$_img/osg_home/cart_progress_1_1em6g2i.png',
    '$_img/osg_home/cart_progress_2_yzjdax.png',
    '$_img/osg_home/cart_progress_3_10dl7x9.png',
    '$_img/osg_home/cart_progress_4_dd0c07.png',
    '$_img/osg_home/cart_progress_5_zesgs9.png',
    '$_img/osg_home/cart_progress_6_zesgs9.png',
    '$_img/osg_home/cart_progress_7_147gvcv.png',
    '$_img/osg_home/cart_progress_8_vyfc1g.png',
    '$_img/osg_home/cart_progress_9_xthwzx.png',
    '$_img/osg_home/cart_progress_10_uxl2pw.png',
  ];

  // ── Shop / SKU detail ───────────────────────────────────────────────────────
  static const String shopDefaultSpu1x1 =
      '$_img/shop/default_spu_img_1_1_1unmp9b.png';
  static const String shopDefault1x1 = '$_img/shop/default_1_1_58115r.png';
  static const String shopDefault1x1Color =
      '$_img/shop/default_1_1_color_v5k4a1.png';
  static const String shopEmpty = '$_img/shop/empty_shop_1nv21a8.png';
  static const String shopEmptyList = '$_img/shop/empty_list_1gqvy22.png';
  static const String shopEmptySearchList =
      '$_img/shop/empty_search-list_1dbhqkz.png';
  static const String shopStarEmpty = '$_img/shop/shop_star_empty_1hpivb8.png';
  static const String shopLoadingGif = '$_img/shop/loading_u6zbft.gif';
  static const String cartDelivery =
      '$_img/shop/icon_cart_delivery_3.0_grca0k.png';
  static const String cartPickup =
      '$_img/shop/icon_cart_pickup_3.0_14bz7ti.png';
  static const String shopShare = '$_img/shop/icon_share_1j0hry7.png';
  static const String shopSearch = '$_img/shop/icon_search_1e1kp49.png';
  static const String shopRedHeart = '$_img/shop/icon_red_heart_eurbqf.png';
  static const String shopEmptyHeart =
      '$_img/shop/icon_empty_heart_1cq6pbt.png';
  static const String spoonForkIcon = '$_img/shop/spoon_fork_icon_qnoj8e.png';
  static const String promiseRuleLogo =
      '$_img/shop/promise_rule_logo_v3_blxovo.png';
  // Multi-SKU modal controls (real add/dec/close/checkbox PNGs).
  static const String skuAdd = '$_img/shop/icon_multi_sku_add_s44s1p.png';
  static const String skuDec = '$_img/shop/icon_multi_sku_dec_zkcdff.png';
  static const String skuDecDisabled =
      '$_img/shop/icon_multi_sku_dec_unable_1wu4w77.png';
  static const String skuClose = '$_img/shop/multi_sku_close_icon_1icnfhl.png';
  static const String skuGroupSelected =
      '$_img/shop/icon_multi_group_sku_selected_able_7m9h6g.png';
  static const String skuGroupUnselected =
      '$_img/shop/icon_multi_group_sku_unselected_able_thjjf6.png';

  // ── Order status: rider / car markers (the high-value tracking assets) ──────
  static const String riderMarkerMotorbike =
      '$_img/order_status/rider_marker_motorbike_1kc5y5n.png';
  static const String riderMarkerCar =
      '$_img/order_status/rider_marker_car_1445mek.png';
  static const String deliveryDriver =
      '$_img/order_status/delivery_driver_dextxw.webp';
  static const String deliveryDriverCar =
      '$_img/order_status/delivery_driver_car_135mpjp.webp';
  static const String motoEmptyMarker =
      '$_img/order_status/moto_empty_icon_marker_jlw5tl.png';
  static const String shopMarker =
      '$_img/order_status/shop_right_icon_marker_niq099.png';
  static const String userMarker =
      '$_img/order_status/user_right_icon_marker_xllkhy.png';
  static const String pickupUserMarker =
      '$_img/order_status/pickup_user_marker_eg0t6f.png';
  static const String deliveryUserMarker =
      '$_img/order_status/delivery_user_marker_1v450uw.png';
  static const String mapMarkerShadow =
      '$_img/order_status/map_marker_ellipse_shadow_lnpzwr.png';
  static const String navigationIcon =
      '$_img/order_status/navigation_1enij5u.png';

  /// 24-frame heading-rotated car marker (webp), key = heading degrees (0..345 step 15).
  static String carMarkerForHeading(int deg) {
    const map = <int, String>{
      0: 'car_n_0_9ciqmz.webp',
      15: 'car_n_15_gxyc7g.webp',
      30: 'car_n_30_i8qj44.webp',
      45: 'car_n_45_6kbohw.webp',
      60: 'car_n_60_f23nzi.webp',
      75: 'car_n_75_1ydfpab.webp',
      90: 'car_n_90_1ub0f9y.webp',
      105: 'car_n_105_1ccfhgh.webp',
      120: 'car_n_120_169unuj.webp',
      135: 'car_n_135_1fck97j.webp',
      150: 'car_n_150_177s22c.webp',
      165: 'car_n_165_qpvxl.webp',
      180: 'car_n_180_14qivad.webp',
      195: 'car_n_195_11c44ko.webp',
      210: 'car_n_210_1pg3z0g.webp',
      225: 'car_n_225_1ncanro.webp',
      240: 'car_n_240_1y5h5qg.webp',
      255: 'car_n_255_t3y7rk.webp',
      270: 'car_n_270_13s4bje.webp',
      285: 'car_n_285_nmlha2.webp',
      300: 'car_n_300_13zygux.webp',
      315: 'car_n_315_hsaxpj.webp',
      330: 'car_n_330_1ral958.webp',
      345: 'car_n_345_1aiu2wv.webp',
    };
    final snapped = ((deg % 360) / 15).round() * 15 % 360;
    return '$_img/order_status/${map[snapped] ?? map[0]}';
  }

  /// 24-frame heading-rotated user/destination map pin (png), step 15°.
  static String mapPinForHeading(int deg) {
    const map = <int, String>{
      0: 'map_marker_icon_n_0_xvow9p.png',
      15: 'map_marker_icon_n_15_ka3y4t.png',
      30: 'map_marker_icon_n_30_1dhjx8p.png',
      45: 'map_marker_icon_n_45_m5icgm.png',
      60: 'map_marker_icon_n_60_ykye9n.png',
      75: 'map_marker_icon_n_75_1dv0div.png',
      90: 'map_marker_icon_n_90_1g2imyj.png',
      105: 'map_marker_icon_n_105_948tvl.png',
      120: 'map_marker_icon_n_120_166uvl4.png',
      135: 'map_marker_icon_n_135_ygq9my.png',
      150: 'map_marker_icon_n_150_1hmk9zw.png',
      165: 'map_marker_icon_n_165_zdrlci.png',
      180: 'map_marker_icon_n_180_1nug2un.png',
      195: 'map_marker_icon_n_195_1udzchk.png',
      210: 'map_marker_icon_n_210_dke74.png',
      225: 'map_marker_icon_n_225_16ffyzv.png',
      240: 'map_marker_icon_n_240_s8nflb.png',
      255: 'map_marker_icon_n_255_zzvmcn.png',
      270: 'map_marker_icon_n_270_nwjbpc.png',
      285: 'map_marker_icon_n_285_1qv4op4.png',
      300: 'map_marker_icon_n_300_do91s2.png',
      315: 'map_marker_icon_n_315_11id1zs.png',
      330: 'map_marker_icon_n_330_1p7kz01.png',
      345: 'map_marker_icon_n_345_s7pab3.png',
    };
    final snapped = ((deg % 360) / 15).round() * 15 % 360;
    return '$_img/order_status/${map[snapped] ?? map[0]}';
  }

  // ── Order status: progress timeline nodes (confirm → prepare → pickup → car → delivery) ──
  static const String progressNodeConfirm =
      '$_img/order_status/progress_node_confirm_vhnqkf.png';
  static const String progressNodePrepare =
      '$_img/order_status/progress_node_prepare_19qunac.png';
  static const String progressNodeMotor =
      '$_img/order_status/progress_node_motor_1ckdh5s.png';
  static const String progressNodeCar =
      '$_img/order_status/progress_node_car_1cc1y15.png';
  static const String progressNodeDelivery =
      '$_img/order_status/progress_node_delivery_1gbncg6.png';

  // tech (highlight/normal) variants of the same timeline
  static const String techNodeConfirm =
      '$_img/order_status/tech_progress_node_confirm_13yjszc.png';
  static const String techNodePrepareHighlight =
      '$_img/order_status/tech_progress_node_prepare_highlight_ivwata.png';
  static const String techNodePrepareNormal =
      '$_img/order_status/tech_progress_node_prepare_normal_1j4cnp.png';
  static const String techNodePickupHighlight =
      '$_img/order_status/tech_progress_node_pickup_highlight_4c0dq2.png';
  static const String techNodePickupNormal =
      '$_img/order_status/tech_progress_node_pickup_normal_ybzevm.png';
  static const String techNodeMotorHighlight =
      '$_img/order_status/tech_progress_node_motor_highlight_1eqxj6r.png';
  static const String techNodeMotorNormal =
      '$_img/order_status/tech_progress_node_motor_normal_vbbyjx.png';
  static const String techNodeCarHighlight =
      '$_img/order_status/tech_progress_node_car_highlight_157109b.png';
  static const String techNodeCarNormal =
      '$_img/order_status/tech_progress_node_car_normal_188yn4g.png';
  static const String techNodeDeliveryHighlight =
      '$_img/order_status/tech_progress_node_delivery_highlight_1h7ty.png';
  static const String techNodeDeliveryNormal =
      '$_img/order_status/tech_progress_node_delivery_normal_infqo6.png';

  // ── Order status: delivery code / package / completion ──────────────────────
  static const String deliveryPackageLtr =
      '$_img/order_status/delivery_package_ltr_t71clo.webp';
  static const String deliveryPackageRtl =
      '$_img/order_status/delivery_package_rtl_bhpmhq.webp';
  static const String deliveryPackageShadow =
      '$_img/order_status/delivery_package_shadow_1tu1dzg.png';
  static const String deliveryCodePopupBg =
      '$_img/order_status/delivery_code_popup_bg_1j051en.webp';
  static const String deliveryCodeIcon =
      '$_img/order_status/delivery_code_icon_in3fn9.webp';
  static const String deliveryCompletedLight =
      '$_img/order_status/delivery_completed_light_13tx75.png';
  static const String deliveryCompletedSlider =
      '$_img/order_status/delivery_completed_slider_6mwsna.webp';
  static const String foodPlaceholder1x1 =
      '$_img/order_status/food_placeholder_1_1_uqlolt.png';
  static const String riderCall =
      '$_img/order_status/icon_rider_call_vhpm1v.png';
  static const String riderIm = '$_img/order_status/icon_rider_im_bm20un.png';
  static const String onTimePromiseIcon =
      '$_img/order_status/ontime_promise_icon_u1x63p.png';
  static const String onTimePromiseLogo =
      '$_img/order_status/ontime_promise_logo_544iy5.png';
  // Refund-request glyphs (shipped under order_status/).
  static const String refundReasonSelected =
      '$_img/order_status/order_refund_reason_selected_9x37ff.png';
  static const String refundReasonUnselected =
      '$_img/order_status/order_refund_gary_unselected_qbobql.png';
  static const String refundMethodSelected =
      '$_img/order_status/refundMethodPreferenceTip-icon-selected_jbm67s.png';
  static const String refundMethodUnselected =
      '$_img/order_status/refundMethodPreferenceTip-icon-unselected_1h8vsjt.png';

  // ── Order confirm / checkout ────────────────────────────────────────────────
  static const String applePay = '$_img/order_confirm/apple_pay_1jd21gu.png';
  static const String googlePay = '$_img/order_confirm/google_pay_b5l23y.png';
  static const String confirmLoadingGif =
      '$_img/order_confirm/loading_u6zbft.gif';
  static const String confirmLoadingThreeCirclesGif =
      '$_img/order_confirm/loading-three-circles_fet7vw.gif';
  static const String iconHome = '$_img/order_confirm/icon_home_1h15tp2.png';
  static const String iconOffice =
      '$_img/order_confirm/icon_office_15ummc2.png';
  static const String iconOther = '$_img/order_confirm/icon_others_1y3e5bc.png';
  static const String iconGathering =
      '$_img/order_confirm/icon_gathering_1xnkhaq.png';
  static const String iconClock = '$_img/order_confirm/icon_clock_fc3d0r.png';
  static const String addrLogoDefault =
      '$_img/order_confirm/addr_logo_default_43tf62.png';
  // Address "Save as" label icons (global variants) — used by the address edit form.
  static const String labelHome =
      '$_img/order_confirm/icon_home_global_1bf0u4k.png';
  static const String labelOffice =
      '$_img/order_confirm/icon_office_global_1lsklhx.png';
  static const String labelGathering =
      '$_img/order_confirm/icon_gathering_global_g2vf0g.png';
  static const String labelFaceToDelivery =
      '$_img/order_confirm/face_to_delivery_confirm_global_muyj0a.png';
  static const String labelAssignedPlace =
      '$_img/order_confirm/assigned_place_confirm_global_1l9oxn7.png';
  static const String labelOther =
      '$_img/order_confirm/icon_others_global_tz8aol.png';
  static const String switchOn =
      '$_img/order_confirm/icon_switch_on_global_v2_gbqlzm.png';
  static const String switchOff =
      '$_img/order_confirm/icon_switch_off_global_v2_1pl6jhx.png';
  static const String tablewareIcon =
      '$_img/order_confirm/tableware_icon_global_1ptv69v.png';
  static const String couponModalBg =
      '$_img/order_confirm/koupon_modal_bg_1ocdx5s.png';
  static const String couponIcon =
      '$_img/order_confirm/koupon_icon_14i7dv5.png';
  static const String iconPunctual =
      '$_img/order_confirm/icon_punctual_1hrpdxh.png';
  static const String iconTips = '$_img/order_confirm/icon_tips_lphtk1.png';
  static const String dropOffSelected =
      '$_img/order_confirm/drop_off_option_selected_1zm6gs.png';
  static const String dropOffUnselected =
      '$_img/order_confirm/drop_off_option_unselected_1m4vrwk.png';
  static const String secondaryConfirmIcon =
      '$_img/order_confirm/ic_secondary_confirm_icon_om0aen.png';

  // ── Mine / profile ──────────────────────────────────────────────────────────
  static const String mineBg = '$_img/mine/mine_bg_new_1j3nd58.png';
  static const String mineHeaderBg = '$_img/mine/header_bg_global_5lx8l5.png';
  static const String mineBannerBg = '$_img/mine/banner_bg_global_1rz2quf.png';
  static const String mineScanQrCode = '$_img/mine/scan_qrcode_w1z5l3.png';
  static const String mineArrowCell = '$_img/mine/mine_arrow_cell_1pnfygk.png';
  static const String mineChecked = '$_img/mine/checked_v2_1wephbl.png';
  static const String mineUnchecked = '$_img/mine/unChecked_v2_1f9ta1p.png';
  // Single-select check glyphs (16x16) — region/list pickers.
  static const String checkIcon = '$_img/mine/check_1712k7m.png';
  static const String checkedIcon = '$_img/mine/checked_1zm6gs.png';

  // ── Login / passport ────────────────────────────────────────────────────────
  static const String loginGoogle = '$_img/login/login_icon_google_1xvfrhj.png';
  static const String loginApple = '$_img/login/login_icon_apple_oi0jl5.png';
  static const String loginFacebook =
      '$_img/login/login_icon_facebook_eoiu3a.png';
  static const String loginEmail = '$_img/login/login_icon_email_farsi9.png';
  static const String loginNavBack = '$_img/login/navBack_m3mavt.png';
  static const String loginNavClose = '$_img/login/navClose_1vbpqwr.png';
  static const String loginNavHelper = '$_img/login/navHelper_zihwor.png';
  static const String loginArrowDown = '$_img/login/arrowDown_1cb8es3.png';

  // ── Order review (real Jameia star + like/unlike two-state PNGs) ─────────────
  static const String _review = '$_img/review';
  static const String reviewStarNormal =
      '$_review/icon_review_res_star_normal_w3qzzt.png';
  static const String reviewLikeLight =
      '$_review/icon_review_like_light_18r0cl2.png';
  static const String reviewLikeGrey =
      '$_review/icon_review_like_grey_z6jsrx.png';
  static const String reviewUnlikeLight =
      '$_review/icon_review_unlike_light_gq4b66.png';
  static const String reviewUnlikeGrey =
      '$_review/icon_review_unlike_grey_8k4bo0.png';

  // ── Home top-ups (address bar v3 / searchbar v3 / shop-banner rail / tabs) ──
  static const String searchbarIconV3 =
      '$_img/home/searchbar_sub_icon_v3_1g8boz5.png';
  static const String addressLogoV3 =
      '$_img/home/home_address_logo_v3_1reojpu.png';
  static const String addressLocationV3 =
      '$_img/home/home_address_location_v3_1rl6qix.png';
  static const String addressDownV3 =
      '$_img/home/home_address_down_v3_1iu4qr9.png';
  static const String shopRateStar =
      '$_img/home/icon_shop_rate_star_s6x9si.png';
  static const String shopBannerTime = '$_img/home/icon_time_16a975b.png';
  static const String riderPrice = '$_img/home/rider-price_sgl9kx.png';
  static const String sectionTitleArrow =
      '$_img/home/home_special_card_title_arrow_1a7lv7e.png';
  static const String bannerShowmoreArrow =
      '$_img/home/icon_banner_showmore_arrow_1mrpnza.png';
  static const String indicatorSelected =
      '$_img/home/indicator-selected_2fe7l6.png';
  // Channel / sticky / anchor tabs
  static const String tabNormal = '$_img/home/tab_normal_m9itk9.png';
  static const String tabSelected = '$_img/home/tab_selected_2109o.png';
  static const String tabSelectedFirst =
      '$_img/home/tab_selected_first_1qx4983.png';
  static const String tabSelectedLast =
      '$_img/home/tab_selected_last_1a916xr.png';
  static const String tabSelectedLeft =
      '$_img/home/tab_selected_left_kw45y6.png';
  static const String tabSelectedRight =
      '$_img/home/tab_selected_right_h2ns0v.png';
  static const String sceneItemSelected =
      '$_img/home/scence_item_selected_17d664q.png';

  // ── Home popups / overlays (assets/images/jameia/popup) ──────────────────────
  static const String _popup = '$_img/popup';

  /// Centered-modal close button (coupon pop / image-text / video pop).
  static const String popupClose = '$_popup/icon_fall_sky_close_monzly.png';

  /// Coupon-popup header banner image.
  static const String popupCouponHeader = '$_popup/short_whuy9.png';

  /// popup_list_main modal close button.
  static const String popupListClose =
      '$_popup/pupup_list_close_icon_1p75ijp.png';

  /// Bottom-overlay (re-engagement bubble) background + close.
  static const String overlayBgDefault =
      '$_popup/sl_overlay_bg_default_2mpqr4.png';
  static const String overlayClose = '$_popup/sl_overlay_close_4bbzlj.png';

  /// New-user carousel-banner card background.
  static const String newbornCardBg = '$_popup/new_one_bg_w8w70p.png';

  /// Vertical-banner active page indicator + generic banner placeholder.
  static const String popupIndicatorSelected =
      '$_popup/indicator-selected_2fe7l6.png';
  static const String popupBannerPlaceholder =
      '$_popup/placeholder_1r6bh1v.png';
  static const String popupVerticalPlaceholder =
      '$_popup/vertical_banner_placeholder_wakeeb.png';
  static const String popupPercent = '$_popup/percent_1tub46i.png';
  static const String popupDot = '$_popup/dot_yta720.png';
  static const String popupPromotionBubble =
      '$_popup/promotion-bubble_1vroin.png';
  static const String popupGoldenArrowUp =
      '$_popup/golden-shopcard-arrow-up_16ewjfe.png';
  static const String popupGoldenArrowDown =
      '$_popup/golden-shopcard-arrow-down_1er740s.png';

  // ── Marketing: invite friends (assets/images/jameia/marketing) ───────────────
  static const String _mkt = '$_img/marketing';
  static const String inviteShare = '$_mkt/share_vd7k7c.png';
  static const String inviteShareWhite = '$_mkt/share-white_93725r.png';
  static const String inviteCopyCode = '$_mkt/copy-code_1q4gbme.png';
  static const String inviteCopy = '$_mkt/copy_1jyfzp4.png';
  static const String inviteSearch = '$_mkt/search_113yd5r.png';
  static const String inviteRewardCommon = '$_mkt/reward-common_1h1cnt.png';
  static const String inviteRewardSingle = '$_mkt/reward-single_8oajdp.png';
  static const String inviteRewardDetailBg =
      '$_mkt/reward-detail-bg_qatf55.png';
  static const String inviteRewardDetailClose =
      '$_mkt/reward-detail-close_11wckyq.png';
  static const String inviteRewardDetailOpen =
      '$_mkt/reward-detail-open_1wxh1so.png';
  static const String inviteRewardOver = '$_mkt/reward-over_1hja5w.png';
  static const String inviteRewards = '$_mkt/rewards_16ymb9t.png';
  static const String inviteRewardSingleBtn =
      '$_mkt/reward-single-btn_zgujex.png';
  static const String inviteQrCode = '$_mkt/qr-code_1e02zal.png';
  static const String inviteRewardCommonQr =
      '$_mkt/reward-common-QR_19qwy4i.png';
  static const String inviteWorkInvite = '$_mkt/work-invite_19zsm9b.png';
  static const String inviteWorkOrder = '$_mkt/work-order_uvcwuj.png';
  static const String inviteWorkReward = '$_mkt/work-reward_18nah23.png';
  static const String inviteWorkArrow = '$_mkt/work-arrow_1rc0ncv.png';
  static const String inviteRibbon = '$_mkt/ribbon_1c63v8i.png';
  static const String inviteLockNodeBg = '$_mkt/lock-node-bg_123hjox.png';
  static const String invitePopupBg = '$_mkt/popup-background_1xkts09.webp';
  static const String inviteRightArrow = '$_mkt/right-arrow_1t4vxyl.png';
  static const String invitePageBack = '$_mkt/page_back_1sdjz3z.png';
  static const String inviteStar = '$_mkt/star_yzm9ti.png';
  static const String invitePersonIcon = '$_mkt/personIcon_sd2uk1.png';
  static const String inviteInfoIcon = '$_mkt/infoIcon_1085usb.png';
  static const String inviteCouponIcon = '$_mkt/coupon-icon_44i639.png';
  static const String inviteAwardImg = '$_mkt/award-img_1j3e6z6.png';
  static const String inviteActInvalid = '$_mkt/actInvalid_116qlnk.webp';
  static const String inviteNoLogin = '$_mkt/noLogin_1lj8o2u.webp';

  // ── Marketing: punctual / on-time promise ───────────────────────────────────
  static const String punctualLogo = '$_mkt/promise_rule_logo_17eu7pr.png';
  static const String punctualCoupon = '$_mkt/promise_rule_coupon_11rklc2.png';
  static const String punctualBackground =
      '$_mkt/punctual-background_wioyik.png';
  static const String punctualPageBack = '$_mkt/punctual_page_back_1b8vp75.png';
  static const String punctualFaqsIcon = '$_mkt/faqs-icon_1vz042.png';
  static const String punctualLineImage = '$_mkt/line-image_f0y4d9.png';

  // ── Animations ──────────────────────────────────────────────────────────────
  /// Official Jameia brand loading animation (GIF, ~2.2 MB).
  static const String brandLoadingGif = '$_anim/jameia_design_loading.gif';

  /// New-user onboarding slide (GIF).
  static const String newUserSlideGif = '$_anim/new_user_slide.gif';

  /// Splash screen Lottie (JSON) — requires the `lottie` package.
  static const String splashLottie = '$_anim/splash_lottie_default.json';

  /// Invite-rewards shine / shimmer (LTR + RTL).
  static const String shineGif = '$_anim/shine_aiqpe5.gif';
  static const String shineRtlGif = '$_anim/shine-rtl_111da1b.gif';
}
