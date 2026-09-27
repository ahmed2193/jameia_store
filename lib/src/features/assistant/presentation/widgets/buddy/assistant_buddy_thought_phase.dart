import 'dart:ui' show Offset;

import '../mascot/assistant_mascot_mood.dart';

/// Where the launcher's thought is — and the face the mascot makes along:
/// dots while it thinks (it looks up, wondering), the line typing (it
/// talks), then said (a smile while it can be read).
enum AssistantBuddyThoughtPhase {
  thinking(AssistantMascotMood.curious, Offset(0, -0.9)),
  typing(AssistantMascotMood.talking, Offset(0, -0.5)),
  said(AssistantMascotMood.happy, Offset.zero);

  const AssistantBuddyThoughtPhase(this.mood, this.look);

  final AssistantMascotMood mood;

  /// Where the mascot's eyes go: up at its bubble while it thinks.
  final Offset look;
}
