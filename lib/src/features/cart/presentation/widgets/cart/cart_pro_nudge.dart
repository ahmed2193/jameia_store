import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/routes.dart';
import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/domain/entities/catalog_product_entity.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/motion/size_fade_switcher.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../store_mode/presentation/cubit/pro_status_cubit.dart';
import '../../cubit/cart_cubit.dart';

/// Under the delivery row, for a customer without Jm3eia Pro whose basket
/// pays a delivery fee: "Save 0.750 KD on delivery with Jm3eia Pro · Join ›"
/// — the real fee, only while Pro includes free delivery, never for a
/// member. Opens the Pro page (a guest signs in from there). Grows in and
/// out with the fee.
class CartProNudge extends StatelessWidget {
  const CartProNudge({super.key});

  static const double _crown = AppSize.s16;
  static const double _chevron = AppSize.s16;

  @override
  Widget build(BuildContext context) {
    final offered = context.select<ProStatusCubit, bool>(
      (status) => status.state.offersFreeDelivery,
    );
    final feeFils = context.select<CartCubit, int>((cubit) {
      final totals = cubit.state.cart.totals;
      return totals.hasDeliveryFee ? totals.deliveryFeeWithoutExpressFils : 0;
    });
    final show = offered && feeFils > 0;
    return SizeFadeSwitcher(
      stateKey: show,
      child: !show
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.s6),
              child: Semantics(
                button: true,
                child: PressScale(
                  onTap: () => context.push(Routes.proMembership),
                  child: Container(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpacing.s10,
                      vertical: AppSpacing.s8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentVioletLight,
                      borderRadius: BorderRadius.circular(AppRadius.r2),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.workspace_premium_rounded,
                          size: _crown,
                          color: AppColors.accentViolet,
                        ),
                        const SizedBox(width: AppSpacing.s8),
                        Expanded(
                          child: Text(
                            'cart.pro_nudge'.tr(
                              namedArgs: {
                                'amount': Formatters.price(
                                  feeFils / CatalogProductEntity.filsPerDinar,
                                ),
                              },
                            ),
                            style: AppTextStyles.captionLarge.copyWith(
                              color: AppColors.primaryText,
                              fontWeight: AppTextStyles.medium,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s8),
                        Text(
                          'cart.pro_nudge_cta'.tr(),
                          style: AppTextStyles.captionLarge.copyWith(
                            color: AppColors.accentViolet,
                            fontWeight: AppTextStyles.bold,
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          size: _chevron,
                          color: AppColors.accentViolet,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
