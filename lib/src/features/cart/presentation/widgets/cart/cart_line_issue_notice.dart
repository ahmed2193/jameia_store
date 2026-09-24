import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/domain/entities/cart_line_entity.dart';

/// Why the server flagged a line, in the line's tile; nothing when it is
/// fine.
class CartLineIssueNotice extends StatelessWidget {
  const CartLineIssueNotice({super.key, required this.issue});

  final CartLineIssue issue;

  @override
  Widget build(BuildContext context) {
    final String text;
    final Color color;
    switch (issue) {
      case CartLineIssue.none:
        return const SizedBox.shrink();
      case CartLineIssue.outOfStock:
        text = 'cart.issue_out_of_stock'.tr();
        color = AppColors.error;
      case CartLineIssue.quantityReduced:
        text = 'cart.issue_quantity_reduced'.tr();
        color = AppColors.warn;
      case CartLineIssue.unavailable:
      case CartLineIssue.other:
        text = 'cart.issue_unavailable'.tr();
        color = AppColors.error;
    }
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.captionMedium.copyWith(
        color: color,
        fontWeight: AppTextStyles.medium,
      ),
    );
  }
}
