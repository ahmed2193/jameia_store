import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../domain/entities/assistant_voice_waveform.dart';
import '../../cubit/assistant_voice_cubit.dart';
import '../../cubit/assistant_voice_state.dart';
import 'assistant_voice_wave_painter.dart';

/// The live waveform of a hands-free recording. Only this layer repaints
/// on the recording clock; nothing around it rebuilds.
class AssistantVoiceWaveView extends StatelessWidget {
  const AssistantVoiceWaveView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      AssistantVoiceCubit,
      AssistantVoiceState,
      AssistantVoiceWaveform
    >(
      selector: (state) => state.waveform,
      builder: (context, waveform) => RepaintBoundary(
        child: SizedBox(
          height: AppSize.s28,
          width: double.infinity,
          child: CustomPaint(
            painter: AssistantVoiceWavePainter(
              levels: waveform.levels,
              color: AppColors.primaryDark,
              trackColor: AppColors.disabledText,
              textDirection: Directionality.of(context),
            ),
          ),
        ),
      ),
    );
  }
}
