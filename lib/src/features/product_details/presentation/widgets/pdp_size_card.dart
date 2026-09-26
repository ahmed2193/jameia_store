import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/domain/entities/catalog_product_entity.dart';
import '../../../../core/domain/entities/catalog_variant_entity.dart';
import '../../../../core/motion/haptics.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/shelf_marker_painter.dart';

/// One option of a variant product as a talabat size card: its name, then
/// its price — on a deal with the lime marker under it and the struck price
/// on a third line. The chosen card wears a 2 dp ink border (easing in), the
/// others a hairline. An option that cannot be bought is dimmed, says it is
/// out of stock and does not react.
class PdpSizeCard extends StatelessWidget {
  const PdpSizeCard({
    super.key,
    required this.variant,
    required this.selected,
    required this.pro,
    required this.width,
    required this.onTap,
    this.compareAtFils,
    this.reservesThirdLine = false,
  });

  final CatalogVariantEntity variant;
  final bool selected;
  final bool pro;
  final double width;
  final VoidCallback onTap;

  /// The struck price of a deal valid now, or `null`.
  final int? compareAtFils;

  /// Keep the third line's room without one, so a row of cards lines up.
  final bool reservesThirdLine;

  static const double _selectedBorder = AppSize.s2;
  static const double _border = AppSize.s1;

  /// Border plus padding: the content never moves as the border thickens.
  static const double _inset = AppSpacing.s12;

  /// The third line's height at the default text scale (captionLarge).
  static const double _captionLine = AppSize.s16;

  @override
  Widget build(BuildContext context) {
    final available = variant.isAvailable;
    final ink = available ? AppColors.primaryText : AppColors.disabledText;
    final border = selected ? _selectedBorder : _border;
    final compareAt = available ? compareAtFils : null;
    final lineStyle = AppTextStyles.itemTitle.copyWith(color: ink);
    final captionStyle = AppTextStyles.captionLarge;
    final price = Text(
      Formatters.price(variant.priceKdFor(pro: pro)),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: lineStyle,
    );
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      enabled: available,
      child: GestureDetector(
        onTap: available
            ? () {
                Haptics.selection();
                onTap();
              }
            : null,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: MotionGuard.duration(context, AppMotion.fast),
          curve: AppMotion.signature,
          width: width,
          padding: EdgeInsetsDirectional.all(_inset - border),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppSize.r12),
            border: Border.all(
              color: selected ? AppColors.primaryText : AppColors.divider,
              width: border,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                variant.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: lineStyle,
              ),
              const SizedBox(height: AppSpacing.s2),
              if (compareAt != null)
                CustomPaint(
                  painter: ShelfMarkerPainter(
                    progress: kAlwaysCompleteAnimation,
                    color: AppColors.proLime,
                    textDirection: Directionality.of(context),
                  ),
                  child: price,
                )
              else
                price,
              if (compareAt != null)
                Text(
                  Formatters.price(
                    compareAt / CatalogProductEntity.filsPerDinar,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: captionStyle.copyWith(
                    color: AppColors.tertiaryText,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: AppColors.tertiaryText,
                  ),
                )
              else if (!available)
                Text(
                  'catalog.out_of_stock'.tr(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: captionStyle.copyWith(color: AppColors.secondaryText),
                )
              else if (reservesThirdLine)
                SizedBox(
                  height: MediaQuery.textScalerOf(context).scale(_captionLine),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
