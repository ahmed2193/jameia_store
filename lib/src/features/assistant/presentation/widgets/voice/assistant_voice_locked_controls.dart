import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_icon.dart';
import '../../cubit/assistant_voice_cubit.dart';

/// Where the text field was, during a hands-free recording: the bin at the
/// start and, in the middle, stop — which puts the words in the message
/// box to read over. The mic beside them has become the send button.
class AssistantVoiceLockedControls extends StatelessWidget {
  const AssistantVoiceLockedControls({super.key});

  @override
  Widget build(BuildContext context) {
    final voice = context.read<AssistantVoiceCubit>();
    return Row(
      children: [
        IconButton(
          tooltip: 'assistant.voice.delete'.tr(),
          onPressed: voice.discard,
          icon: const HeroIcon(
            HeroIcons.trash,
            size: AppSize.s24,
            color: AppColors.secondaryText,
          ),
        ),
        Expanded(
          child: Center(
            child: IconButton(
              tooltip: 'assistant.voice.stop_and_edit'.tr(),
              onPressed: voice.review,
              icon: const HeroIcon(
                HeroIcons.stopCircle,
                size: AppSize.s30,
                color: AppColors.error,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
