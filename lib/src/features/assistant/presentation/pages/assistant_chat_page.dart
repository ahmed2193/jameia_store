import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/motion/haptics.dart';
import '../../../../core/navigation/hero_snack_bar.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../language/presentation/cubit/localization_cubit.dart';
import '../../../language/presentation/cubit/localization_state.dart';
import '../../domain/entities/assistant_thread.dart';
import '../cubit/assistant_chat_cubit.dart';
import '../cubit/assistant_chat_state.dart';
import '../cubit/assistant_voice_cubit.dart';
import '../widgets/chat/assistant_chat_app_bar.dart';
import '../widgets/chat/assistant_chat_body.dart';
import '../widgets/chat/assistant_typing_host.dart';

/// The Hero Assistant chat (`/v1/assistant/*`). Opens a conversation from
/// history ([conversationId]), starts one with [initialPrompt], or shows the
/// welcome. Composes the app bar + body and turns the cubit's one-shot
/// outcomes into feedback: a confirmed proposal refetches the app cart (its
/// card flies the items there — no confetti), notices and failures become
/// snack bars unless the chat already says it inline (a failed turn's
/// footer, a proposal's error line, the thumbs' thanks, the hand-off
/// banner), a language change reloads the thread (names are resolved
/// server-side).
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
    final failure = state.failure;
    switch (state.notice) {
      // A failed turn warns once; its footer says what happened, inline.
      case AssistantChatNotice.turnFailed:
        Haptics.refuse();
      // The "Thanks!" beside the thumbs and the live-region banner are the
      // proof of a rating and of a hand-off: no snack bar on top.
      case AssistantChatNotice.feedbackSent || AssistantChatNotice.handedOff:
        return;
      case AssistantChatNotice.sendFailed:
        final text = state.noticeMessage;
        if (text != null && text.isNotEmpty) {
          showHeroSnackBar(context, text, tone: HeroSnackTone.error);
        } else if (failure != null) {
          showFailureSnackBar(context, failure, action: true);
        }
      case AssistantChatNotice.actionExpired:
        showHeroSnackBar(
          context,
          'assistant.action_unavailable'.tr(),
          tone: HeroSnackTone.warning,
        );
      case AssistantChatNotice.conversationUnavailable:
        showHeroSnackBar(
          context,
          'assistant.conversation_unavailable'.tr(),
          tone: HeroSnackTone.warning,
        );
      case null:
        if (failure == null) return;
        _onFailure(context, failure, state.failedAction);
    }
  }

  /// A call the customer made failed. A proposal that could not go says so
  /// under its button (a lost connection also through the offline snack);
  /// a refused hand-off warns; anything else follows the app's
  /// failure-snack rules (offline → "needs the internet" once + the banner).
  void _onFailure(
    BuildContext context,
    Failure failure,
    AssistantChatAction? action,
  ) {
    switch (action) {
      case AssistantChatAction.confirm:
        Haptics.refuse();
        if (failure.isTransport) {
          showFailureSnackBar(context, failure, action: true);
        }
      case AssistantChatAction.handOff:
        Haptics.refuse();
        showFailureSnackBar(context, failure, action: true);
      case AssistantChatAction.send ||
          AssistantChatAction.rate ||
          AssistantChatAction.load ||
          null:
        showFailureSnackBar(context, failure, action: true);
    }
  }

  /// Tells a screen reader that a reply started, then how it ended — the
  /// first words of the answer, never the streamed words one by one. An
  /// arriving answer never vibrates (§9.5).
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
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<AssistantChatCubit>()
            ..open(
              conversationId: conversationId,
              initialPrompt: initialPrompt,
            ),
        ),
        // The composer's mic: readied now when already allowed, so the
        // first press records at once.
        BlocProvider(create: (_) => sl<AssistantVoiceCubit>()..prepare()),
      ],
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
            // The haptic comes with the proposal's flight landing in the
            // cart (the card fires it), not here.
            listener: (context, _) =>
                context.read<CartCubit>().onLocaleChanged(),
          ),
          BlocListener<LocalizationCubit, LocalizationState>(
            listenWhen: (previous, current) =>
                previous.isInitialized && previous.locale != current.locale,
            listener: (context, _) =>
                context.read<AssistantChatCubit>().reloadForLocale(),
          ),
        ],
        // The composer tells the header's mascot when the customer types.
        child: const AssistantTypingHost(
          child: Scaffold(
            backgroundColor: AppColors.smallBackground,
            appBar: AssistantChatAppBar(),
            body: AssistantChatBody(),
          ),
        ),
      ),
    );
  }
}
