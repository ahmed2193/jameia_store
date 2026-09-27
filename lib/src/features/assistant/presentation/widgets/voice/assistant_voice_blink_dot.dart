import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/responsive/app_size.dart';

/// The red mic that blinks while recording (WhatsApp's "on air" light).
/// Its own layer; still under reduced motion.
class AssistantVoiceBlinkDot extends StatefulWidget {
  const AssistantVoiceBlinkDot({super.key});

  /// One fade out and back in.
  static const Duration period = Duration(milliseconds: 1000);

  /// The dimmest point of a blink.
  static const double _dim = 0.15;

  @override
  State<AssistantVoiceBlinkDot> createState() => _AssistantVoiceBlinkDotState();
}

class _AssistantVoiceBlinkDotState extends State<AssistantVoiceBlinkDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AssistantVoiceBlinkDot.period,
  );
  late final Animation<double> _opacity = Tween<double>(
    begin: 1,
    end: AssistantVoiceBlinkDot._dim,
  ).chain(CurveTween(curve: AppMotion.machEaseInOut)).animate(_controller);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MotionGuard.reduced(context)) {
      _controller
        ..stop()
        ..value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: FadeTransition(
        opacity: _opacity,
        child: const Icon(
          Icons.mic_rounded,
          size: AppSize.s22,
          color: AppColors.error,
        ),
      ),
    );
  }
}
