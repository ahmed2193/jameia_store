import 'package:go_router/go_router.dart';

import '../../../core/navigation/navigation.dart';
import '../../../features/coupons/presentation/pages/history_coupons_page.dart';
import '../../../features/coupons/presentation/pages/my_coupons_page.dart';
import '../routes.dart';

/// My coupons and coupon history.
final List<RouteBase> couponsRoutes = <RouteBase>[
  GoRoute(
    path: Routes.myCoupons,
    pageBuilder: (_, state) => HeroTransitionPage<Object?>(
      key: state.pageKey,
      name: state.uri.path,
      child: const MyCouponsPage(),
    ),
  ),
  GoRoute(
    path: Routes.historyCoupons,
    pageBuilder: (_, state) => HeroTransitionPage<Object?>(
      key: state.pageKey,
      name: state.uri.path,
      child: const HistoryCouponsPage(),
    ),
  ),
];
