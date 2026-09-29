import 'package:flutter/physics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../cubit/assistant_voice_cubit.dart';
import '../../cubit/assistant_voice_state.dart';
import '../assistant_motion.dart';

/// A soft ring behind the held mic that swells with the customer's voice:
/// "I hear you" — the only level signal on screen (docs/motion §9.6 §2.9).
/// It grows out from under the held mic, then follows the latest waveform
/// bar through ONE controller on the calm spring (retargeted on every level
/// tick, never restarted), so it is smooth at any refresh rate; alone in its
/// own layer. Reduced motion: a still ring whose strength follows the level.
class AssistantVoiceMicHalo extends StatefulWidget {
  const AssistantVoiceMicHalo({super.key});

  /// The ring at silence: a little wider than the held mic.
  static const double rest = 2.1;

  /// Extra scale at full voice.
  static const double swell = 0.9;

  @override
  State<AssistantVoiceMicHalo> createState() => _AssistantVoiceMicHaloState();
}

class _AssistantVoiceMicHaloState extends State<AssistantVoiceMicHalo>
    with SingleTickerProviderStateMixin {
  static const double _alpha = 0.22;

  /// Under reduced motion the ring's strength spans this share at silence
  /// up to full at full voice.
  static const double _quietShare = 0.4;

  /// Built once, not on every tick of the recording clock.
  static final BoxDecoration _ring = BoxDecoration(
    shape: BoxShape.circle,
    color: AppColors.primary.withValues(alpha: _alpha),
  );

  /// Where the held mic grows from, so the ring stays around it.
  static const Alignment _growFrom = Alignment(0, 0.8);

  /// It enters from the held mic's own size.
  late final AnimationController _scale = AnimationController.unbounded(
    vsync: this,
    value: AssistantMotion.holdScale,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _follow(context.read<AssistantVoiceCubit>().state.waveform.latest);
  }

  /// Retargets the one spring at [level] from where the ring is now.
  void _follow(double level) {
    if (MotionGuard.reduced(context)) return;
    final target =
        AssistantVoiceMicHalo.rest + level * AssistantVoiceMicHalo.swell;
    _scale.animateWith(
      SpringSimulation(
        AppSprings.calm.spring,
        _scale.value,
        target,
        _scale.velocity,
      ),
    );
  }

  @override
  void dispose() {
    _scale.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MotionGuard.reduced(context)) {
      return BlocSelector<AssistantVoiceCubit, AssistantVoiceState, double>(
        selector: (state) => state.waveform.latest,
        builder: (context, level) => Transform.scale(
          scale: AssistantVoiceMicHalo.rest,
          alignment: _growFrom,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(
                alpha: _alpha * (_quietShare + (1 - _quietShare) * level),
              ),
            ),
            child: const SizedBox.square(dimension: AppSize.s48),
          ),
        ),
      );
    }
    return BlocListener<AssistantVoiceCubit, AssistantVoiceState>(
      listenWhen: (previous, current) =>
          previous.waveform.latest != current.waveform.latest,
      listener: (context, state) => _follow(state.waveform.latest),
      child: RepaintBoundary(
        child: ScaleTransition(
          scale: _scale,
          alignment: _growFrom,
          child: DecoratedBox(
            decoration: _ring,
            child: const SizedBox.square(dimension: AppSize.s48),
          ),
        ),
      ),
    );
  }
}
