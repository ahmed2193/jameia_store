import 'package:flutter/widgets.dart';

import 'motion.dart';
import 'on_screen_gate.dart';

/// The ON-SCREEN GATE as a widget (docs/motion §9.3): [builder] gets
/// `play = true` while this box is on screen, the app is in the foreground
/// and decorative motion is allowed here ([MotionGuard.ambientAllowed]: not
/// reduced, no screen reader, its tab and route in front). For motion that
/// is not an [AmbientLoop] — a drift, a glide, a hand-made ticker — so it
/// stops the moment nobody can see it. A stateful widget of its own mixes
/// in [OnScreenGate] instead.
class PlayWhenOnScreen extends StatefulWidget {
  const PlayWhenOnScreen({super.key, required this.builder});

  final Widget Function(BuildContext context, bool play) builder;

  @override
  State<PlayWhenOnScreen> createState() => _PlayWhenOnScreenState();
}

class _PlayWhenOnScreenState extends State<PlayWhenOnScreen>
    with OnScreenGate<PlayWhenOnScreen> {
  @override
  void onScreenChanged() => setState(() {});

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, onScreen && MotionGuard.ambientAllowed(context));
}
