import 'package:go_router/go_router.dart';

import '../../../core/navigation/navigation.dart';
import '../../../features/orders/presentation/pages/order_invoice_page.dart';
import '../../../features/orders/presentation/pages/order_map_page.dart';
import '../../../features/orders/presentation/pages/order_refund_detail_page.dart';
import '../../../features/orders/presentation/pages/order_refund_page.dart';
import '../../../features/orders/presentation/pages/order_review_page.dart';
import '../../../features/orders/presentation/pages/order_tracking_page.dart';
import '../routes.dart';

const String _fallbackOrderId = 'o1';

/// Order lifecycle: tracking, map, review, refund, refund progress, e-invoice.
final List<RouteBase> ordersRoutes = <RouteBase>[
  // extra: String order id (default: 'o1').
  GoRoute(
    path: Routes.orderTracking,
    pageBuilder: (_, state) {
      final orderId = state.extra;
      return JameiaTransitionPage<Object?>(
        key: state.pageKey,
        name: state.uri.path,
        child: OrderTrackingPage(
          orderId: orderId is String ? orderId : _fallbackOrderId,
        ),
      );
    },
  ),
  // extra: String order id (default: 'o1').
  GoRoute(
    path: Routes.orderMap,
    pageBuilder: (_, state) {
      final orderId = state.extra;
      return JameiaTransitionPage<Object?>(
        key: state.pageKey,
        name: state.uri.path,
        child: OrderMapPage(
          orderId: orderId is String ? orderId : _fallbackOrderId,
        ),
      );
    },
  ),
  // extra: String order id (default: 'o1').
  GoRoute(
    path: Routes.orderReview,
    pageBuilder: (_, state) {
      final orderId = state.extra;
      return JameiaTransitionPage<Object?>(
        key: state.pageKey,
        name: state.uri.path,
        child: OrderReviewPage(
          orderId: orderId is String ? orderId : _fallbackOrderId,
        ),
      );
    },
  ),
  GoRoute(
    path: Routes.orderRefund,
    pageBuilder: (_, state) => JameiaTransitionPage<Object?>(
      key: state.pageKey,
      name: state.uri.path,
      child: const OrderRefundPage(),
    ),
  ),
  // extra: String order id (default: 'o1').
  GoRoute(
    path: Routes.orderRefundDetail,
    pageBuilder: (_, state) {
      final orderId = state.extra;
      return JameiaTransitionPage<Object?>(
        key: state.pageKey,
        name: state.uri.path,
        child: OrderRefundDetailPage(
          orderId: orderId is String ? orderId : _fallbackOrderId,
        ),
      );
    },
  ),
  // extra: String order id (default: null).
  GoRoute(
    path: Routes.orderInvoice,
    pageBuilder: (_, state) {
      final orderId = state.extra;
      return JameiaTransitionPage<Object?>(
        key: state.pageKey,
        name: state.uri.path,
        child: OrderInvoicePage(orderId: orderId is String ? orderId : null),
      );
    },
  ),
];
