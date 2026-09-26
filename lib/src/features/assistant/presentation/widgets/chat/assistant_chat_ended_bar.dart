import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../cubit/assistant_chat_cubit.dart';

/// Replaces the composer once the conversation is closed (or gone): the
/// chat reads on, a new one starts from here.
class AssistantChatEndedBar extends StatelessWidget {
  const AssistantChatEndedBar({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.all(AppSpacing.s12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'assistant.chat_ended'.tr(),
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
              const SizedBox(height: AppSpacing.s8),
              AppButton(
                label: 'assistant.start_new_chat'.tr(),
                onPressed: () =>
                    context.read<AssistantChatCubit>().startNewChat(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
