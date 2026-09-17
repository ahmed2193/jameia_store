import 'package:go_router/go_router.dart';

import '../../../core/navigation/navigation.dart';
import '../../../features/account/presentation/pages/mine_page.dart';
import '../../../features/orders/presentation/pages/orders_page.dart';
import '../../../features/search/presentation/pages/search_page.dart';
import '../../../features/shell/presentation/pages/main_shell_page.dart';
import '../routes.dart';

/// Main tab shell (Home / Search / Orders / Mine) plus the stand-alone tab
/// pages. [Routes.shell] and [Routes.home] both land on [MainShellPage].
final List<RouteBase> shellRoutes = <RouteBase>[
  GoRoute(
    path: Routes.shell,
    pageBuilder: (_, state) => JameiaTransitionPage<Object?>(
      key: state.pageKey,
      name: state.uri.path,
      child: const MainShellPage(),
    ),
  ),
  GoRoute(
    path: Routes.home,
    pageBuilder: (_, state) => JameiaTransitionPage<Object?>(
      key: state.pageKey,
      name: state.uri.path,
      child: const MainShellPage(),
    ),
  ),
  GoRoute(
    path: Routes.search,
    pageBuilder: (_, state) => JameiaTransitionPage<Object?>(
      key: state.pageKey,
      name: state.uri.path,
      child: const SearchPage(),
    ),
  ),
  GoRoute(
    path: Routes.orders,
    pageBuilder: (_, state) => JameiaTransitionPage<Object?>(
      key: state.pageKey,
      name: state.uri.path,
      child: const OrdersPage(),
    ),
  ),
  GoRoute(
    path: Routes.mine,
    pageBuilder: (_, state) => JameiaTransitionPage<Object?>(
      key: state.pageKey,
      name: state.uri.path,
      child: const MinePage(),
    ),
  ),
];
