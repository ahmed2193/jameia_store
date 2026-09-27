import 'package:flutter/material.dart';

import '../../../../../core/motion/motion.dart';
import '../../../../../core/motion/size_fade_switcher.dart';

/// Shows or hides a voice part of the composer (the live words, the
/// hands-free line): it grows in and fades, and shrinks away. Under
/// reduced motion it simply appears — an `AnimatedSize` with no duration
/// re-dirties itself in its own layout.
class AssistantVoiceReveal extends StatelessWidget {
  const AssistantVoiceReveal({
    super.key,
    required this.shown,
    required this.child,
    this.alignment = AlignmentDirectional.bottomStart,
  });

  final bool shown;
  final Widget child;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final content = shown ? child : const SizedBox(width: double.infinity);
    if (MotionGuard.reduced(context)) return content;
    return SizeFadeSwitcher(
      stateKey: shown,
      alignment: alignment,
      child: content,
    );
  }
}
