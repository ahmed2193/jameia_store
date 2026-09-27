// The mascot's gestures come back to rest: the sprout's wave settles and a
// wink opens its eye again; a wink shuts only one eye.
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/features/assistant/presentation/widgets/mascot/assistant_mascot_gesture.dart';
import 'package:jameia_mart/src/features/assistant/presentation/widgets/mascot/assistant_mascot_pose.dart';

void main() {
  test('a wave swings both ways and settles at rest', () {
    final swings = [
      for (var i = 0; i <= 100; i++) AssistantMascotGesture.wave(i / 100),
    ];
    expect(swings.first, closeTo(0, 1e-9));
    expect(swings.last, closeTo(0, 1e-9));
    expect(swings.any((sway) => sway > 0.3), isTrue);
    expect(swings.any((sway) => sway < -0.3), isTrue);
  });

  test('a wink shuts halfway through and opens again', () {
    expect(AssistantMascotGesture.wink(0), closeTo(0, 1e-9));
    expect(AssistantMascotGesture.wink(0.5), closeTo(1, 1e-9));
    expect(AssistantMascotGesture.wink(1), closeTo(0, 1e-9));
  });

  test('the wink is part of the pose, eased like the rest', () {
    const open = AssistantMascotPose();
    const winking = AssistantMascotPose(wink: 1);
    expect(winking, isNot(open));
    expect(AssistantMascotPose.lerp(open, winking, 0.5).wink, 0.5);
  });
}
