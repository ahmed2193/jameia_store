import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/domain/entities/cart_line_entity.dart';
import '../../../../../core/motion/haptics.dart';
import '../../../../../core/widgets/jameia_text_link.dart';
import '../../../../cart/presentation/cubit/cart_cubit.dart';
import 'checkout_line_frame.dart';
import 'checkout_line_issue_tag.dart';
import 'checkout_line_price.dart';
import 'checkout_red_tag.dart';

/// One paid line in the items sheet, Keeta-style: the 56 dp thumb, then the
/// bold name (two lines) at the top and, at the bottom, its tags — why the
/// server flagged it, "N% off" for a line on a deal — over "2x KD 0.600",
/// the struck "was" price and the line total. A line that blocks the order
/// (out of stock, unavailable) gets "Remove" under it. The facts read as one
/// element; "Remove" is its own button.
class CheckoutLineRow extends StatelessWidget {
  const CheckoutLineRow({super.key, required this.line});

  final CartLineEntity line;

  void _remove(BuildContext context) {
    Haptics.selection();
    context.read<CartCubit>().removeLine(line);
  }

  @override
  Widget build(BuildContext context) {
    final variant = line.variantName;
    final percent = line.savePercent;
    final tagged = line.hasIssue || percent != null;
    return CheckoutLineFrame(
      imageUrl: line.product.image,
      top: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            line.product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.label.copyWith(
              fontWeight: AppTextStyles.bold,
              color: AppColors.primaryText,
            ),
          ),
          if (variant != null && variant.isNotEmpty)
            Text(
              variant,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
        ],
      ),
      bottom: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (tagged)
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                vertical: AppSpacing.s4,
              ),
              child: Wrap(
                spacing: AppSpacing.s6,
                runSpacing: AppSpacing.s4,
                children: [
                  if (line.hasIssue) CheckoutLineIssueTag(issue: line.issue),
                  if (percent != null)
                    CheckoutRedTag(
                      label: 'checkout.line_off'.tr(
                        namedArgs: {'percent': '$percent'},
                      ),
                    ),
                ],
              ),
            ),
          CheckoutLinePrice(line: line),
        ],
      ),
      below: line.blocksCheckout
          ? Align(
              alignment: AlignmentDirectional.centerStart,
              child: JameiaTextLink(
                label: 'checkout.line_remove'.tr(),
                color: AppColors.errorDeep,
                navigates: false,
                onTap: () => _remove(context),
              ),
            )
          : null,
    );
  }
}
