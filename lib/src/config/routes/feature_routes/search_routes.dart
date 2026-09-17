import 'package:go_router/go_router.dart';

import '../../../core/navigation/navigation.dart';
import '../../../features/search/presentation/pages/search_shop_page.dart';
import '../routes.dart';

const String _emptyQuery = '';

/// Search results (the search entry page itself is registered with the shell
/// tabs in `shell_routes.dart`).
final List<RouteBase> searchRoutes = <RouteBase>[
  // extra: String query (default: empty).
  GoRoute(
    path: Routes.searchShop,
    pageBuilder: (_, state) {
      final query = state.extra;
      return JameiaTransitionPage<Object?>(
        key: state.pageKey,
        name: state.uri.path,
        child: SearchShopPage(query: query is String ? query : _emptyQuery),
      );
    },
  ),
];
