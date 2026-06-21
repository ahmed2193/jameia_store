/// Route-name registry for the KeeTa consumer clone. Mirrors KeeTa's Mach Pro
/// page inventory (one route per real screen).
class Routes {
  Routes._();

  static const String splash = '/';
  static const String shell = '/shell'; // MainTab: Home / Search / Orders / Mine

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
  static const String shop = '/shop'; // menu/ordering — arg: shopId
  static const String shopDetail = '/shop-detail';
  static const String shopMap = '/shop-map';
  static const String shopFavorites = '/shop-favorites';
  static const String skuModal = '/sku-modal';
  static const String cartPreview = '/cart-preview';
  static const String checkout = '/checkout'; // order confirm

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
  static const String mineAbout = '/mine-about';
  static const String mineSettings = '/mine-settings';
  static const String mineDeliveryCode = '/mine-delivery-code';
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
  static const String login = '/login';
}
