import 'package:flutter/material.dart';

import '../../../../core/data/models/catalog.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

/// KeeTa "KingKong" entry grid — the row of round category icons under the home
/// header. 8 items in 2 rows of 4.
class KingKongGrid extends StatelessWidget {
  const KingKongGrid({super.key, required this.items});
  final List<KingKongItem> items;

  static Color _hex(String s) =>
      Color(int.parse(s.replaceFirst('#', '0xFF')));

  static IconData _icon(String name) => switch (name) {
        'restaurant' => Icons.restaurant_rounded,
        'shopping_basket' => Icons.shopping_basket_rounded,
        'local_pharmacy' => Icons.local_pharmacy_rounded,
        'shopping_bag' => Icons.shopping_bag_rounded,
        'set_meal' => Icons.set_meal_rounded,
        'sell' => Icons.sell_rounded,
        'local_florist' => Icons.local_florist_rounded,
        _ => Icons.grid_view_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pageMargin, vertical: AppSpacing.s8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: AppSpacing.s12,
        childAspectRatio: 0.86,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final it = items[i];
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _hex(it.color).withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(AppRadius.r3),
              ),
              child: Icon(_icon(it.icon), color: _hex(it.color), size: 26),
            ),
            const SizedBox(height: 4),
            Text(it.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.captionLarge
                    .copyWith(color: AppColors.primaryText)),
          ],
        );
      },
    );
  }
}
