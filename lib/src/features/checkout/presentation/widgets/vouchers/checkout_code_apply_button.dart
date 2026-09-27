import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/domain/entities/cart_coupon_entity.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_submit_button.dart';
import '../../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../../cart/presentation/cubit/cart_state.dart';

/// The code sheet's sticker "Apply": live only for a code of an accepted
/// length and while no other cart action runs. Only this button listens to
/// the field, so a keystroke rebuilds nothing else of the sheet.
class CheckoutCodeApplyButton extends StatelessWidget {
  const CheckoutCodeApplyButton({
    super.key,
    required this.controller,
    required this.loading,
    required this.success,
    required this.onPressed,
    required this.onBlocked,
  });

  final TextEditingController controller;

  /// The code went out and has not landed on the cart yet.
  final bool loading;

  /// The code landed (the check shows while the sheet closes).
  final bool success;
  final VoidCallback onPressed;

  /// A tap while it is not live (says why when the length is wrong).
  final VoidCallback onBlocked;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<CartCubit, CartState, bool>(
      selector: (state) => state.isBusy,
      builder: (context, busy) => ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) => HeroSubmitButton(
          label: 'checkout.code_apply'.tr(),
          sticker: true,
          height: AppSize.s48,
          enabled: !busy && CartCouponEntity.acceptsCode(value.text),
          loading: loading,
          success: success,
          onPressed: onPressed,
          onBlocked: onBlocked,
        ),
      ),
    );
  }
}
