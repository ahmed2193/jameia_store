import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/motion/haptics.dart';
import '../../../../../core/navigation/hero_snack_bar.dart';
import '../../../domain/entities/assistant_voice_problem.dart';
import '../../cubit/assistant_voice_cubit.dart';
import '../../cubit/assistant_voice_state.dart';
import 'assistant_voice_blocked_dialog.dart';

/// Turns the voice message's one-shot outcomes into what the customer sees
/// and feels: the words go to the chat ([onSend]) or back to the message
/// box ([onReview]), the bin plays, a mere tap shows the hint, problems
/// become snack bars (keeping any words heard), a blocked microphone
/// offers the settings. A recording starting or locking gives a haptic;
/// a deleted one is told to a screen reader (the microphone is off by then).
class AssistantVoiceListener extends StatelessWidget {
  const AssistantVoiceListener({
    super.key,
    required this.onSend,
    required this.onReview,
    required this.onDiscarded,
    required this.onTooShort,
    required this.onRecording,
    required this.child,
  });

  final ValueChanged<String> onSend;
  final ValueChanged<String> onReview;
  final VoidCallback onDiscarded;
  final VoidCallback onTooShort;

  /// A recording began (the composer drops a bin still playing).
  final VoidCallback onRecording;
  final Widget child;

  static bool _hasNotice(
    AssistantVoiceState previous,
    AssistantVoiceState current,
  ) => current.noticeSeq != previous.noticeSeq && current.notice != null;

  static bool _phaseChanged(
    AssistantVoiceState previous,
    AssistantVoiceState current,
  ) => previous.phase != current.phase;

  static String _problemKey(AssistantVoiceProblem? problem) =>
      switch (problem) {
        AssistantVoiceProblem.noSpeech => 'assistant.voice.no_speech',
        AssistantVoiceProblem.network => 'assistant.voice.network',
        AssistantVoiceProblem.language => 'assistant.voice.language',
        AssistantVoiceProblem.busy => 'assistant.voice.busy',
        AssistantVoiceProblem.permission => 'assistant.voice.mic_denied',
        AssistantVoiceProblem.other || null => 'assistant.voice.failed',
      };

  void _onNotice(BuildContext context, AssistantVoiceState state) {
    final text = state.noticeText;
    switch (state.notice) {
      case AssistantVoiceNotice.send:
        onSend(text);
      case AssistantVoiceNotice.review:
        onReview(text);
      case AssistantVoiceNotice.discarded:
        Haptics.discard();
        onDiscarded();
        _announce(context, 'assistant.voice.a11y_deleted'.tr());
      case AssistantVoiceNotice.tooShort:
        Haptics.refuse();
        onTooShort();
      case AssistantVoiceNotice.noSpeech:
        showHeroSnackBar(
          context,
          'assistant.voice.no_speech'.tr(),
          tone: HeroSnackTone.warning,
        );
      case AssistantVoiceNotice.failed:
        if (text.isNotEmpty) onReview(text);
        showHeroSnackBar(
          context,
          _problemKey(state.problem).tr(),
          tone: HeroSnackTone.warning,
        );
      case AssistantVoiceNotice.micDenied:
        showHeroSnackBar(
          context,
          'assistant.voice.mic_denied'.tr(),
          tone: HeroSnackTone.warning,
        );
      case AssistantVoiceNotice.micBlocked:
        unawaited(AssistantVoiceBlockedDialog.show(context));
      case AssistantVoiceNotice.unavailable:
        showHeroSnackBar(
          context,
          'assistant.voice.unavailable'.tr(),
          tone: HeroSnackTone.warning,
        );
      case null:
        return;
    }
  }

  /// A haptic, never a spoken announcement: the open microphone would hear
  /// the screen reader and write its words into the message.
  void _onPhase(BuildContext context, AssistantVoiceState state) {
    switch (state.phase) {
      // The hold's tick fired at touch-down, before the microphone opened
      // (the mic button; docs/motion §9.6 §2.9): none here, where it would
      // land in the recording.
      case AssistantVoicePhase.holding:
        onRecording();
      case AssistantVoicePhase.locked:
        Haptics.pick();
        onRecording();
      case AssistantVoicePhase.idle:
      case AssistantVoicePhase.sending:
      case AssistantVoicePhase.stopping:
        return;
    }
  }

  void _announce(BuildContext context, String text) => unawaited(
    SemanticsService.sendAnnouncement(
      View.of(context),
      text,
      Directionality.of(context),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AssistantVoiceCubit, AssistantVoiceState>(
          listenWhen: _hasNotice,
          listener: _onNotice,
        ),
        BlocListener<AssistantVoiceCubit, AssistantVoiceState>(
          listenWhen: _phaseChanged,
          listener: _onPhase,
        ),
      ],
      child: child,
    );
  }
}
