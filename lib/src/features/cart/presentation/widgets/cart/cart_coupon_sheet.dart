import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/domain/entities/cart_coupon_entity.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/utils/failure_message.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../domain/entities/cart_snapshot.dart';
import '../../cubit/cart_cubit.dart';

/// Bottom sheet that takes a coupon code and applies it on the server
/// (`POST /v1/cart/coupon`); closes on success, and shows a refused code
/// here rather than leaving it to the page: a snack bar would come up
/// UNDER this sheet, so a rejected coupon looked like nothing happened.
class CartCouponSheet extends StatefulWidget {
  const CartCouponSheet({super.key});

  @override
  State<CartCouponSheet> createState() => _CartCouponSheetState();
}

class _CartCouponSheetState extends State<CartCouponSheet> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    final applied = await context.read<CartCubit>().applyCoupon(
      _controller.text,
    );
    if (applied && mounted) context.pop();
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
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        AppSpacing.s16,
        AppSpacing.s16,
        AppSpacing.s16,
        AppSpacing.s16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'cart.coupon_title'.tr(),
            style: AppTextStyles.headingMedium.copyWith(
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          TextField(
            controller: _controller,
            autofocus: true,
            enabled: !busy,
            textCapitalization: TextCapitalization.characters,
            maxLength: CartCouponEntity.maxCodeLength,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _apply(),
            decoration: InputDecoration(
              hintText: 'cart.coupon_hint'.tr(),
              counterText: '',
            ),
          ),
          if (failure != null) ...[
            const SizedBox(height: AppSpacing.s8),
            Text(
              failure.localizedMessage,
              style: AppTextStyles.captionLarge.copyWith(
                color: AppColors.error,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.s12),
          AppButton(
            label: 'cart.coupon_apply'.tr(),
            loading: busy,
            onPressed: busy ? null : _apply,
          ),
        ],
      ),
    );
  }
}
