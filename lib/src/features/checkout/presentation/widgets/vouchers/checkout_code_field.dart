import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/domain/entities/cart_coupon_entity.dart';
import '../../../../../core/motion/collapse_reveal.dart';
import '../../../../../core/motion/shake_x.dart';
import '../../../../../core/widgets/jameia_input_decoration.dart';

/// The code sheet's field: capital letters, at most
/// [CartCouponEntity.maxCodeLength] characters, "done" applies. A refusal
/// shakes it ([shakeKey] changes) and opens ONE error line under it
/// ([error]) — never the field's own error text.
class CheckoutCodeField extends StatelessWidget {
  const CheckoutCodeField({
    super.key,
    required this.controller,
    required this.shakeKey,
    required this.error,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final Object shakeKey;
  final String? error;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    final message = error;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ShakeX(
          shakeKey: shakeKey,
          child: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            maxLength: CartCouponEntity.maxCodeLength,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onSubmitted(),
            style: AppTextStyles.itemTitle,
            cursorColor: AppColors.primaryText,
            decoration: JameiaInputDecoration.outlined(
              hintText: 'checkout.code_hint'.tr(),
              counterText: '',
            ),
          ),
        ),
        CollapseReveal(
          visible: message != null,
          child: message == null
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsetsDirectional.only(top: AppSpacing.s8),
                  child: Text(
                    message,
                    style: AppTextStyles.meta.copyWith(
                      color: AppColors.errorDeep,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
