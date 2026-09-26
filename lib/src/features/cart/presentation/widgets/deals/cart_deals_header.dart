import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/widgets/round_outlined_button.dart';

/// The sheet's head: close at the start, "Buy more, save more" and the
/// "grab all offers" line centred.
class CartDealsHeader extends StatelessWidget {
  const CartDealsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.all(AppSpacing.s12),
      child: Stack(
        alignment: AlignmentDirectional.topStart,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.s48,
              vertical: AppSpacing.s4,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    'cart.deals_title'.tr(),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.sectionTitle.copyWith(
                      color: AppColors.black,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  'cart.deals_subtitle'.tr(),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.labelGrey,
                  ),
                ),
              ],
            ),
          ),
          RoundOutlinedButton(
            icon: Icons.close_rounded,
            label: MaterialLocalizations.of(context).closeButtonLabel,
            onTap: () => context.pop(),
          ),
        ],
      ),
    );
  }
}
