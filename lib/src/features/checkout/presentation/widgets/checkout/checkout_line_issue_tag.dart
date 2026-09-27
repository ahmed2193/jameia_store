import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/domain/entities/cart_line_entity.dart';
import '../../../../../core/responsive/app_size.dart';

/// Why the server flagged a line, as a small tag on its items-sheet row:
/// red for a line that cannot be ordered ("Out of stock", "Unavailable"),
/// amber for a quantity the server cut back to what is in stock; nothing
/// for a line that is fine.
class CheckoutLineIssueTag extends StatelessWidget {
  const CheckoutLineIssueTag({super.key, required this.issue});

  final CartLineIssue issue;

  static const BorderRadius _radius = BorderRadius.all(
    Radius.circular(AppSize.r4),
  );

  @override
  Widget build(BuildContext context) {
    final (String, IconData, Color, Color, Color)? look = switch (issue) {
      CartLineIssue.none => null,
      CartLineIssue.outOfStock => (
        'checkout.line_out_of_stock',
        Icons.error_outline_rounded,
        AppColors.errorBg,
        AppColors.error,
        AppColors.errorDeep,
      ),
      CartLineIssue.unavailable || CartLineIssue.other => (
        'checkout.line_unavailable',
        Icons.error_outline_rounded,
        AppColors.errorBg,
        AppColors.error,
        AppColors.errorDeep,
      ),
      CartLineIssue.quantityReduced => (
        'checkout.line_qty_reduced',
        Icons.info_outline_rounded,
        AppColors.accent4Light,
        AppColors.warn,
        AppColors.accent4Foreground,
      ),
    };
    if (look == null) return const SizedBox.shrink();
    final (key, icon, fill, glyph, ink) = look;
    return DecoratedBox(
      decoration: BoxDecoration(color: fill, borderRadius: _radius),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.s6,
          vertical: AppSpacing.s2,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppSize.s12, color: glyph),
            const SizedBox(width: AppSpacing.s4),
            Flexible(
              child: Text(
                key.tr(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.tag.copyWith(color: ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
