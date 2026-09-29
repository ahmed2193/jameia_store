import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/utils/failure_message.dart';

/// Why a proposal's confirm failed, under its button: an icon and the words
/// (never colour or motion alone). A screen reader hears it once.
class AssistantCartActionError extends StatelessWidget {
  const AssistantCartActionError({super.key, required this.failure});

  final Failure failure;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: AppSpacing.s8),
      child: Semantics(
        liveRegion: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: AppSize.s16,
              color: AppColors.error,
            ),
            const SizedBox(width: AppSpacing.s6),
            Expanded(
              child: Text(
                failure.localizedMessage,
                style: AppTextStyles.captionLarge.copyWith(
                  color: AppColors.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
