import 'package:go_router/go_router.dart';

import '../../../core/navigation/navigation.dart';
import '../../../features/marketing/presentation/pages/invite_friends_page.dart';
import '../../../features/marketing/presentation/pages/punctual_page.dart';
import '../routes.dart';

/// Invite friends and the on-time (punctual) guarantee page.
final List<RouteBase> marketingRoutes = <RouteBase>[
  GoRoute(
    path: Routes.inviteFriends,
    pageBuilder: (_, state) => JameiaTransitionPage<Object?>(
      key: state.pageKey,
      name: state.uri.path,
      child: const InviteFriendsPage(),
    ),
  ),
  GoRoute(
    path: Routes.punctual,
    pageBuilder: (_, state) => JameiaTransitionPage<Object?>(
      key: state.pageKey,
      name: state.uri.path,
      child: const PunctualPage(),
    ),
  ),
];
