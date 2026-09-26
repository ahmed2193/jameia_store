import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/routes.dart';
import '../../../../../core/responsive/content_clamp.dart';
import '../../../../../core/utils/failure_message.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../cubit/assistant_availability_cubit.dart';
import '../../cubit/assistant_availability_state.dart';
import '../../cubit/assistant_chat_cubit.dart';
import '../../cubit/assistant_chat_state.dart';
import '../composer/assistant_composer.dart';
import '../welcome/assistant_welcome_view.dart';
import 'assistant_chat_ended_bar.dart';
import 'assistant_handoff_banner.dart';
import 'assistant_message_list.dart';
import 'assistant_thread_skeleton.dart';

/// Switches the chat screen: off when the store turned the assistant off,
/// a sign-in prompt when guests may not chat, then loading / error /
/// welcome / the conversation — with the handoff banner on top and the
/// composer (or the "chat ended" bar) at the bottom.
class AssistantChatBody extends StatelessWidget {
  const AssistantChatBody({super.key});

  static bool _layoutChanged(
    AssistantChatState previous,
    AssistantChatState current,
  ) =>
      previous.status != current.status ||
      previous.isWelcome != current.isWelcome ||
      previous.thread.hasEnded != current.thread.hasEnded ||
      previous.thread.isHandedOff != current.thread.isHandedOff;

  @override
  Widget build(BuildContext context) {
    final unavailable = context.select<AssistantAvailabilityCubit, bool>(
      (cubit) => cubit.state.status == AssistantAvailabilityStatus.unavailable,
    );
    if (unavailable) {
      return EmptyStateView(
        message: 'assistant.unavailable'.tr(),
        icon: Icons.auto_awesome_outlined,
        actionLabel: 'assistant.go_back'.tr(),
        onAction: () => context.pop(),
      );
    }
    // Never a pre-check of the session: the server's 401 decides (§3.2).
    return BlocBuilder<AssistantChatCubit, AssistantChatState>(
      buildWhen: _layoutChanged,
      builder: (context, state) => switch (state.status) {
        AssistantChatStatus.loading => const AssistantThreadSkeleton(),
        AssistantChatStatus.signedOut => EmptyStateView(
          message: 'assistant.sign_in_prompt'.tr(),
          icon: Icons.lock_outline_rounded,
          actionLabel: 'auth.log_in_or_sign_up'.tr(),
          onAction: () => context.go(Routes.login),
        ),
        AssistantChatStatus.error => ErrorView(
          message: state.failure?.localizedMessage,
          onRetry: () => context.read<AssistantChatCubit>().retryLoad(),
        ),
        AssistantChatStatus.ready => ContentClamp(
          child: Column(
            children: [
              if (state.thread.isHandedOff) const AssistantHandoffBanner(),
              Expanded(
                child: state.isWelcome
                    ? const AssistantWelcomeView()
                    : const AssistantMessageList(),
              ),
              if (state.thread.hasEnded)
                const AssistantChatEndedBar()
              else
                const AssistantComposer(),
            ],
          ),
        ),
      },
    );
  }
}
