import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/domain/entities/cart_coupon_entity.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/motion/collapse_reveal.dart';
import '../../../../../core/motion/haptics.dart';
import '../../../../../core/motion/shake_x.dart';
import '../../../../../core/utils/failure_message.dart';
import '../../../../../core/widgets/hero_input_decoration.dart';
import '../../../../../core/widgets/keyboard_inset_padding.dart';
import '../../../../../core/widgets/hero_sheet_header.dart';
import '../../../../../core/widgets/hero_submit_button.dart';
import '../../../domain/entities/cart_snapshot.dart';
import '../../cubit/cart_cubit.dart';

/// Bottom sheet that takes a coupon code and applies it on the server
/// (`POST /v1/cart/coupon`); closes on success (the button's check shows
/// while it closes), and shows a refused code here rather than leaving it
/// to the page: a snack bar would come up UNDER this sheet, so a rejected
/// coupon looked like nothing happened. A refusal shakes the field.
class CartCouponSheet extends StatefulWidget {
  const CartCouponSheet({super.key});

  @override
  State<CartCouponSheet> createState() => _CartCouponSheetState();
}

class _CartCouponSheetState extends State<CartCouponSheet> {
  final TextEditingController _controller = TextEditingController();

  /// Bumped on every refused code, to shake the field.
  int _refusals = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    final applied = await context.read<CartCubit>().applyCoupon(
      _controller.text,
    );
    if (!mounted) return;
    if (applied) {
      Haptics.done();
      context.pop();
      return;
    }
    Haptics.refuse();
    setState(() => _refusals++);
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.select<CartCubit, bool>(
      (cubit) => cubit.state.busyAction == CartAction.coupon,
    );
    final failure = context.select<CartCubit, Failure?>(
      (cubit) => cubit.state.failedAction == CartAction.coupon
          ? cubit.state.failure
          : null,
    );
    final coupon = context.select<CartCubit, CartCouponEntity?>(
      (cubit) => cubit.state.cart.coupon,
    );
    // The keyboard inset is read below this build, so the keyboard sliding
    // in does not rebuild the sheet.
    return KeyboardInsetPadding(
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HeroSheetHeader(title: 'cart.coupon_title'.tr()),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.gutter,
                AppSpacing.s8,
                AppSpacing.gutter,
                AppSpacing.s16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ShakeX(
                    shakeKey: _refusals,
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      enabled: !busy,
                      textCapitalization: TextCapitalization.characters,
                      maxLength: CartCouponEntity.maxCodeLength,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _apply(),
                      style: AppTextStyles.itemTitle,
                      cursorColor: AppColors.primaryText,
                      decoration: HeroInputDecoration.outlined(
                        hintText: 'cart.coupon_hint'.tr(),
                        counterText: '',
                      ),
                    ),
                  ),
                  // The refusal is ONE text below the field (never the
                  // field's errorText), opening and folding with it.
                  CollapseReveal(
                    visible: failure != null,
                    child: failure == null
                        ? const SizedBox.shrink()
                        : Padding(
                            padding: const EdgeInsetsDirectional.only(
                              top: AppSpacing.s8,
                            ),
                            child: Text(
                              failure.localizedMessage,
                              style: AppTextStyles.meta.copyWith(
                                color: AppColors.errorDeep,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  HeroSubmitButton(
                    label: 'cart.coupon_apply'.tr(),
                    loading: busy,
                    success: coupon != null,
                    successLabel: coupon == null
                        ? null
                        : 'cart.coupon_applied'.tr(
                            namedArgs: {'code': coupon.code},
                          ),
                    onPressed: busy ? null : _apply,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
