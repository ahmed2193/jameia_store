import 'package:go_router/go_router.dart';

import '../../../core/domain/entities/order_entity.dart';
import '../../../core/navigation/navigation.dart';
import '../../../features/support/presentation/pages/customer_service_page.dart';
import '../../../features/support/presentation/pages/customer_service_question_page.dart';
import '../../../features/support/presentation/pages/im_chat_page.dart';
import '../../../features/support/presentation/pages/order_help_page.dart';
import '../routes.dart';

/// Customer service hub, FAQ/question page, the IM chat and the order help
/// form.
final List<RouteBase> supportRoutes = <RouteBase>[
  GoRoute(
    path: Routes.customerService,
    pageBuilder: (_, state) => HeroTransitionPage<Object?>(
      key: state.pageKey,
      name: state.uri.path,
      child: const CustomerServicePage(),
    ),
  ),
  // extra: String question / order id (default: null).
  GoRoute(
    path: Routes.customerServiceQuestion,
    pageBuilder: (_, state) {
      final arg = state.extra;
      return HeroTransitionPage<Object?>(
        key: state.pageKey,
        name: state.uri.path,
        child: CustomerServiceQuestionPage(arg: arg is String ? arg : null),
      );
    },
  ),
  // extra (an order id from the orders list) is accepted but unused.
  GoRoute(
    path: Routes.imChat,
    pageBuilder: (_, state) => HeroTransitionPage<Object?>(
      key: state.pageKey,
      name: state.uri.path,
      child: const ImChatPage(),
    ),
  ),
  // extra: the OrderEntity the help is about. Without one (a restored or
  // typed location) the help hub, which still reaches every way to help.
  GoRoute(
    path: Routes.orderHelp,
    pageBuilder: (_, state) {
      final order = state.extra;
      return HeroTransitionPage<Object?>(
        key: state.pageKey,
        name: state.uri.path,
        child: order is OrderEntity
            ? OrderHelpPage(order: order)
            : const CustomerServicePage(),
      );
    },
  ),
];
