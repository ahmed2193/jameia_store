/// Route-path registry for the Jameia consumer clone (GoRouter locations — every
/// path starts with '/'). Mirrors Jameia's Mach Pro page inventory (one route
/// per real screen). Arguments travel as GoRouter `extra`.
class Routes {
  Routes._();

  static const String splash = '/';
  static const String shell =
      '/shell'; // MainTab: Home / Search / Orders / Mine

  // Home & discovery
  static const String home = '/home';
  static const String search = '/search';
  static const String searchShop = '/search-shop';
  static const String channelList = '/channel-list';
  static const String mealForOne = '/meal-for-one';
  static const String pickUp = '/pick-up';
  static const String fixedPrice = '/fixed-price';
  static const String kingkongLanding = '/kingkong';

  // Shop & ordering
  // Legacy "open the shop" link of the still-offline screens → the store's
  // categories (single store; the old shop-id extra is ignored).
  static const String shop = '/shop';
  static const String shopFavorites = '/shop-favorites'; // unbuilt (wishlist)
  static const String skuModal = '/sku-modal';
  static const String cartPreview = '/cart-preview';
  static const String checkout = '/checkout'; // order confirm

  // Backend catalogue (jm3eia API) — slugs travel in immutable args classes
  static const String categories = '/categories'; // the whole category tree
  static const String category = '/category'; // extra: CategoryArgs
  // Any product list: brand, collection, tag, offers… extra: ProductListingArgs
  static const String productListing = '/products';
  static const String brands = '/brands';
  static const String offers = '/offers';
  static const String recipes = '/recipes';
  static const String recipe = '/recipe'; // extra: String slug
  static const String contentPage = '/content-page'; // extra: String slug (CMS)
  static const String proMembership = '/pro'; // Pro plans + perks

  // Product detail
  // extra: ProductDetailArgs
  static const String productDetail = '/product-detail';
  // extra: PdpImageViewerArgs
  static const String pdpImageViewer = '/pdp-image-viewer';

  // Order lifecycle
  static const String orders = '/orders'; // list
  static const String orderTracking = '/order-tracking'; // arg: orderId
  static const String orderMap = '/order-map';
  static const String orderRefund = '/order-refund';
  static const String orderRefundDetail = '/order-refund-detail';
  static const String orderReview = '/order-review';
  static const String orderInvoice = '/order-invoice';
  static const String punctual = '/punctual';
  static const String punctualRule = '/punctual-rule';

  // Account & support
  static const String mine = '/mine';
  static const String profileEdit = '/profile-edit'; // signed-in customer only
  static const String notifications = '/notifications'; // inbox (signed-in)
  static const String mineAbout = '/mine-about';
  static const String mineSettings = '/mine-settings';
  static const String mineDeliveryCode = '/mine-delivery-code';
  static const String wallet = '/wallet'; // balance + transactions (signed-in)
  static const String loyalty = '/loyalty'; // points + history (signed-in)
  static const String customerService = '/customer-service';
  static const String customerServiceQuestion = '/customer-service-question';
  static const String imChat = '/im-chat';

  // Address & location
  static const String addressList = '/address-list';
  static const String addressEdit = '/address-edit';
  static const String addressSelect = '/address-select';
  static const String chooseLocation = '/choose-location';

  // Marketing & coupons
  static const String myCoupons = '/my-coupons';
  static const String historyCoupons = '/history-coupons';
  static const String orderCoupons = '/order-coupons';
  static const String inviteFriends = '/invite-friends';

  // Auth
  static const String login = '/login'; // extra: `true` after a session expiry
  static const String otpVerify = '/otp-verify'; // extra: OtpVerifyArgs
}
