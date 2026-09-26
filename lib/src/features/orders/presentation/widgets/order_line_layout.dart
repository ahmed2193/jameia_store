import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';

/// The geometry every order line shares, so paid and free rows read as one
/// list: the quantity (`2×`, one left-to-right tabular run), the name (two
/// lines) over an optional [subtitle], and an optional [trailing] value.
/// Flat — the list around it draws the hairlines. Read out as one node.
class OrderLineLayout extends StatelessWidget {
  const OrderLineLayout({
    super.key,
    required this.quantity,
    required this.name,
    this.subtitle = '',
    this.subtitleColor,
    this.trailing,
  });

  static final TextStyle _quantityStyle = AppTextStyles.label.copyWith(
    color: AppColors.secondaryText,
    fontFeatures: AppTextStyles.tabular,
  );

  final int quantity;
  final String name;

  /// Hidden when empty.
  final String subtitle;

  /// Defaults to the grey of [AppTextStyles.meta].
  final Color? subtitleColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final trailing = this.trailing;
    final subtitleColor = this.subtitleColor;
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          vertical: AppSpacing.s12,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Directionality(
              textDirection: TextDirection.ltr,
              child: Text('$quantity×', style: _quantityStyle),
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.itemTitle,
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: subtitleColor == null
                          ? AppTextStyles.meta
                          : AppTextStyles.meta.copyWith(color: subtitleColor),
                    ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.s12),
              trailing,
            ],
          ],
        ),
      ),
    );
  }
}
