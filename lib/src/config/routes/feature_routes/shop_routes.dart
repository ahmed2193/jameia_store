import 'package:go_router/go_router.dart';

import '../../../core/navigation/navigation.dart';
import '../../../features/shop/presentation/pages/brands_page.dart';
import '../../../features/shop/presentation/pages/categories_page.dart';
import '../../../features/shop/presentation/pages/category_page.dart';
import '../../../features/shop/presentation/pages/product_listing_page.dart';
import '../placeholder_page.dart';
import '../route_args/category_args.dart';
import '../route_args/product_listing_args.dart';
import '../routes.dart';

/// Category browsing + product listings (jm3eia backend catalogue).
final List<RouteBase> shopRoutes = <RouteBase>[
  GoRoute(
    path: Routes.categories,
    pageBuilder: (_, state) => JameiaTransitionPage<Object?>(
      key: state.pageKey,
      name: state.uri.path,
      child: const CategoriesPage(),
    ),
  ),
  GoRoute(
    path: Routes.brands,
    pageBuilder: (_, state) => JameiaTransitionPage<Object?>(
      key: state.pageKey,
      name: state.uri.path,
      child: const BrandsPage(),
    ),
  ),
  // The app is a single store: the marketplace "open this shop" link of the
  // screens that are still offline (orders, discovery leftovers) lands on the
  // store's categories. Its old `extra` (an offline shop id) is ignored.
  GoRoute(
    path: Routes.shop,
    pageBuilder: (_, state) => JameiaTransitionPage<Object?>(
      key: state.pageKey,
      name: state.uri.path,
      child: const CategoriesPage(),
    ),
  ),
  // extra: CategoryArgs
  GoRoute(
    path: Routes.category,
    pageBuilder: (_, state) {
      final args = state.extra;
      return JameiaTransitionPage<Object?>(
        key: state.pageKey,
        name: state.uri.path,
        child: args is CategoryArgs
            ? CategoryPage(args: args)
            : PlaceholderPage(title: PlaceholderPage.titleFor(state.uri.path)),
      );
    },
  ),
  // extra: ProductListingArgs
  GoRoute(
    path: Routes.productListing,
    pageBuilder: (_, state) {
      final args = state.extra;
      return JameiaTransitionPage<Object?>(
        key: state.pageKey,
        name: state.uri.path,
        child: args is ProductListingArgs
            ? ProductListingPage(args: args)
            : PlaceholderPage(title: PlaceholderPage.titleFor(state.uri.path)),
      );
    },
  ),
];
