import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/design/hero_icons.dart';
import '../../../../core/motion/entrance_cascade_item.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/light_sweep.dart';
import 'home_first_order_fee_line.dart';
import 'home_first_order_step.dart';

/// The words of the first-order dialog under its art: the [title], the
/// welcome line, the zone's fee struck through when the store knows it
/// ([deliveryFeeKd] > 0), how it works — fill the basket (from the
/// [minOrderKd] minimum when there is one), delivery on us, and for a guest
/// ([needsSignIn]) that an order needs an account — then "Start shopping"
/// ([onStart]). Each rises in after the one above it; the button's light
/// sweeps once the card is still.
class HomeFirstOrderDetails extends StatelessWidget {
  const HomeFirstOrderDetails({
    super.key,
    required this.title,
    required this.deliveryFeeKd,
    required this.minOrderKd,
    required this.needsSignIn,
    required this.onStart,
  });

  final String title;
  final double deliveryFeeKd;
  final double minOrderKd;
  final bool needsSignIn;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final basketBody = minOrderKd > 0
        ? 'home.first_order_step_basket_min'.tr(
            namedArgs: {'amount': Formatters.price(minOrderKd)},
          )
        : 'home.first_order_step_basket_body'.tr();
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.s24,
        AppSpacing.s20,
        AppSpacing.s24,
        AppSpacing.s16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EntranceCascadeItem.single(
            index: 1,
            child: Semantics(
              header: true,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.groupTitle,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          EntranceCascadeItem.single(
            index: 2,
            child: Text(
              'home.first_order_message'.tr(),
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
          ),
          if (deliveryFeeKd > 0) ...[
            const SizedBox(height: AppSpacing.s12),
            EntranceCascadeItem.single(
              index: 3,
              child: Center(child: HomeFirstOrderFeeLine(feeKd: deliveryFeeKd)),
            ),
          ],
          const SizedBox(height: AppSpacing.s20),
          EntranceCascadeItem.single(
            index: 3,
            child: HomeFirstOrderStep(
              icon: HeroIcons.basket,
              title: 'home.first_order_step_basket_title'.tr(),
              body: basketBody,
            ),
          ),
          const SizedBox(height: AppSpacing.s14),
          EntranceCascadeItem.single(
            index: 4,
            child: HomeFirstOrderStep(
              icon: HeroIcons.delivery,
              title: 'home.first_order_step_delivery_title'.tr(),
              body: 'home.first_order_step_delivery_body'.tr(),
            ),
          ),
          if (needsSignIn) ...[
            const SizedBox(height: AppSpacing.s14),
            EntranceCascadeItem.single(
              index: 5,
              child: HomeFirstOrderStep(
                icon: HeroIcons.person,
                title: 'home.first_order_step_sign_in_title'.tr(),
                body: 'home.first_order_step_sign_in_body'.tr(),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.s24),
          EntranceCascadeItem.single(
            index: 5,
            child: LightSweep(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: AppButton(
                label: 'home.first_order_cta'.tr(),
                onPressed: onStart,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
