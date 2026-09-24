import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../core/navigation/app_keys.dart';
import '../../core/navigation/navigation.dart';
import 'feature_routes/account_routes.dart';
import 'feature_routes/address_routes.dart';
import 'feature_routes/auth_routes.dart';
import 'feature_routes/checkout_routes.dart';
import 'feature_routes/coupons_routes.dart';
import 'feature_routes/discovery_routes.dart';
import 'feature_routes/marketing_routes.dart';
import 'feature_routes/notifications_routes.dart';
import 'feature_routes/orders_routes.dart';
import 'feature_routes/placeholder_routes.dart';
import 'feature_routes/product_details_routes.dart';
import 'feature_routes/recipes_routes.dart';
import 'feature_routes/search_routes.dart';
import 'feature_routes/shell_routes.dart';
import 'feature_routes/shop_routes.dart';
import 'feature_routes/splash_routes.dart';
import 'feature_routes/store_mode_routes.dart';
import 'feature_routes/support_routes.dart';
import 'placeholder_page.dart';
import 'routes.dart';

/// Every top-level route (Jameia Mach Pro page router equivalent), grouped per
/// feature under `feature_routes/`. Each [GoRoute] builds its page through
/// [JameiaTransitionPage] / [JameiaSlideUpTransitionPage] and reads its arguments
/// from `state.extra`.
final List<RouteBase> appRoutes = <RouteBase>[
  ...splashRoutes,
  ...shellRoutes,
  ...searchRoutes,
  ...shopRoutes,
  ...checkoutRoutes,
  ...productDetailsRoutes,
  ...storeModeRoutes,
  ...recipesRoutes,
  ...ordersRoutes,
  ...addressRoutes,
  ...couponsRoutes,
  ...accountRoutes,
  ...notificationsRoutes,
  ...supportRoutes,
  ...marketingRoutes,
  ...discoveryRoutes,
  ...authRoutes,
  ...placeholderRoutes,
];

/// The app's single router, created once (on first read) and handed to
/// `MaterialApp.router` in `app.dart`. Its root navigator is the global
/// [navigatorKey], so non-widget orchestration (the post language-switch
/// refresh in `SettingCubit`) still reaches a surviving `BuildContext`.
final GoRouter appRouter = buildAppRouter();

/// Builds a [GoRouter] over [appRoutes]. The app reads [appRouter]; tests build
/// a fresh instance per case (own [rootNavigatorKey] / [initialLocation]).
///
/// Unknown locations land on [PlaceholderPage] titled from the path, exactly
/// like the former `onGenerateRoute` default arm.
GoRouter buildAppRouter({
  String initialLocation = Routes.splash,
  GlobalKey<NavigatorState>? rootNavigatorKey,
}) {
  return GoRouter(
    navigatorKey: rootNavigatorKey ?? navigatorKey,
    initialLocation: initialLocation,
    routes: appRoutes,
    observers: [routeObserver],
    errorPageBuilder: (_, state) => JameiaTransitionPage<Object?>(
      key: state.pageKey,
      name: state.uri.path,
      child: PlaceholderPage(title: PlaceholderPage.titleFor(state.uri.path)),
    ),
  );
}
