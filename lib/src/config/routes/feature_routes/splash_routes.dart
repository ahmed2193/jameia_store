import 'package:go_router/go_router.dart';

import '../../../core/navigation/navigation.dart';
import '../../../features/splash/presentation/pages/splash_page.dart';
import '../../di/app_global_cubits.dart';
import '../routes.dart';

/// Brand splash — the router's initial location.
final List<RouteBase> splashRoutes = <RouteBase>[
  GoRoute(
    path: Routes.splash,
    pageBuilder: (_, state) => HeroTransitionPage<Object?>(
      key: state.pageKey,
      name: state.uri.path,
      // The home read starts as the launch frame holds (B1-14).
      child: const SplashPage(onLaunchFrame: AppGlobalCubits.prefetchHome),
    ),
  ),
];
