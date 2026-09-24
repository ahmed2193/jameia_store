import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../cubit/cart_cubit.dart';

/// Shown while taps could not reach the server (offline): they are kept and
/// retried; the button retries now.
class CartSyncBanner extends StatelessWidget {
  const CartSyncBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final unsynced = context.select<CartCubit, bool>(
      (cubit) => cubit.state.isUnsynced,
    );
    if (!unsynced) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.s12,
        AppSpacing.s8,
        AppSpacing.s12,
        0,
      ),
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.s12,
        vertical: AppSpacing.s8,
      ),
      decoration: BoxDecoration(
        color: AppColors.warnBg,
        borderRadius: BorderRadius.circular(AppRadius.r4),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: AppSize.s20,
            color: AppColors.warn,
          ),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            child: Text(
              'cart.unsynced'.tr(),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primaryText,
              ),
            ),
          ),
          TextButton(
            onPressed: () => context.read<CartCubit>().prepareCheckout(),
            child: Text('cart.retry'.tr()),
          ),
        ],
      ),
    );
  }
}
