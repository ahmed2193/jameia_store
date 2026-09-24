import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/navigation.dart';
import '../../../features/orders/presentation/pages/order_invoice_page.dart';
import '../../../features/orders/presentation/pages/order_review_page.dart';
import '../../../features/orders/presentation/pages/order_tracking_page.dart';
import '../placeholder_page.dart';
import '../routes.dart';

/// Order lifecycle: tracking, product reviews, invoice. Each takes the order
/// id as `extra`; without one the placeholder page explains the dead link.
final List<RouteBase> ordersRoutes = <RouteBase>[
  GoRoute(
    path: Routes.orderTracking,
    pageBuilder: (_, state) =>
        _orderPage(state, (orderId) => OrderTrackingPage(orderId: orderId)),
  ),
  GoRoute(
    path: Routes.orderReview,
    pageBuilder: (_, state) =>
        _orderPage(state, (orderId) => OrderReviewPage(orderId: orderId)),
  ),
  GoRoute(
    path: Routes.orderInvoice,
    pageBuilder: (_, state) =>
        _orderPage(state, (orderId) => OrderInvoicePage(orderId: orderId)),
  ),
];

JameiaTransitionPage<Object?> _orderPage(
  GoRouterState state,
  Widget Function(String orderId) build,
) {
  final orderId = state.extra;
  return JameiaTransitionPage<Object?>(
    key: state.pageKey,
    name: state.uri.path,
    child: orderId is String && orderId.isNotEmpty
        ? build(orderId)
        : PlaceholderPage(title: PlaceholderPage.titleFor(state.uri.path)),
  );
}
