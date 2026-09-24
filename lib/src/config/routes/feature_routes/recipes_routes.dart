import 'package:go_router/go_router.dart';

import '../../../core/navigation/navigation.dart';
import '../../../features/recipes/presentation/pages/recipe_detail_page.dart';
import '../../../features/recipes/presentation/pages/recipes_page.dart';
import '../placeholder_page.dart';
import '../routes.dart';

/// Recipe list and recipe page (jm3eia backend).
final List<RouteBase> recipesRoutes = <RouteBase>[
  GoRoute(
    path: Routes.recipes,
    pageBuilder: (_, state) => JameiaTransitionPage<Object?>(
      key: state.pageKey,
      name: state.uri.path,
      child: const RecipesPage(),
    ),
  ),
  // extra: String recipe slug (required).
  GoRoute(
    path: Routes.recipe,
    pageBuilder: (_, state) {
      final slug = state.extra;
      return JameiaTransitionPage<Object?>(
        key: state.pageKey,
        name: state.uri.path,
        child: slug is String && slug.isNotEmpty
            ? RecipeDetailPage(slug: slug)
            : PlaceholderPage(title: PlaceholderPage.titleFor(state.uri.path)),
      );
    },
  ),
];
