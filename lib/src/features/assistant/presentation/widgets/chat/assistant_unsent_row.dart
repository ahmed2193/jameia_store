import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../cubit/assistant_chat_cubit.dart';

/// Under a bubble that never reached the server: "Not sent · Tap to retry".
class AssistantUnsentRow extends StatelessWidget {
  const AssistantUnsentRow({
    super.key,
    required this.draftKey,
    required this.canRetry,
  });

  final String draftKey;
  final bool canRetry;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: canRetry
          ? () => context.read<AssistantChatCubit>().retryDraft(draftKey)
          : null,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: SuiSize.minTouchTarget),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: AppSize.s16,
              color: AppColors.error,
            ),
            const SizedBox(width: AppSpacing.s4),
            Text(
              'assistant.not_sent'.tr(),
              style: AppTextStyles.captionLarge.copyWith(
                color: AppColors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
