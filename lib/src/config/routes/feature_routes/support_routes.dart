import 'package:go_router/go_router.dart';

import '../../../core/navigation/navigation.dart';
import '../../../features/support/presentation/pages/customer_service_page.dart';
import '../../../features/support/presentation/pages/customer_service_question_page.dart';
import '../../../features/support/presentation/pages/im_chat_page.dart';
import '../routes.dart';

/// Customer service hub, FAQ/question page and the IM chat.
final List<RouteBase> supportRoutes = <RouteBase>[
  GoRoute(
    path: Routes.customerService,
    pageBuilder: (_, state) => JameiaTransitionPage<Object?>(
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
      return JameiaTransitionPage<Object?>(
        key: state.pageKey,
        name: state.uri.path,
        child: CustomerServiceQuestionPage(arg: arg is String ? arg : null),
      );
    },
  ),
  // extra (an order id from the orders list) is accepted but unused.
  GoRoute(
    path: Routes.imChat,
    pageBuilder: (_, state) => JameiaTransitionPage<Object?>(
      key: state.pageKey,
      name: state.uri.path,
      child: const ImChatPage(),
    ),
  ),
];
