import 'package:go_router/go_router.dart';

import '../../../core/navigation/navigation.dart';
import '../../../features/product_details/presentation/pages/pdp_image_viewer_page.dart';
import '../../../features/product_details/presentation/pages/product_detail_page.dart';
import '../placeholder_page.dart';
import '../route_args/pdp_image_viewer_args.dart';
import '../route_args/product_detail_args.dart';
import '../routes.dart';

/// The product page and its full-screen image viewer. Both are "Pop"
/// presentations, so they slide up via [JameiaSlideUpTransitionPage]. Without
/// their required `extra` they fall back to [PlaceholderPage].
final List<RouteBase> productDetailsRoutes = <RouteBase>[
  // extra: ProductDetailArgs (required) — the product is addressed by slug.
  GoRoute(
    path: Routes.productDetail,
    pageBuilder: (_, state) {
      final args = state.extra;
      return JameiaSlideUpTransitionPage<Object?>(
        key: state.pageKey,
        name: state.uri.path,
        child: args is ProductDetailArgs
            ? ProductDetailPage(args: args)
            : PlaceholderPage(title: PlaceholderPage.titleFor(state.uri.path)),
      );
    },
  ),
  // extra: PdpImageViewerArgs (required). Pops with the final page index (int).
  GoRoute(
    path: Routes.pdpImageViewer,
    pageBuilder: (_, state) {
      final args = state.extra;
      return JameiaSlideUpTransitionPage<Object?>(
        key: state.pageKey,
        name: state.uri.path,
        child: args is PdpImageViewerArgs
            ? PdpImageViewerPage(
                images: args.images,
                initialIndex: args.initialIndex,
              )
            : PlaceholderPage(title: PlaceholderPage.titleFor(state.uri.path)),
      );
    },
  ),
];
