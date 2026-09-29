import 'dart:ui' show Offset;

import 'assistant_mascot_pose.dart';

/// What the mascot feels; [AssistantMascot] eases from one mood's face to
/// the next. Every mood is a still face: nothing loops (docs/motion §9.6
/// §3.1 row 8 — talking is a held pose, not a flapping mouth).
enum AssistantMascotMood {
  /// Calm, a small smile, looking ahead.
  idle(AssistantMascotPose.rest),

  /// Laughing eyes and a wide smile (a tap, a greeting, a cart add).
  happy(AssistantMascotPose(happy: 1, twinkle: 0.4)),

  /// Laughing, its sparkle at full shine — a good deal to tell about.
  delighted(AssistantMascotPose(happy: 1, twinkle: 1)),

  /// A soft smile with open eyes — easy company (and room for a wink).
  warm(AssistantMascotPose(happy: 0.2, twinkle: 0.2)),

  /// Mouth open mid-word, held while its own line reveals.
  talking(AssistantMascotPose(talk: 0.55)),

  /// Eyes up and to the side, mouth shut: working something out (a real
  /// wait — the chat's reply on its way).
  thinking(AssistantMascotPose(look: Offset(0.55, -0.75))),

  /// Eyes wide, glancing down, sprout drooping aside: "oops" — a reply
  /// that failed (docs/motion §9.6 §2.8).
  oops(
    AssistantMascotPose(surprise: 0.6, sway: -0.35, look: Offset(-0.3, 0.55)),
  ),

  /// A soft smile, looking and leaning aside — passing the chat to a
  /// person (§2.11).
  handingOver(
    AssistantMascotPose(happy: 0.3, sway: 0.45, look: Offset(0.85, 0.1)),
  ),

  /// Eyes a little wider, sprout leaning in: listening.
  curious(
    AssistantMascotPose(surprise: 0.35, sway: 0.3, look: Offset(0, -0.4)),
  ),

  /// Round eyes and an "o" — picked up and carried around.
  surprised(AssistantMascotPose(surprise: 1, squash: -0.35));

  const AssistantMascotMood(this.pose);

  /// The face this mood settles on.
  final AssistantMascotPose pose;
}
