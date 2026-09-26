import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/jameia_surface_card.dart';

/// "You earned N points" under the payment summary, on the brand wash.
class InvoiceLoyaltyNote extends StatelessWidget {
  const InvoiceLoyaltyNote({super.key, required this.points});

  final int points;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.gutter,
        AppSpacing.s12,
        AppSpacing.gutter,
        0,
      ),
      child: JameiaSurfaceCard(
        tone: JameiaSurfaceTone.brand,
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s12,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.stars_rounded,
              size: AppSize.s20,
              color: AppColors.brandDeep,
            ),
            const SizedBox(width: AppSpacing.s8),
            Expanded(
              child: Text(
                'orders.loyalty_earned'.tr(namedArgs: {'points': '$points'}),
                style: AppTextStyles.label.copyWith(color: AppColors.brandDeep),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
