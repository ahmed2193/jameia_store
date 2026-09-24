import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';

import '../../../core/domain/entities/catalog_product_query.dart';
import '../../../core/navigation/navigation.dart';
import '../../../features/shop/presentation/pages/product_listing_page.dart';
import '../placeholder_page.dart';
import '../route_args/product_listing_args.dart';
import '../routes.dart';

/// Search results. (The search entry screen is a shell tab.)
final List<RouteBase> searchRoutes = <RouteBase>[
  // extra: String — the committed search text. The results ARE a product
  // listing (`GET /v1/products?search=`) with the same sort / filters / paging
  // as every other listing, so the shared listing page renders them.
  GoRoute(
    path: Routes.searchShop,
    pageBuilder: (_, state) {
      final query = state.extra;
      final text = query is String ? query.trim() : '';
      return JameiaTransitionPage<Object?>(
        key: state.pageKey,
        name: state.uri.path,
        child: text.isEmpty
            ? PlaceholderPage(title: PlaceholderPage.titleFor(state.uri.path))
            : ProductListingPage(
                args: ProductListingArgs(
                  title: 'search.results_title'.tr(namedArgs: {'query': text}),
                  query: CatalogProductQuery(search: text),
                ),
              ),
      );
    },
  ),
];
