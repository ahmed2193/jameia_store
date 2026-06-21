/// Centralized API path constants. Every `RemoteDataSource` references paths
/// from here so a backend route rename is a single edit (mirrors the
/// reference's `EndPoints`).
class EndPoints {
  EndPoints._();

  /// KeeTa REST base URL.
  static const String baseUrl = 'https://fooddelivery.mykeeta.com';

  // --- Auth -------------------------------------------------------------------
  static const String emailLogin = '/api/emaillogin/v1';

  // --- Home -------------------------------------------------------------------
  static const String homePageInfo = '/api/v2/homePage/homePageInfo';
  static const String kingKongPage = '/v1/category/kingKongPage';

  // --- Search -----------------------------------------------------------------
  static const String searchGlobalPage = '/v1/search/globalpage';
  static const String searchSuggest = '/v1/search/suggest';
  static const String searchHotWord = '/v1/search/searchHotWord';

  // --- Shop -------------------------------------------------------------------
  static const String shopInfo = '/v1/shop/shopInfo';
  static const String shopProductList = '/v1/shop/productList';
  static const String shopProductSpecifics = '/v1/shop/productSpecifics';

  // --- Cart -------------------------------------------------------------------
  static const String cartInfo = '/v1/shoppingcart/userCartInfo';
  static const String cartCalculatePrice = '/v1/shoppingcart/calculatePrice';

  // --- Order ------------------------------------------------------------------
  static const String orderPreview = '/v1/order/preview';
  static const String orderSubmit = '/v1/order/submit';
  static const String orderDetail = '/v1/order/detail';
  static const String orderStatus = '/v1/order/status';
  static const String orderList = '/v1/order/list';
  static const String orderCancel = '/v1/order/cancel';
  static const String orderRefund = '/v1/order/refund';

  // --- Address ----------------------------------------------------------------
  static const String addressSaveOrUpdate = '/v1/address/user/saveOrUpdate';
  static const String addressGetAll = '/v1/address/user/getAllAddressInUserV2';

  // --- Mine (user page) -------------------------------------------------------
  static const String myPageModule = '/v1/userinfo/getMyPageModule';

  // --- Coupons ----------------------------------------------------------------
  static const String couponUseLinkUrl = '/v1/coupon/mycoupon/getUseCouponLinkUrl';
}
