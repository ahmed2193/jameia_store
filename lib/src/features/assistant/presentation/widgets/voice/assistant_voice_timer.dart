import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../cubit/assistant_voice_cubit.dart';
import '../../cubit/assistant_voice_state.dart';

/// The recording's length, `0:07`: it rebuilds once a second, not on every
/// tick of the recording clock, and its digits keep their width.
class AssistantVoiceTimer extends StatelessWidget {
  const AssistantVoiceTimer({super.key});

  static const int _secondsPerMinute = 60;
  static const int _secondsWidth = 2;

  /// `m:ss` with Western digits, like every number in the app.
  static String format(int seconds) {
    final minutes = seconds ~/ _secondsPerMinute;
    final rest = (seconds % _secondsPerMinute).toString().padLeft(
      _secondsWidth,
      '0',
    );
    return '$minutes:$rest';
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AssistantVoiceCubit, AssistantVoiceState, int>(
      selector: (state) => state.elapsed.inSeconds,
      builder: (context, seconds) => Text(
        format(seconds),
        textDirection: TextDirection.ltr,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.primaryText,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
