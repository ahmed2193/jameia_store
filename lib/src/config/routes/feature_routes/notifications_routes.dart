import 'package:go_router/go_router.dart';

import '../../../core/navigation/navigation.dart';
import '../../../features/notifications/presentation/pages/notifications_page.dart';
import '../routes.dart';

/// Customer inbox (signed-in). Deep links out of it go to the order tracking
/// and customer-service routes registered by their own features.
final List<RouteBase> notificationsRoutes = <RouteBase>[
  GoRoute(
    path: Routes.notifications,
    pageBuilder: (_, state) => JameiaTransitionPage<Object?>(
      key: state.pageKey,
      name: state.uri.path,
      child: const NotificationsPage(),
    ),
  ),
];
