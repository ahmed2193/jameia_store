import 'package:go_router/go_router.dart';

import '../../../core/navigation/navigation.dart';
import '../../../features/splash/presentation/pages/splash_page.dart';
import '../routes.dart';

/// Brand splash — the router's initial location.
final List<RouteBase> splashRoutes = <RouteBase>[
  GoRoute(
    path: Routes.splash,
    pageBuilder: (_, state) => JameiaTransitionPage<Object?>(
      key: state.pageKey,
      name: state.uri.path,
      child: const SplashPage(),
    ),
  ),
];
