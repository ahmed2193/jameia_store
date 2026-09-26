import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/routes.dart';
import '../../../../../core/utils/failure_message.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../cubit/assistant_history_cubit.dart';
import '../../cubit/assistant_history_state.dart';
import 'assistant_history_list.dart';
import 'assistant_history_skeleton.dart';

/// The history screen by status: skeleton, sign-in prompt, error + retry,
/// "No chats yet" (back to the chat) or the grouped list.
class AssistantHistoryBody extends StatelessWidget {
  const AssistantHistoryBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AssistantHistoryCubit, AssistantHistoryState>(
      buildWhen: (previous, current) =>
          previous.status != current.status || previous.feed != current.feed,
      builder: (context, state) => switch (state.status) {
        AssistantHistoryStatus.initial ||
        AssistantHistoryStatus.loading => const AssistantHistorySkeleton(),
        AssistantHistoryStatus.error when state.isSignedOut => EmptyStateView(
          message: 'assistant.sign_in_prompt'.tr(),
          icon: Icons.lock_outline_rounded,
          actionLabel: 'auth.log_in_or_sign_up'.tr(),
          onAction: () => context.go(Routes.login),
        ),
        AssistantHistoryStatus.error => ErrorView(
          message: state.failure?.localizedMessage,
          onRetry: () => context.read<AssistantHistoryCubit>().load(),
        ),
        AssistantHistoryStatus.loaded when state.feed.isEmpty => EmptyStateView(
          message: 'assistant.history_empty'.tr(),
          icon: Icons.forum_outlined,
          actionLabel: 'assistant.history_start'.tr(),
          onAction: () => context.pop(),
        ),
        AssistantHistoryStatus.loaded => AssistantHistoryList(feed: state.feed),
      },
    );
  }
}
