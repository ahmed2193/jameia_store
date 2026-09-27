import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../cubit/assistant_voice_cubit.dart';
import '../../cubit/assistant_voice_state.dart';

/// A soft ring behind the held mic that swells with the customer's voice:
/// "I hear you". It follows the latest waveform bar, so it redraws at the
/// recording clock's pace, alone in its own layer.
class AssistantVoiceMicHalo extends StatelessWidget {
  const AssistantVoiceMicHalo({super.key});

  /// The ring at silence: a little wider than the held mic.
  static const double _rest = 2.1;

  /// Extra scale at full voice.
  static const double _swell = 0.9;

  static const double _alpha = 0.22;

  /// Built once, not on every tick of the recording clock.
  static final BoxDecoration _ring = BoxDecoration(
    shape: BoxShape.circle,
    color: AppColors.primary.withValues(alpha: _alpha),
  );

  /// Where the held mic grows from, so the ring stays around it.
  static const Alignment _growFrom = Alignment(0, 0.8);

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AssistantVoiceCubit, AssistantVoiceState, double>(
      selector: (state) => state.waveform.latest,
      builder: (context, level) => RepaintBoundary(
        child: AnimatedScale(
          scale: _rest + level * _swell,
          alignment: _growFrom,
          duration: MotionGuard.duration(
            context,
            AssistantVoiceCubit.defaultTick,
          ),
          curve: AppMotion.decelerate,
          child: DecoratedBox(
            decoration: _ring,
            child: const SizedBox.square(dimension: AppSize.s48),
          ),
        ),
      ),
    );
  }
}
