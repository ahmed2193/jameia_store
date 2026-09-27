import 'package:go_router/go_router.dart';

import '../../../core/navigation/navigation.dart';
import '../placeholder_page.dart';
import '../routes.dart';

/// Registered-but-unbuilt screens: each lands on [PlaceholderPage] titled from
/// its path (e.g. `/invite-friends` -> "invite friends"). Any other unknown
/// location gets the same page from the router's `errorPageBuilder`.
const List<String> unbuiltRoutePaths = <String>[
  // Saved products: `GET /v1/account/wishlist` is not integrated yet (the old
  // page listed the offline marketplace's shops).
  Routes.shopFavorites,
  // No backend behind it: the referral programme was built on invented data
  // (fake code / earnings) and is gone. The link that still points here (Mine
  // page) lands on the placeholder.
  Routes.inviteFriends,
];

final List<RouteBase> placeholderRoutes = <RouteBase>[
  for (final path in unbuiltRoutePaths)
    GoRoute(
      path: path,
      pageBuilder: (_, state) => HeroTransitionPage<Object?>(
        key: state.pageKey,
        name: state.uri.path,
        child: PlaceholderPage(title: PlaceholderPage.titleFor(state.uri.path)),
      ),
    ),
];
