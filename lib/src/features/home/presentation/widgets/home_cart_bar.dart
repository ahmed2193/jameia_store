import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/routes.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_shadows.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/design/jameia_icons.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/utils/formatters.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../cart/presentation/cubit/cart_state.dart';

/// The basket bar under the home feed: how much is still missing before the
/// minimum order the server computed for the cart, or the basket summary
/// once the order can be placed. Hidden while the basket is empty.
class HomeCartBar extends StatelessWidget {
  const HomeCartBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartCubit, CartState>(
      buildWhen: (previous, current) =>
          previous.totalQty != current.totalQty ||
          previous.subtotalKd != current.subtotalKd,
      builder: (context, cart) {
        if (cart.isEmpty) return const SizedBox.shrink();
        final missing = cart.cart.totals.shortfallKd;
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.s12,
              AppSpacing.s6,
              AppSpacing.s12,
              AppSpacing.s8,
            ),
            child: GestureDetector(
              onTap: () => context.push(Routes.cartPreview),
              behavior: HitTestBehavior.opaque,
              child: Container(
                height: AppSize.s50,
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpacing.s16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppRadius.r3),
                  boxShadow: AppShadows.medium,
                ),
                child: Row(
                  children: [
                    const Icon(
                      JameiaIcons.cart,
                      size: AppSize.s22,
                      color: AppColors.brandForeground,
                    ),
                    const SizedBox(width: AppSpacing.s8),
                    if (missing > 0)
                      Expanded(
                        child: Text(
                          'home.min_order_prompt'.tr(
                            namedArgs: {'amount': Formatters.price(missing)},
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.brandForeground,
                            fontWeight: AppTextStyles.medium,
                          ),
                        ),
                      )
                    else ...[
                      Text(
                        'shop.cart_items'.tr(
                          namedArgs: {'count': '${cart.totalQty}'},
                        ),
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.brandForeground,
                          fontWeight: AppTextStyles.medium,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        Formatters.price(cart.subtotalKd),
                        style: AppTextStyles.headingMedium.copyWith(
                          color: AppColors.brandForeground,
                          fontWeight: AppTextStyles.bold,
                        ),
                      ),
                    ],
                    const SizedBox(width: AppSpacing.s4),
                    const Icon(
                      Icons.chevron_right,
                      size: AppSize.s20,
                      color: AppColors.brandForeground,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
