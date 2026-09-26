import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/domain/entities/cart_line_entity.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/jameia_money_text.dart';

/// One cart line being ordered, flat on the page: the name (and variant), the
/// pieces, and the line total at the end. Read as one element.
class CheckoutLineRow extends StatelessWidget {
  const CheckoutLineRow({super.key, required this.line});

  final CartLineEntity line;

  @override
  Widget build(BuildContext context) {
    final variant = line.variantName;
    return MergeSemantics(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSize.s56),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.gutter,
            vertical: AppSpacing.s12,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      line.product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.itemTitle,
                    ),
                    if (variant != null && variant.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.s2),
                      Text(
                        variant,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.meta,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.s2),
                    Text(
                      'checkout.item_qty'.tr(
                        namedArgs: {'count': '${line.quantity}'},
                      ),
                      style: AppTextStyles.meta,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              JameiaMoneyText(kd: line.lineTotalKd, style: AppTextStyles.label),
            ],
          ),
        ),
      ),
    );
  }
}
