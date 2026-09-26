import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/motion/haptics.dart';
import '../../../../core/navigation/jameia_snack_bar.dart';
import '../../../../core/utils/failure_message.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../language/presentation/cubit/localization_cubit.dart';
import '../../../language/presentation/cubit/localization_state.dart';
import '../../domain/entities/assistant_thread.dart';
import '../cubit/assistant_chat_cubit.dart';
import '../cubit/assistant_chat_state.dart';
import '../widgets/chat/assistant_chat_app_bar.dart';
import '../widgets/chat/assistant_celebration.dart';
import '../widgets/chat/assistant_chat_body.dart';

/// The Jm3eia Assistant chat (`/v1/assistant/*`). Opens a conversation from
/// history ([conversationId]), starts one with [initialPrompt], or shows the
/// welcome. Composes the app bar + body and turns the cubit's one-shot
/// outcomes into feedback: a confirmed proposal refetches the app cart,
/// notices and failures become snack bars, a language change reloads the
/// thread (names are resolved server-side).
class AssistantChatPage extends StatelessWidget {
  const AssistantChatPage({super.key, this.conversationId, this.initialPrompt});

  final String? conversationId;
  final String? initialPrompt;

  static bool _hasOutcome(
    AssistantChatState previous,
    AssistantChatState current,
  ) =>
      current.notice != null ||
      (current.failure != null && current.status == AssistantChatStatus.ready);

  void _onOutcome(BuildContext context, AssistantChatState state) {
    final failureText = state.failure?.localizedMessage;
    final String? text = switch (state.notice) {
      AssistantChatNotice.turnFailed => null,
      AssistantChatNotice.sendFailed => state.noticeMessage ?? failureText,
      AssistantChatNotice.actionExpired => 'assistant.action_unavailable'.tr(),
      AssistantChatNotice.feedbackSent => 'assistant.feedback_thanks'.tr(),
      AssistantChatNotice.handedOff =>
        state.noticeMessage ?? 'assistant.handoff_body'.tr(),
      AssistantChatNotice.conversationUnavailable =>
        'assistant.conversation_unavailable'.tr(),
      null => failureText,
    };
    if (state.notice == AssistantChatNotice.turnFailed) Haptics.warning();
    if (state.notice == AssistantChatNotice.handedOff) Haptics.success();
    if (text != null && text.isNotEmpty) showJameiaSnackBar(context, text);
  }

  /// Tells a screen reader that a reply started, then how it ended — the
  /// first words of the answer, never the streamed words one by one — and
  /// gives a light tap when an answer lands.
  void _onTurn(BuildContext context, AssistantChatState state) {
    final entries = state.thread.entries;
    final last = entries.isEmpty ? null : entries.last;
    final text = state.isStreaming
        ? 'assistant.a11y_responding'.tr()
        : switch (last) {
            AssistantMessageEntry(:final message) when message.isAssistant =>
              'assistant.a11y_replied'.tr(
                namedArgs: {'text': message.spokenPreview},
              ),
            AssistantTurnEntry(:final turn) when turn.isFailed =>
              'assistant.a11y_failed'.tr(),
            _ => '',
          };
    if (!state.isStreaming && last is AssistantMessageEntry) {
      Haptics.selection();
    }
    if (text.isEmpty) return;
    unawaited(
      SemanticsService.sendAnnouncement(
        View.of(context),
        text,
        Directionality.of(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AssistantChatCubit>()
        ..open(conversationId: conversationId, initialPrompt: initialPrompt),
      child: MultiBlocListener(
        listeners: [
          BlocListener<AssistantChatCubit, AssistantChatState>(
            listenWhen: _hasOutcome,
            listener: _onOutcome,
          ),
          BlocListener<AssistantChatCubit, AssistantChatState>(
            listenWhen: (previous, current) =>
                previous.isStreaming != current.isStreaming,
            listener: _onTurn,
          ),
          // A confirmed proposal changed the server cart: refetch the app's
          // cart mirror (the only public refetch the cart cubit offers).
          BlocListener<AssistantChatCubit, AssistantChatState>(
            listenWhen: (previous, current) =>
                previous.cartRevision != current.cartRevision,
            listener: (context, _) {
              Haptics.success();
              context.read<CartCubit>().onLocaleChanged();
            },
          ),
          BlocListener<LocalizationCubit, LocalizationState>(
            listenWhen: (previous, current) =>
                previous.isInitialized && previous.locale != current.locale,
            listener: (context, _) =>
                context.read<AssistantChatCubit>().reloadForLocale(),
          ),
        ],
        child: const Scaffold(
          backgroundColor: AppColors.smallBackground,
          appBar: AssistantChatAppBar(),
          body: AssistantCelebration(child: AssistantChatBody()),
        ),
      ),
    );
  }
}
