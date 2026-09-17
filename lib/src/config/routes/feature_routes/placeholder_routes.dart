import 'package:go_router/go_router.dart';

import '../../../core/navigation/navigation.dart';
import '../placeholder_page.dart';
import '../routes.dart';

/// Registered-but-unbuilt screens: each lands on [PlaceholderPage] titled from
/// its path (e.g. `/punctual-rule` -> "punctual rule"). Any other unknown
/// location gets the same page from the router's `errorPageBuilder`.
const List<String> unbuiltRoutePaths = <String>[
  Routes.skuModal,
  Routes.punctualRule,
  Routes.addressSelect,
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
