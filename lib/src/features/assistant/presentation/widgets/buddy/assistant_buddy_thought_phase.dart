import 'dart:ui' show Offset;

import '../mascot/assistant_mascot_mood.dart';

/// Where the launcher's thought is — and the face the mascot makes along:
/// the line revealing (it holds a talking pose, eyes up at its bubble),
/// then said (a smile while it can be read). There is no "thinking" beat:
/// nothing real is being worked out, so no dots fake one (docs/motion §9.6
/// §3.4).
enum AssistantBuddyThoughtPhase {
  speaking(AssistantMascotMood.talking, Offset(0, -0.5)),
  said(AssistantMascotMood.happy, Offset.zero);

  const AssistantBuddyThoughtPhase(this.mood, this.look);

  final AssistantMascotMood mood;

  /// Where the mascot's eyes go: up at its bubble while it speaks.
  final Offset look;
}
