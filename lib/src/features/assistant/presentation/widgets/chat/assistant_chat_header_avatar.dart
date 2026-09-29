import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/responsive/app_size.dart';
import '../../../domain/entities/assistant_thread.dart';
import '../../cubit/assistant_chat_cubit.dart';
import '../../cubit/assistant_chat_state.dart';
import '../assistant_motion.dart';
import '../mascot/assistant_mascot_mood.dart';
import 'assistant_avatar.dart';
import 'assistant_chat_motion_gate.dart';

/// The chat header's mascot (docs/motion §9.6 §3.3): one wake blink once
/// the page has settled, then only moods that follow the chat — thinking
/// while a reply is on its way, idle when it lands, happy for
/// [AssistantMotion.cheerHold] after a confirmed proposal, "oops" after a
/// reply that failed, handing over once a person has the chat. Each change
/// eases over `medium` when the chat's motion gate is open (nothing streams,
/// the mic rests, no keyboard) and jumps otherwise; nothing loops.
class AssistantChatHeaderAvatar extends StatefulWidget {
  const AssistantChatHeaderAvatar({super.key});

  @override
  State<AssistantChatHeaderAvatar> createState() =>
      _AssistantChatHeaderAvatarState();
}

class _AssistantChatHeaderAvatarState extends State<AssistantChatHeaderAvatar> {
  Timer? _cheer;

  static AssistantMascotMood _moodOf(AssistantChatState state) {
    if (state.isStreaming) return AssistantMascotMood.thinking;
    final entries = state.thread.entries;
    final last = entries.isEmpty ? null : entries.last;
    if (last is AssistantTurnEntry && last.turn.isFailed) {
      return AssistantMascotMood.oops;
    }
    if (state.thread.isHandedOff) return AssistantMascotMood.handingOver;
    return AssistantMascotMood.idle;
  }

  void _onCartRevision(BuildContext context, AssistantChatState state) {
    _cheer?.cancel();
    setState(() {
      _cheer = Timer(AssistantMotion.cheerHold, () {
        if (mounted) setState(() => _cheer = null);
      });
    });
  }

  @override
  void dispose() {
    _cheer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mood = context.select<AssistantChatCubit, AssistantMascotMood>(
      (cubit) => _moodOf(cubit.state),
    );
    final cheering = _cheer != null && mood != AssistantMascotMood.thinking;
    return BlocListener<AssistantChatCubit, AssistantChatState>(
      listenWhen: (previous, current) =>
          current.cartRevision > previous.cartRevision,
      listener: _onCartRevision,
      child: AssistantChatMotionGate(
        child: AssistantAvatar(
          size: AppSize.s32,
          wake: true,
          mood: cheering ? AssistantMascotMood.happy : mood,
        ),
      ),
    );
  }
}
