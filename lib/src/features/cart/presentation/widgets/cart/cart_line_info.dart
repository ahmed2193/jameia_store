import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/domain/entities/cart_line_entity.dart';
import '../../../../../core/motion/collapse_reveal.dart';
import 'cart_line_issue_notice.dart';
import 'cart_line_price.dart';

/// The text column of a cart row: the name (two lines at most), the variant,
/// the price, and the server's note — the issue tag, or "Max n" once the
/// stock cap is reached — which opens and folds as it comes and goes.
class CartLineInfo extends StatelessWidget {
  const CartLineInfo({super.key, required this.line});

  final CartLineEntity line;

  @override
  Widget build(BuildContext context) {
    final variant = line.variantName;
    final noted = line.hasIssue || !line.canIncrement;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          line.product.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.itemTitle,
        ),
        if (variant != null)
          Text(
            variant,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.meta,
          ),
        const SizedBox(height: AppSpacing.s4),
        CartLinePrice(line: line),
        CollapseReveal(
          visible: noted,
          child: noted
              ? Padding(
                  padding: const EdgeInsetsDirectional.only(top: AppSpacing.s6),
                  child: line.hasIssue
                      ? CartLineIssueNotice(issue: line.issue)
                      : Text(
                          'cart.max_quantity'.tr(
                            namedArgs: {'count': '${line.maxQuantity}'},
                          ),
                          style: AppTextStyles.meta,
                        ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
