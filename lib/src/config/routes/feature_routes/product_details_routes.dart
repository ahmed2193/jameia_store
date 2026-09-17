import 'package:go_router/go_router.dart';

import '../../../core/data/models/models.dart';
import '../../../core/navigation/navigation.dart';
import '../../../features/product_details/presentation/pages/product_detail_page.dart';
import '../../../features/product_details/presentation/widgets/pdp_image_viewer.dart';
import '../placeholder_page.dart';
import '../route_args/pdp_image_viewer_args.dart';
import '../routes.dart';

/// KeeMart product detail (PDP) and its full-screen image viewer. Both are
/// "Pop" presentations, so they slide up via [JameiaSlideUpTransitionPage].
/// Without their required `extra` they fall back to [PlaceholderPage].
final List<RouteBase> productDetailsRoutes = <RouteBase>[
  // extra: Product (required).
  GoRoute(
    path: Routes.productDetail,
    pageBuilder: (_, state) {
      final product = state.extra;
      return JameiaSlideUpTransitionPage<Object?>(
        key: state.pageKey,
        name: state.uri.path,
        child: product is Product
            ? ProductDetailPage(product: product)
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
            ? PdpImageViewer(
                images: args.images,
                kcal: args.kcal,
                initialIndex: args.initialIndex,
              )
            : PlaceholderPage(title: PlaceholderPage.titleFor(state.uri.path)),
      );
    },
  ),
];
