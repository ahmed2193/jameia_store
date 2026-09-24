import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/domain/entities/cart_line_entity.dart';
import '../../../../../core/domain/entities/cart_line_ref.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/jameia_card_image.dart';
import '../../../../../core/widgets/price_text.dart';
import '../../../../../core/widgets/qty_stepper.dart';
import '../../cubit/cart_cubit.dart';
import 'cart_line_issue_notice.dart';

/// One paid line: picture, name (+ variant), unit price with the struck
/// "was" price, the server's issue if any, and the stepper. A line that
/// cannot be bought any more offers "remove" instead of the stepper; a line
/// still on its way to the server is dimmed.
///
/// The tile selects its own line by [lineRef], so a tap on one stepper
/// rebuilds only that tile — every other line compares equal and stays.
class CartLineTile extends StatelessWidget {
  const CartLineTile({super.key, required this.lineRef});

  final CartLineRef lineRef;

  static const double _pendingOpacity = 0.6;

  @override
  Widget build(BuildContext context) {
    final line = context.select<CartCubit, CartLineEntity?>(
      (cubit) => cubit.state.cart.lineFor(lineRef),
    );
    if (line == null) return const SizedBox.shrink(); // removed mid-frame
    final cubit = context.read<CartCubit>();
    final variant = line.variantName;
    return Opacity(
      opacity: line.isLocalOnly ? _pendingOpacity : 1,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s12,
        ),
        child: Row(
          children: [
            JameiaCardImage(
              url: line.product.image,
              width: AppSize.s56,
              height: AppSize.s56,
              radius: AppRadius.r4,
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    line.product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.primaryText,
                    ),
                  ),
                  if (variant != null)
                    Text(
                      variant,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.captionLarge.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                  const SizedBox(height: AppSpacing.s4),
                  PriceText(
                    price: line.unitPriceKd,
                    originalPrice: line.compareAtKd,
                    size: AppSize.font14,
                  ),
                  if (line.hasIssue) CartLineIssueNotice(issue: line.issue),
                  if (!line.hasIssue && !line.canIncrement)
                    Text(
                      'cart.max_quantity'.tr(
                        namedArgs: {'count': '${line.maxQuantity}'},
                      ),
                      style: AppTextStyles.captionMedium.copyWith(
                        color: AppColors.tertiaryText,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.s8),
            if (line.blocksCheckout)
              TextButton(
                onPressed: () => cubit.removeLine(line),
                child: Text('cart.remove'.tr()),
              )
            else
              QtyStepper(
                qty: line.quantity,
                canAdd: line.canIncrement,
                onAdd: () {
                  if (!line.canIncrement) return;
                  HapticFeedback.selectionClick();
                  cubit.increment(line);
                },
                onRemove: () {
                  HapticFeedback.lightImpact();
                  cubit.decrement(line);
                },
              ),
          ],
        ),
      ),
    );
  }
}
