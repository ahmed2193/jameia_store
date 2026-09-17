import 'package:go_router/go_router.dart';

import '../../../core/navigation/navigation.dart';
import '../../../features/coupons/presentation/pages/history_coupons_page.dart';
import '../../../features/coupons/presentation/pages/my_coupons_page.dart';
import '../../../features/coupons/presentation/pages/order_coupons_page.dart';
import '../routes.dart';

/// My coupons, coupon history and the checkout coupon picker.
final List<RouteBase> couponsRoutes = <RouteBase>[
  GoRoute(
    path: Routes.myCoupons,
    pageBuilder: (_, state) => JameiaTransitionPage<Object?>(
      key: state.pageKey,
      name: state.uri.path,
      child: const MyCouponsPage(),
    ),
  ),
  // extra: String selected coupon id (default: null). Pops with the chosen
  // coupon (or null).
  GoRoute(
    path: Routes.orderCoupons,
    pageBuilder: (_, state) {
      final selectedId = state.extra;
      return JameiaTransitionPage<Object?>(
        key: state.pageKey,
        name: state.uri.path,
        child: OrderCouponsPage(
          selectedId: selectedId is String ? selectedId : null,
        ),
      );
    },
  ),
  GoRoute(
    path: Routes.historyCoupons,
    pageBuilder: (_, state) => JameiaTransitionPage<Object?>(
      key: state.pageKey,
      name: state.uri.path,
      child: const HistoryCouponsPage(),
    ),
  ),
];
