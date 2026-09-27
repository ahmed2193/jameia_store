import 'dart:ui' show Offset;

import 'assistant_mascot_pose.dart';

/// What the mascot feels; [AssistantMascot] eases from one mood's face to
/// the next.
enum AssistantMascotMood {
  /// Calm, a small smile — blinks and glances around now and then.
  idle(AssistantMascotPose.rest),

  /// Laughing eyes and a wide smile (a tap, a greeting, a cart add).
  happy(AssistantMascotPose(happy: 1, twinkle: 0.4)),

  /// Mouth moving, as while the greeting types itself out.
  talking(AssistantMascotPose()),

  /// Eyes a little wider, sprout leaning in: listening.
  curious(
    AssistantMascotPose(surprise: 0.35, sway: 0.3, look: Offset(0, -0.4)),
  ),

  /// Round eyes and an "o" — picked up and carried around.
  surprised(AssistantMascotPose(surprise: 1, squash: -0.35));

  const AssistantMascotMood(this.pose);

  /// The face this mood settles on (talking adds the moving mouth).
  final AssistantMascotPose pose;
}
