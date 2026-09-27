import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/core_widgets.dart';

/// The answer body of an open topic, under a hairline.
class SupportFaqAnswer extends StatelessWidget {
  const SupportFaqAnswer({super.key, required this.answerKey});

  /// i18n key of the answer.
  final String answerKey;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.s14,
        0,
        AppSpacing.s14,
        AppSpacing.s14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ThinDivider(),
          const SizedBox(height: AppSpacing.s12),
          Text(
            answerKey.tr(),
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.secondaryText,
              height: AppSize.lh1_5,
            ),
          ),
        ],
      ),
    );
  }
}
