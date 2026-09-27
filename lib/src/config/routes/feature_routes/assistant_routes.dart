import 'package:go_router/go_router.dart';

import '../../../core/navigation/navigation.dart';
import '../../../features/assistant/presentation/pages/assistant_chat_page.dart';
import '../../../features/assistant/presentation/pages/assistant_history_page.dart';
import '../route_args/assistant_chat_args.dart';
import '../routes.dart';

/// The Hero Assistant: the chat slides up as a full-screen presentation,
/// its history pushes over it (and pops a conversation id back).
final List<RouteBase> assistantRoutes = <RouteBase>[
  // extra: AssistantChatArgs (optional) — without it, a new chat.
  GoRoute(
    path: Routes.assistant,
    pageBuilder: (_, state) {
      final args = state.extra;
      final chat = args is AssistantChatArgs ? args : null;
      return HeroSlideUpTransitionPage<Object?>(
        key: state.pageKey,
        name: state.uri.path,
        child: AssistantChatPage(
          conversationId: chat?.conversationId,
          initialPrompt: chat?.initialPrompt,
        ),
      );
    },
  ),
  // Pops with the picked conversation id (String), or nothing.
  GoRoute(
    path: Routes.assistantHistory,
    pageBuilder: (_, state) => HeroTransitionPage<Object?>(
      key: state.pageKey,
      name: state.uri.path,
      child: const AssistantHistoryPage(),
    ),
  ),
];
