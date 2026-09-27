import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/routes.dart';
import '../../../../../core/domain/entities/screen_load.dart';
import '../../../../../core/widgets/reconnect_refresh.dart';
import '../../../../../core/widgets/screen_stale_notice.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../cubit/assistant_history_cubit.dart';
import '../../cubit/assistant_history_state.dart';
import 'assistant_history_list.dart';
import 'assistant_history_skeleton.dart';

/// The history screen by status: skeleton, sign-in prompt, error + retry
/// ("No connection" when nothing is saved), "No chats yet" (back to the
/// chat) or the grouped list — the saved one at once, with the "Updated …
/// ago" note while offline or after a failed refresh. A returning
/// connection refreshes a saved or failed history.
class AssistantHistoryBody extends StatelessWidget {
  const AssistantHistoryBody({super.key});

  @override
  Widget build(BuildContext context) {
    return ReconnectRefresh(
      onReconnected: () =>
          context.read<AssistantHistoryCubit>().onReconnected(),
      child: BlocBuilder<AssistantHistoryCubit, AssistantHistoryState>(
        buildWhen: (previous, current) =>
            current.load.screenChangedFrom(previous.load) ||
            previous.feed != current.feed,
        builder: (context, state) => switch (state.status) {
          LoadPhase.initial ||
          LoadPhase.loading => const AssistantHistorySkeleton(),
          LoadPhase.error when state.isSignedOut => EmptyStateView(
            message: 'assistant.sign_in_prompt'.tr(),
            icon: Icons.lock_outline_rounded,
            actionLabel: 'auth.log_in_or_sign_up'.tr(),
            onAction: () => context.go(Routes.login),
          ),
          LoadPhase.error => FailureView(
            failure: state.failure,
            onRetry: () => context.read<AssistantHistoryCubit>().load(),
          ),
          LoadPhase.loaded => Column(
            children: [
              const ScreenStaleNotice<
                AssistantHistoryCubit,
                AssistantHistoryState
              >(),
              Expanded(
                child: state.feed.isEmpty
                    ? EmptyStateView(
                        message: 'assistant.history_empty'.tr(),
                        icon: Icons.forum_outlined,
                        actionLabel: 'assistant.history_start'.tr(),
                        onAction: () => context.pop(),
                      )
                    : AssistantHistoryList(feed: state.feed),
              ),
            ],
          ),
        },
      ),
    );
  }
}
