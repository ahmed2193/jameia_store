import 'package:go_router/go_router.dart';

import '../../../core/navigation/navigation.dart';
import '../../../features/marketing/domain/entities/content_page_entity.dart';
import '../../../features/marketing/presentation/pages/content_page.dart';
import '../../../features/marketing/presentation/pages/offers_page.dart';
import '../placeholder_page.dart';
import '../routes.dart';

/// The store's offers and the backend's CMS pages.
final List<RouteBase> marketingRoutes = <RouteBase>[
  GoRoute(
    path: Routes.offers,
    pageBuilder: (_, state) => JameiaTransitionPage<Object?>(
      key: state.pageKey,
      name: state.uri.path,
      child: const OffersPage(),
    ),
  ),
  // extra: String slug — one of the backend's CMS pages (`about`, `contact`,
  // `faq`, `privacy`, `terms`); anything else is a placeholder.
  GoRoute(
    path: Routes.contentPage,
    pageBuilder: (_, state) {
      final slug = state.extra;
      final kind = slug is String ? ContentPageKind.ofSlug(slug) : null;
      return JameiaTransitionPage<Object?>(
        key: state.pageKey,
        name: state.uri.path,
        child: kind != null
            ? ContentPage(kind: kind)
            : PlaceholderPage(title: PlaceholderPage.titleFor(state.uri.path)),
      );
    },
  ),
];
