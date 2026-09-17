import '../constants/app_env.dart';

/// Every jm3eia customer route, in one place, so a backend rename is a single
/// edit. Paths are relative to `AppEnv.apiBaseUrl`; parameterised routes are
/// functions (`EndPoints.product(slug)`).
///
/// Reference: https://docs.jm3eia.store/developers/
abstract final class EndPoints {
  static const String _v = AppEnv.apiVersion;

  // --- Bootstrap (public; auth optional) ------------------------------------
  /// Launch snapshot: store, user|null, wishlist ids, cart offers, delivery
  /// mode, marketing popups, `store.assistant.{enabled,allowGuests}`.
  static const String init = '$_v/init';
  static const String home = '$_v/home';

  // --- Auth (OTP) ------------------------------------------------------------
  static const String authSendOtp = '$_v/auth/send-otp';
  static const String authVerifyOtp = '$_v/auth/verify-otp';
  static const String authRefresh = '$_v/auth/refresh';
  static const String authLogout = '$_v/auth/logout';

  /// Routes the 401-refresh interceptor must never try to recover.
  static const Set<String> authPaths = {
    authSendOtp,
    authVerifyOtp,
    authRefresh,
    authLogout,
  };

  // --- Catalog (public; slugs, not ids) --------------------------------------
  static const String categories = '$_v/categories';
  static String category(String slug) => '$categories/$slug';
  static const String brands = '$_v/brands';
  static String brand(String slug) => '$brands/$slug';
  static const String collections = '$_v/collections';
  static String collection(String slug) => '$collections/$slug';

  /// Query: page, limit, categorySlug, brandSlug, collectionSlug, search, tag,
  /// inStock, onSale, minPrice, maxPrice, sort → `{ data, pagination }`.
  static const String products = '$_v/products';
  static String product(String slug) => '$products/$slug';
  static String productReviews(String slug) => '$products/$slug/reviews';
  static const String recipes = '$_v/recipes';
  static String recipe(String slug) => '$recipes/$slug';
  static const String offers = '$_v/offers';
  static String page(String slug) => '$_v/pages/$slug';
  static const String subscriptionPlans = '$_v/subscription-plans';
  static const String reviews = '$_v/reviews';
  static String review(String reviewId) => '$reviews/$reviewId';

  // --- Cart (public; guest → X-Cart-Token, customer → Bearer) ---------------
  static const String cart = '$_v/cart';
  static const String cartItems = '$cart/items';
  static String cartItem(String key) => '$cartItems/$key';
  static const String cartCoupon = '$cart/coupon';
  static const String cartLoyalty = '$cart/loyalty';
  static const String cartExpress = '$cart/express';

  // --- Delivery --------------------------------------------------------------
  static const String deliveryAreas = '$_v/delivery/areas';
  static const String deliveryBranches = '$_v/delivery/branches';
  static const String deliverySlots = '$_v/delivery/slots';
  static const String deliverySelect = '$_v/delivery/select';
  static const String deliverySelectBranch = '$_v/delivery/select-branch';
  static const String deliverySelectAddress = '$_v/delivery/select-address';
  static const String deliveryResolveLocation = '$_v/delivery/resolve-location';

  // --- Orders (customer) -----------------------------------------------------
  static const String orders = '$_v/orders';
  static String order(String orderId) => '$orders/$orderId';
  static String orderCancel(String orderId) => '$orders/$orderId/cancel';

  // --- Account (customer) ----------------------------------------------------
  static const String accountMe = '$_v/account/me';
  static const String accountProfile = '$_v/account/profile';
  static const String accountWallet = '$_v/account/wallet';
  static const String accountLoyalty = '$_v/account/loyalty';
  static const String accountAddresses = '$_v/account/addresses';
  static String accountAddress(String addressId) =>
      '$accountAddresses/$addressId';
  static const String accountWishlist = '$_v/account/wishlist';
  static String accountWishlistItem(String productId) =>
      '$accountWishlist/$productId';
  static const String accountViewed = '$_v/account/viewed';
  static const String accountViewedMerge = '$accountViewed/merge';
  static const String accountSubscription = '$_v/account/subscription';
  static const String accountSubscriptionCancel = '$accountSubscription/cancel';

  // --- Notifications + push (customer) ---------------------------------------
  static const String notifications = '$_v/notifications';

  /// `text/event-stream` — bypasses the JSON envelope (needs a stream client).
  static const String notificationsSse = '$notifications/sse';
  static const String notificationsReadAll = '$notifications/read-all';
  static String notificationRead(String notificationId) =>
      '$notifications/$notificationId/read';
  static const String pushRegister = '$_v/push/register';

  // --- Support ---------------------------------------------------------------
  static const String supportCategories = '$_v/support/categories';
  static const String supportTickets = '$_v/support/tickets';
  static String supportTicket(String ticketId) => '$supportTickets/$ticketId';
  static String supportTicketMessages(String ticketId) =>
      '$supportTickets/$ticketId/messages';

  // --- Assistant (customer or X-Assistant-Guest) -----------------------------
  static const String assistantConversations = '$_v/assistant/conversations';
  static String assistantConversation(String conversationId) =>
      '$assistantConversations/$conversationId';
  static String assistantHandoff(String conversationId) =>
      '$assistantConversations/$conversationId/handoff';

  /// POST — `text/event-stream` reply (needs a stream client).
  static const String assistantMessages = '$_v/assistant/messages';
  static String assistantMessageFeedback(String messageId) =>
      '$assistantMessages/$messageId/feedback';
  static String assistantActionConfirm(String actionId) =>
      '$_v/assistant/actions/$actionId/confirm';

  /// Routes that stream `text/event-stream` instead of the JSON envelope.
  static const Set<String> streamingPaths = {
    notificationsSse,
    assistantMessages,
  };
}
