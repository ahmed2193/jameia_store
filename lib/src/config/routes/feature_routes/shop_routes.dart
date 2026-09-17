import 'package:go_router/go_router.dart';

import '../../../core/navigation/navigation.dart';
import '../../../features/shop/presentation/pages/shop_detail_page.dart';
import '../../../features/shop/presentation/pages/shop_favorites_page.dart';
import '../../../features/shop/presentation/pages/shop_map_page.dart';
import '../../../features/shop/presentation/pages/shop_page.dart';
import '../routes.dart';

const String _fallbackShopId = 's1';

/// Shop menu, shop info, shop map and favourites.
final List<RouteBase> shopRoutes = <RouteBase>[
  // extra: String shop id / shop route arg (default: 's1').
  GoRoute(
    path: Routes.shop,
    pageBuilder: (_, state) {
      final shopId = state.extra;
      return JameiaTransitionPage<Object?>(
        key: state.pageKey,
        name: state.uri.path,
        child: ShopPage(shopId: shopId is String ? shopId : _fallbackShopId),
      );
    },
  ),
  // extra: String shop id (default: 's1').
  GoRoute(
    path: Routes.shopDetail,
    pageBuilder: (_, state) {
      final shopId = state.extra;
      return JameiaTransitionPage<Object?>(
        key: state.pageKey,
        name: state.uri.path,
        child: ShopDetailPage(
          shopId: shopId is String ? shopId : _fallbackShopId,
        ),
      );
    },
  ),
  GoRoute(
    path: Routes.shopFavorites,
    pageBuilder: (_, state) => JameiaTransitionPage<Object?>(
      key: state.pageKey,
      name: state.uri.path,
      child: const ShopFavoritesPage(),
    ),
  ),
  // extra: String shop id (default: 's1').
  GoRoute(
    path: Routes.shopMap,
    pageBuilder: (_, state) {
      final shopId = state.extra;
      return JameiaTransitionPage<Object?>(
        key: state.pageKey,
        name: state.uri.path,
        child: ShopMapPage(shopId: shopId is String ? shopId : _fallbackShopId),
      );
    },
  ),
];
