import 'package:flutter/material.dart';

import '../data/models/models.dart';
import '../navigation/navigation.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/shell/presentation/screens/main_shell.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import '../../features/orders/presentation/screens/orders_screen.dart';
import '../../features/orders/presentation/screens/order_tracking_screen.dart';
import '../../features/orders/presentation/screens/order_refund_screen.dart';
import '../../features/orders/presentation/screens/order_review_screen.dart';
import '../../features/account/presentation/screens/mine_screen.dart';
import '../../features/account/presentation/screens/mine_settings_screen.dart';
import '../../features/shop/presentation/screens/shop_screen.dart';
import '../../features/shop/presentation/screens/shop_detail_screen.dart';
import '../../features/shop/presentation/screens/shop_favorites_screen.dart';
import '../../features/checkout/presentation/screens/checkout_screen.dart';
import '../../features/address/presentation/screens/address_list_screen.dart';
import '../../features/address/presentation/screens/address_edit_screen.dart';
import '../../features/coupons/presentation/screens/my_coupons_screen.dart';
import '../../features/coupons/presentation/screens/order_coupons_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/support/presentation/screens/customer_service_screen.dart';
import '../../features/marketing/presentation/screens/invite_friends_screen.dart';
import '../../features/discovery/presentation/screens/channel_list_screen.dart';
import 'placeholder_screen.dart';
import 'routes.dart';

/// Central route dispatcher (KeeTa Mach Pro page router equivalent). Built arms
/// route to real screens; not-yet-built arms fall back to [PlaceholderScreen].
class AppRouter {
  AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final args = settings.arguments;

    Widget page() {
      switch (settings.name) {
        // Shell + tabs
        case Routes.splash:
          return const SplashScreen();
        case Routes.shell:
        case Routes.home:
          return const MainShell();
        case Routes.search:
          return const SearchScreen();
        case Routes.orders:
          return const OrdersScreen();
        case Routes.mine:
          return const MineScreen();

        // Shop & ordering
        case Routes.shop:
          return ShopScreen(shopId: args is String ? args : 's1');
        case Routes.shopDetail:
          return ShopDetailScreen(shopId: args is String ? args : 's1');
        case Routes.shopFavorites:
          return const ShopFavoritesScreen();
        case Routes.checkout:
          return CheckoutScreen(shopId: args is String ? args : 's1');

        // Order lifecycle
        case Routes.orderTracking:
          return OrderTrackingScreen(orderId: args is String ? args : 'o1');
        case Routes.orderReview:
          return OrderReviewScreen(orderId: args is String ? args : 'o1');
        case Routes.orderRefund:
          return const OrderRefundScreen();

        // Address
        case Routes.addressList:
          return const AddressListScreen();
        case Routes.addressEdit:
          return AddressEditScreen(
              address: args is KeetaAddress ? args : null);

        // Coupons
        case Routes.myCoupons:
          return const MyCouponsScreen();
        case Routes.orderCoupons:
          return OrderCouponsScreen(selectedId: args is String ? args : null);

        // Account & support & marketing & discovery
        case Routes.mineSettings:
          return const MineSettingsScreen();
        case Routes.customerService:
          return const CustomerServiceScreen();
        case Routes.inviteFriends:
          return const InviteFriendsScreen();
        case Routes.channelList:
          return ChannelListScreen(title: args is String ? args : 'Discover');

        // Auth
        case Routes.login:
          return const LoginScreen();

        default:
          return PlaceholderScreen(title: _titleFor(settings.name));
      }
    }

    return KeetaPageRoute<dynamic>(page: page(), settings: settings);
  }

  static String _titleFor(String? name) =>
      (name ?? 'Screen').replaceFirst('/', '').replaceAll('-', ' ');
}
