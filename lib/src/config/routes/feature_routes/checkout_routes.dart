import 'package:go_router/go_router.dart';

import '../../../core/navigation/jameia_shared_axis_page.dart';
import '../../../core/navigation/navigation.dart';
import '../../../features/cart/presentation/pages/cart_preview_page.dart';
import '../../../features/checkout/presentation/pages/checkout_page.dart';
import '../../../features/checkout/presentation/pages/checkout_vouchers_page.dart';
import '../routes.dart';

/// Cart and checkout. Both read the app-global cart; neither takes an extra.
/// The cart preview is an entry (standard push); checkout is the next step
/// of the same flow, so it moves on the shared X axis — and so does its
/// "Coupons & offers" page, which takes the serving branch id (a `String`,
/// optional) so it can drop offers limited to other branches.
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
    pageBuilder: (_, state) => JameiaSharedAxisPage<Object?>(
      key: state.pageKey,
      name: state.uri.path,
      child: const CheckoutPage(),
    ),
  ),
  GoRoute(
    path: Routes.checkoutVouchers,
    pageBuilder: (_, state) {
      final branchId = state.extra;
      return JameiaSharedAxisPage<Object?>(
        key: state.pageKey,
        name: state.uri.path,
        child: CheckoutVouchersPage(
          branchId: branchId is String ? branchId : null,
        ),
      );
    },
  ),
];
