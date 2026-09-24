import 'package:go_router/go_router.dart';

import '../../../core/navigation/navigation.dart';
import '../../../features/cart/presentation/pages/cart_preview_page.dart';
import '../../../features/checkout/presentation/pages/checkout_page.dart';
import '../routes.dart';

/// Cart and checkout. Both read the app-global cart; neither takes an extra.
final List<RouteBase> checkoutRoutes = <RouteBase>[
  GoRoute(
    path: Routes.cartPreview,
    pageBuilder: (_, state) => JameiaTransitionPage<Object?>(
      key: state.pageKey,
      name: state.uri.path,
      child: const CartPreviewPage(),
    ),
  ),
  GoRoute(
    path: Routes.checkout,
    pageBuilder: (_, state) => JameiaTransitionPage<Object?>(
      key: state.pageKey,
      name: state.uri.path,
      child: const CheckoutPage(),
    ),
  ),
];
