import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/design/hero_assets.dart';
import '../../../../../core/motion/collapse_reveal.dart';
import '../../../../../core/motion/fade_through_switcher.dart';
import '../../../../../core/responsive/content_clamp.dart';
import '../../../../../core/widgets/reconnect_refresh.dart';
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
/// composer (or the "chat ended" bar) at the bottom. The bones cross-fade
/// into the conversation, other status swaps fade through
/// ([FadeThroughSwitcher]). A thread that failed to load for want of a
/// connection says "Checking your connection…", then "No connection"
/// ([FailureView]), and loads again when the connection returns.
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
        art: HeroAssets.stateUnavailable,
        actionLabel: 'assistant.go_back'.tr(),
        onAction: () => context.pop(),
      );
    }
    // Never a pre-check of the session: the server's 401 decides (§3.2).
    return ReconnectRefresh(
      onReconnected: () => context.read<AssistantChatCubit>().onReconnected(),
      child: BlocBuilder<AssistantChatCubit, AssistantChatState>(
        buildWhen: _layoutChanged,
        builder: (context, state) => FadeThroughSwitcher(
          stateKey: state.status,
          // The switcher bakes each child's timing in when it arrives: the
          // bones must be a cross-fade child too, or they linger.
          crossFade:
              state.status == AssistantChatStatus.loading ||
              state.status == AssistantChatStatus.ready,
          child: switch (state.status) {
            AssistantChatStatus.loading => const AssistantThreadSkeleton(),
            AssistantChatStatus.signedOut => HeroStateView.signedOut(
              message: 'assistant.sign_in_prompt'.tr(),
            ),
            AssistantChatStatus.error => FailureView(
              failure: state.failure,
              onRetry: () => context.read<AssistantChatCubit>().retryLoad(),
            ),
            AssistantChatStatus.ready => ContentClamp(
              child: Column(
                children: [
                  // Opens when a person takes the chat (the reversed list
                  // is pinned to its bottom, so the reader's place holds);
                  // a thread opened already handed off shows it at once.
                  CollapseReveal(
                    visible: state.thread.isHandedOff,
                    child: const AssistantHandoffBanner(),
                  ),
                  // The welcome fades through to the first message (§2.12).
                  Expanded(
                    child: FadeThroughSwitcher(
                      stateKey: state.isWelcome,
                      child: SizedBox.expand(
                        child: state.isWelcome
                            ? const AssistantWelcomeView()
                            : const AssistantMessageList(),
                      ),
                    ),
                  ),
                  FadeThroughSwitcher(
                    stateKey: state.thread.hasEnded,
                    crossFade: true,
                    alignment: AlignmentDirectional.bottomCenter,
                    child: state.thread.hasEnded
                        ? const AssistantChatEndedBar()
                        : const AssistantComposer(),
                  ),
                ],
              ),
            ),
          },
        ),
      ),
    );
  }
}
