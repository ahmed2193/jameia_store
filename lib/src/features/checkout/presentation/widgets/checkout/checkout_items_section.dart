import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/domain/entities/cart_line_entity.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../cart/presentation/cubit/cart_cubit.dart';
import 'checkout_section_title.dart';

/// The cart lines being ordered: name, pieces, line total.
class CheckoutItemsSection extends StatelessWidget {
  const CheckoutItemsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final lines = context.select<CartCubit, List<CartLineEntity>>(
      (cubit) => cubit.state.cart.lines,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        CheckoutSectionTitle('checkout.items_title'.tr()),
        for (final line in lines)
          Padding(
            key: ValueKey<String>('checkout-line:${line.ref}'),
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.s16,
              vertical: AppSpacing.s6,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    line.variantName == null
                        ? line.product.name
                        : '${line.product.name} · ${line.variantName}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primaryText,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.s8),
                Text(
                  'checkout.item_qty'.tr(
                    namedArgs: {'count': '${line.quantity}'},
                  ),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(width: AppSpacing.s12),
                Text(
                  Formatters.price(line.lineTotalKd),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primaryText,
                    fontWeight: AppTextStyles.medium,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.s8),
      ],
    );
  }
}
