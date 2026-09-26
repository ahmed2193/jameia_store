import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../domain/entities/assistant_block.dart';

/// `error`: part of the answer failed (a tool, a lookup). The server's
/// message is shown as sent; without one, a generic line.
class AssistantErrorCard extends StatelessWidget {
  const AssistantErrorCard({super.key, required this.block});

  final AssistantErrorBlock block;

  @override
  Widget build(BuildContext context) {
    final message = block.message;
    return Container(
      padding: const EdgeInsetsDirectional.all(AppSpacing.s12),
      decoration: BoxDecoration(
        color: AppColors.warnBg,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: AppSize.s18,
            color: AppColors.warn,
          ),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            child: Text(
              message == null || message.isEmpty
                  ? 'assistant.error_card'.tr()
                  : message,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
