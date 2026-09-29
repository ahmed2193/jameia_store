import '../mascot/assistant_mascot_mood.dart';

/// What a tour demo asks of the mascot up top at one of its moments: wave
/// hello, listen while the customer "types", talk while the answer comes,
/// smile or cheer (with a hop) when something lands, calm down after.
enum AssistantOnboardingCue {
  wave(AssistantMascotMood.happy, waves: true),
  listen(AssistantMascotMood.curious),
  talk(AssistantMascotMood.talking),
  smile(AssistantMascotMood.happy),
  cheer(AssistantMascotMood.happy, hops: true),
  rest(AssistantMascotMood.idle);

  const AssistantOnboardingCue(
    this.mood, {
    this.hops = false,
    this.waves = false,
  });

  /// The face the mascot takes.
  final AssistantMascotMood mood;

  /// It also hops for joy.
  final bool hops;

  /// It also waves its sprout (its own painted hello).
  final bool waves;
}
