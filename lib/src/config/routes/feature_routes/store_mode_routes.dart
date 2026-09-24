import 'package:go_router/go_router.dart';

import '../../../core/navigation/navigation.dart';
import '../../../features/store_mode/presentation/pages/pro_membership_page.dart';
import '../routes.dart';

/// Pro membership (the backend's replacement of the VIP ⇄ Mart store mode).
final List<RouteBase> storeModeRoutes = <RouteBase>[
  GoRoute(
    path: Routes.proMembership,
    pageBuilder: (_, state) => JameiaTransitionPage<Object?>(
      key: state.pageKey,
      name: state.uri.path,
      child: const ProMembershipPage(),
    ),
  ),
];
