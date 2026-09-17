import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/design/jameia_assets.dart';
import '../../../../../core/design/jameia_icons.dart';
import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/widgets/core_widgets.dart';
import '../../../domain/entities/checkout_draft.dart';
import 'checkout_radio.dart';

/// Payment method picker — uses real Jameia Apple Pay / Google Pay image assets;
/// COD uses icon. Radio is same filled-circle as drop-off.
class PaymentSection extends StatelessWidget {
  const PaymentSection({
    super.key,
    required this.selected,
    required this.onSelect,
  });
  final PaymentMethod selected;
  final ValueChanged<PaymentMethod> onSelect;

  @override
  Widget build(BuildContext context) {
    Widget tile(PaymentMethod value, Widget leadingWidget, String label) {
      final on = value == selected;
      return InkWell(
        onTap: () => onSelect(value),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s16,
            vertical: AppSpacing.s14,
          ),
          child: Row(
            children: [
              leadingWidget,
              const SizedBox(width: AppSpacing.s12),
              Expanded(child: Text(label, style: AppTextStyles.bodyLarge)),
              // Jameia radio — b3caa4 (selected #000) / ieba4d (unselected #666):
              // 16×16, 1.9dp ring; selected adds a filled centre dot.
              CheckoutRadio(selected: on),
            ],
          ),
        ),
      );
    }

    Widget payIcon(String asset, {double size = 28}) => Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) =>
          const Icon(JameiaIcons.pay, size: 22, color: AppColors.secondaryText),
    );

    return Container(
      color: AppColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.s16),
          // Section title: 16dp/w500 ph:16dp mb:12dp (d9ac92)
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.s16,
            ),
            child: Text(
              'checkout.payment_title'.tr(),
              style: AppTextStyles.headingMedium.copyWith(
                fontWeight: AppTextStyles.medium,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          tile(
            PaymentMethod.cod,
            const Icon(
              Icons.money_rounded,
              size: 24,
              color: AppColors.secondaryText,
            ),
            'checkout.pay_cod'.tr(),
          ),
          const ThinDivider(indent: AppSpacing.s16),
          tile(
            PaymentMethod.applePay,
            payIcon(JameiaAssets.applePay),
            'checkout.pay_apple'.tr(),
          ),
          const ThinDivider(indent: AppSpacing.s16),
          tile(
            PaymentMethod.googlePay,
            payIcon(JameiaAssets.googlePay),
            'checkout.pay_google'.tr(),
          ),
          const SizedBox(height: AppSpacing.s4),
        ],
      ),
    );
  }
}
