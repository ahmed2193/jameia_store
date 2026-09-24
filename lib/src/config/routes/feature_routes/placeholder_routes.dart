import 'package:go_router/go_router.dart';

import '../../../core/navigation/navigation.dart';
import '../placeholder_page.dart';
import '../routes.dart';

/// Registered-but-unbuilt screens: each lands on [PlaceholderPage] titled from
/// its path (e.g. `/punctual-rule` -> "punctual rule"). Any other unknown
/// location gets the same page from the router's `errorPageBuilder`.
const List<String> unbuiltRoutePaths = <String>[
  // Saved products: `GET /v1/account/wishlist` is not integrated yet (the old
  // page listed the offline marketplace's shops).
  Routes.shopFavorites,
  // No backend behind them: the referral programme and the on-time guarantee
  // landing were built on invented data (fake code / earnings) and are gone.
  // The links that still point here (Mine page) land on the placeholder.
  Routes.inviteFriends,
  Routes.punctual,
  Routes.skuModal,
  Routes.punctualRule,
  Routes.addressSelect,
  // No backend behind them: the live rider map, refund request and refund
  // progress screens ran on invented data (demo coordinates, fake refund
  // maths) and are gone; the API has no refund or courier-location routes.
  Routes.orderMap,
  Routes.orderRefund,
  Routes.orderRefundDetail,
];

final List<RouteBase> placeholderRoutes = <RouteBase>[
  for (final path in unbuiltRoutePaths)
    GoRoute(
      path: path,
      pageBuilder: (_, state) => JameiaTransitionPage<Object?>(
        key: state.pageKey,
        name: state.uri.path,
        child: PlaceholderPage(title: PlaceholderPage.titleFor(state.uri.path)),
      ),
    ),
];
