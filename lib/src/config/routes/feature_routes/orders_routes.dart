import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../core/domain/entities/order_entity.dart';
import '../../../core/navigation/navigation.dart';
import '../../../features/orders/presentation/pages/order_invoice_page.dart';
import '../../../features/orders/presentation/pages/order_live_map_page.dart';
import '../../../features/orders/presentation/pages/order_review_page.dart';
import '../../../features/orders/presentation/pages/order_tracking_page.dart';
import '../placeholder_page.dart';
import '../route_args/order_review_args.dart';
import '../route_args/placed_order_args.dart';
import '../routes.dart';

/// Order lifecycle: tracking, product reviews, invoice, the live rider map.
/// Each takes the order id as `extra` (the map: the order itself); without
/// one the placeholder page explains the dead link. They are forward steps
/// (orders → tracking → invoice / review), so they push on the shared X axis
/// — except tracking right after the order was placed ([PlacedOrderArgs]), a
/// new root that fades through, and the live map, a layer over the order
/// page that slides up.
final List<RouteBase> ordersRoutes = <RouteBase>[
  GoRoute(
    path: Routes.orderTracking,
    pageBuilder: (_, state) {
      final extra = state.extra;
      if (extra is PlacedOrderArgs) {
        return HeroFadeThroughPage<Object?>(
          key: state.pageKey,
          name: state.uri.path,
          child: OrderTrackingPage(orderId: extra.orderId),
        );
      }
      return _orderPage(
        state,
        (orderId) => OrderTrackingPage(orderId: orderId),
      );
    },
  ),
  // extra: the order id, or [OrderReviewArgs] (stars tapped on the order
  // page) — the review then opens with every product at that rating.
  GoRoute(
    path: Routes.orderReview,
    pageBuilder: (_, state) {
      final extra = state.extra;
      if (extra is OrderReviewArgs && extra.orderId.isNotEmpty) {
        return HeroTransitionPage<Object?>(
          key: state.pageKey,
          name: state.uri.path,
          child: OrderReviewPage(
            orderId: extra.orderId,
            initialRating: extra.rating,
          ),
        );
      }
      return _orderPage(state, (orderId) => OrderReviewPage(orderId: orderId));
    },
  ),
  GoRoute(
    path: Routes.orderInvoice,
    pageBuilder: (_, state) =>
        _orderPage(state, (orderId) => OrderInvoicePage(orderId: orderId)),
  ),
  GoRoute(
    path: Routes.orderLiveMap,
    pageBuilder: (_, state) {
      final order = state.extra;
      return HeroSlideUpTransitionPage<Object?>(
        key: state.pageKey,
        name: state.uri.path,
        child: order is OrderEntity && order.id.isNotEmpty
            ? OrderLiveMapPage(order: order)
            : PlaceholderPage(title: PlaceholderPage.titleFor(state.uri.path)),
      );
    },
  ),
];

HeroTransitionPage<Object?> _orderPage(
  GoRouterState state,
  Widget Function(String orderId) build,
) {
  final orderId = state.extra;
  return HeroTransitionPage<Object?>(
    key: state.pageKey,
    name: state.uri.path,
    child: orderId is String && orderId.isNotEmpty
        ? build(orderId)
        : PlaceholderPage(title: PlaceholderPage.titleFor(state.uri.path)),
  );
}
