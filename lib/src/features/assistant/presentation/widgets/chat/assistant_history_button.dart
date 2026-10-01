import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/routes.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/widgets/hero_bar_action.dart';
import '../../cubit/assistant_chat_cubit.dart';

/// Opens the chat history; the conversation picked there opens here.
class AssistantHistoryButton extends StatelessWidget {
  const AssistantHistoryButton({super.key});

  Future<void> _open(BuildContext context) async {
    final cubit = context.read<AssistantChatCubit>();
    final conversationId = await context.push<String>(Routes.assistantHistory);
    if (conversationId == null || cubit.isClosed) return;
    await cubit.loadThread(conversationId);
  }

  @override
  Widget build(BuildContext context) {
    return HeroBarAction(
      icon: HeroIcons.history,
      tooltip: 'assistant.history'.tr(),
      onPressed: () => _open(context),
    );
  }
}
