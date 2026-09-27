import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/navigation/navigation.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../cubit/assistant_chat_cubit.dart';

/// "Talk to a person?": what happens, where the answer comes, what to do
/// meanwhile. Pops `true` on confirm.
class AssistantHandoffDialog extends StatelessWidget {
  const AssistantHandoffDialog({super.key});

  /// Asks, then hands the chat off (the cubit guards a double submit).
  static Future<void> confirm(BuildContext context) async {
    final cubit = context.read<AssistantChatCubit>();
    final confirmed = await showHeroDialog<bool>(
      context,
      barrierLabel: 'assistant.talk_to_person'.tr(),
      barrierColor: AppColors.overlayPrimary,
      pageBuilder: (_) => const AssistantHandoffDialog(),
    );
    if (confirmed ?? false) await cubit.handOff();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.s24,
        ),
        child: Material(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppSize.r8),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.s16,
              AppSpacing.s24,
              AppSpacing.s16,
              AppSpacing.s12,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.support_agent_rounded,
                  size: AppSize.s40,
                  color: AppColors.primaryDark,
                ),
                const SizedBox(height: AppSpacing.s12),
                Semantics(
                  header: true,
                  child: Text(
                    'assistant.handoff_dialog_title'.tr(),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.headingMedium,
                  ),
                ),
                const SizedBox(height: AppSpacing.s8),
                Text(
                  'assistant.handoff_dialog_body'.tr(),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.s8),
                Text(
                  'assistant.handoff_dialog_note'.tr(),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.captionLarge.copyWith(
                    color: AppColors.labelGrey,
                  ),
                ),
                const SizedBox(height: AppSpacing.s20),
                AppButton(
                  label: 'assistant.talk_to_person'.tr(),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
                const SizedBox(height: AppSpacing.s8),
                AppOutlineButton(
                  label: 'common.cancel'.tr(),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
