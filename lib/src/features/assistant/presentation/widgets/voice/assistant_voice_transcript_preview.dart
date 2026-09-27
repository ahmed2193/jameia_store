import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubit/assistant_voice_cubit.dart';
import '../../cubit/assistant_voice_state.dart';
import 'assistant_voice_reveal.dart';
import 'assistant_voice_transcript_bubble.dart';

/// What the assistant is hearing, live, just above the message box — the
/// message writing itself as the customer speaks, so a misheard word is
/// seen before it is sent. Gone while the mic rests.
class AssistantVoiceTranscriptPreview extends StatelessWidget {
  const AssistantVoiceTranscriptPreview({super.key});

  static bool _changed(
    AssistantVoiceState previous,
    AssistantVoiceState current,
  ) =>
      previous.phase != current.phase ||
      previous.transcript != current.transcript ||
      previous.language != current.language;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AssistantVoiceCubit, AssistantVoiceState>(
      buildWhen: _changed,
      builder: (context, state) => AssistantVoiceReveal(
        // After letting go, only words worth waiting for stay on screen.
        shown:
            state.phase.isRecording ||
            (state.phase.isFinishing && state.transcript.isNotEmpty),
        alignment: AlignmentDirectional.bottomEnd,
        child: AssistantVoiceTranscriptBubble(
          transcript: state.transcript,
          phase: state.phase,
          language: state.language,
        ),
      ),
    );
  }
}
