import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

// TODO(P2.9-boundary): [lines] are the live cart's [CartItem]s (owned by the
// cart feature), not orders data. Keep the core [CartItem] DTO here rather than
// an orders entity — the cart feature owns this boundary (CartState.lines).
import '../../../../../core/data/models/models.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';

/// Compact preview of the cart lines inside [CartCard] — up to two lines
/// (name ×qty), then a "+N more items" summary. Mirrors [OrderItems].
class CartItemsPreview extends StatelessWidget {
  const CartItemsPreview({super.key, required this.lines});

  final List<CartItem> lines;

  @override
  Widget build(BuildContext context) {
    final shown = lines.length > 2 ? lines.sublist(0, 2) : lines;
    final extra = lines.length - shown.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in shown)
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.s2),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    line.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.secondaryText,
                      fontWeight: AppTextStyles.regular,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.s8),
                Text(
                  '×${line.qty}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.tertiaryText,
                    fontWeight: AppTextStyles.regular,
                  ),
                ),
              ],
            ),
          ),
        if (extra > 0)
          Text(
            'orders.more_items'.tr(namedArgs: {'count': '$extra'}),
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.tertiaryText,
            ),
          ),
      ],
    );
  }
}
