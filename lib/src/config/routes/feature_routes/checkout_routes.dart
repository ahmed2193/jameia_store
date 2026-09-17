import 'package:go_router/go_router.dart';

import '../../../core/navigation/navigation.dart';
import '../../../features/cart/presentation/pages/cart_preview_page.dart';
import '../../../features/checkout/presentation/pages/checkout_page.dart';
import '../routes.dart';

const String _fallbackShopId = 's1';

/// Cart preview and order confirm (checkout).
final List<RouteBase> checkoutRoutes = <RouteBase>[
  GoRoute(
    path: Routes.cartPreview,
    pageBuilder: (_, state) => JameiaTransitionPage<Object?>(
      key: state.pageKey,
      name: state.uri.path,
      child: const CartPreviewPage(),
    ),
  ),
  // extra: String shop id (default: 's1').
  GoRoute(
    path: Routes.checkout,
    pageBuilder: (_, state) {
      final shopId = state.extra;
      return JameiaTransitionPage<Object?>(
        key: state.pageKey,
        name: state.uri.path,
        child: CheckoutPage(
          shopId: shopId is String ? shopId : _fallbackShopId,
        ),
      );
    },
  ),
];
