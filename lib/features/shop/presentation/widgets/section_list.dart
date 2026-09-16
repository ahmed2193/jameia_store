import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/data/models/models.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'product_row_tile.dart';

/// One section as a white rounded card: header + all its product rows.
/// SPL realises only on-screen CARDS; a card builds its rows eagerly (a card
/// = one SPL item) — acceptable, and required for index-exact scrollTo.
///
/// The header's active highlight reads [activeRank] via a [ValueListenableBuilder]
/// so a scroll-driven active-index change repaints ONLY the accent bar/title of
/// the affected cards — never the whole list, never via `setState`.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.index,
    required this.section,
    required this.shop,
    required this.activeRank,
  });

  final int index;
  final MenuSection section;
  final Shop shop;
  final ValueListenable<int> activeRank;

  @override
  Widget build(BuildContext context) {
    final products = section.products;
    return Container(
      margin: const EdgeInsetsDirectional.only(start: 9, end: 9, bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.r3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHeader(
            section: section,
            index: index,
            activeRank: activeRank,
          ),
          for (var i = 0; i < products.length; i++) ...[
            if (i > 0)
              const Padding(
                padding: EdgeInsetsDirectional.only(start: 12),
                child: Divider(
                  height: 1,
                  thickness: 0.5,
                  color: AppColors.overlayDivider,
                ),
              ),
            ProductRowTile(product: products[i], shop: shop),
          ],
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

/// Section header — accent bar + title + count. Sits at the top of each
/// section card; the active section's bar/title highlight. The highlight reads
/// [activeRank] directly so it never depends on a body-scroll `setState`.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.section,
    required this.index,
    required this.activeRank,
  });

  final MenuSection section;
  final int index;
  final ValueListenable<int> activeRank;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: 12,
        top: 14,
        end: 12,
        bottom: 6,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ValueListenableBuilder<int>(
            valueListenable: activeRank,
            builder: (context, active, _) {
              final selected = index == active;
              return AnimatedContainer(
                duration: MotionGuard.duration(context, AppMotion.fast),
                curve: MotionGuard.curve(context, AppMotion.standard),
                width: 3,
                height: selected ? 22 : 10,
                margin: const EdgeInsetsDirectional.only(end: AppSpacing.s8),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary
                      : AppColors.primary.withValues(alpha: 0),
                  borderRadius: BorderRadius.circular(AppRadius.r7),
                ),
              );
            },
          ),
          Expanded(
            child: Text(
              section.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.headingLarge.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: AppSize.font16,
                color: AppColors.primaryText,
              ),
            ),
          ),
          if (section.products.isNotEmpty)
            Text(
              '${section.products.length}',
              style: AppTextStyles.captionLarge.copyWith(
                color: AppColors.tertiaryText,
              ),
            ),
        ],
      ),
    );
  }
}

/// A single white card listing the sub-category's directProducts (0-rank sub).
class DirectProductsCard extends StatelessWidget {
  const DirectProductsCard({
    super.key,
    required this.products,
    required this.shop,
  });
  final List<Product> products;
  final Shop shop;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsetsDirectional.only(start: 9, end: 9, bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.r3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 6),
          for (var i = 0; i < products.length; i++) ...[
            if (i > 0)
              const Padding(
                padding: EdgeInsetsDirectional.only(start: 12),
                child: Divider(
                  height: 1,
                  thickness: 0.5,
                  color: AppColors.overlayDivider,
                ),
              ),
            ProductRowTile(product: products[i], shop: shop),
          ],
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

/// Empty-state line for a sub-category with no products.
class EmptySubMessage extends StatelessWidget {
  const EmptySubMessage({super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: Center(
        child: Text(
          'shop.no_products_here'.tr(),
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.tertiaryText,
          ),
        ),
      ),
    );
  }
}
