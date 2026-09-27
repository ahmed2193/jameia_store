import 'dart:ui' show Offset;

import '../../../domain/entities/assistant_thought.dart';
import '../../../domain/entities/assistant_thought_topic.dart';
import '../mascot/assistant_mascot_mood.dart';
import 'assistant_buddy_thought_phase.dart';

/// How the mascot reacts to what it thinks out loud. It looks up while it
/// thinks and talks while the line types — waving its sprout as it greets,
/// its eyes darting about on "What are you looking for?". Once the line is
/// said it beams at an offer (sparkle and all), listens, head tilted, after
/// a question, a choice or a problem, smiles softly and winks when it is
/// just being there, and laughs at the rest. [playful] lines end with a
/// little hop and a bump of the bubble.
extension AssistantBuddyThoughtFace on AssistantThought {
  static const Offset _glanceFrom = Offset(-0.8, -0.2);
  static const Offset _glanceTo = Offset(0.8, -0.2);

  AssistantMascotMood moodWhen(AssistantBuddyThoughtPhase phase) {
    if (phase != AssistantBuddyThoughtPhase.said) return phase.mood;
    return switch (topic) {
      AssistantThoughtTopic.deals => AssistantMascotMood.delighted,
      AssistantThoughtTopic.ask ||
      AssistantThoughtTopic.choose ||
      AssistantThoughtTopic.fix => AssistantMascotMood.curious,
      AssistantThoughtTopic.company => AssistantMascotMood.warm,
      _ => AssistantMascotMood.happy,
    };
  }

  Offset lookWhen(AssistantBuddyThoughtPhase phase) {
    if (this != AssistantThought.looking) return phase.look;
    return switch (phase) {
      AssistantBuddyThoughtPhase.thinking => phase.look,
      AssistantBuddyThoughtPhase.typing => _glanceFrom,
      AssistantBuddyThoughtPhase.said => _glanceTo,
    };
  }

  /// Waves its sprout while it types (a greeting).
  bool get waves => opens;

  /// Winks once it is said (just being there).
  bool get winks => topic == AssistantThoughtTopic.company;

  /// The cheeriest lines, which end with a hop.
  bool get playful => switch (this) {
    AssistantThought.looking ||
    AssistantThought.together ||
    AssistantThought.fillCart ||
    AssistantThought.price => true,
    _ => false,
  };
}
