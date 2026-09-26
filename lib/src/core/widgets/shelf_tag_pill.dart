import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_text_styles.dart';
import '../domain/entities/catalog_product_entity.dart';
import '../responsive/app_size.dart';

/// The one merchandising tag a listing card wears above its name — "Best
/// seller" or "Fresh" — from the product's backend tags. Keeps its line when
/// the product has none, so every card in a row lines up. The line grows
/// with the reader's text scale, so the pill's text is never clipped.
class ShelfTagPill extends StatelessWidget {
  const ShelfTagPill({super.key, required this.product});

  final CatalogProductEntity product;

  /// The line the pill takes at the default text scale (also reserved
  /// without one); it scales with the reader's text.
  static const double height = AppSize.s22;

  /// Backend tags, most telling first.
  static const String _bestSeller = 'best-seller';
  static const String _fresh = 'fresh';

  /// Whether [product] has a tag the pill shows — a page that need not line
  /// cards up skips the pill's empty line without one.
  static bool wears(CatalogProductEntity product) =>
      product.hasTag(_bestSeller) || product.hasTag(_fresh);

  @override
  Widget build(BuildContext context) {
    final (label, ink, plate) = product.hasTag(_bestSeller)
        ? (
            'shop.tag_best_seller',
            AppColors.accent1Dark,
            AppColors.accent1Light,
          )
        : product.hasTag(_fresh)
        ? ('shop.tag_fresh', AppColors.martGreenDark, AppColors.martGreenLight)
        : (null, AppColors.primaryText, AppColors.white);
    return SizedBox(
      height: MediaQuery.textScalerOf(context).scale(height),
      child: label == null
          ? null
          : Align(
              alignment: AlignmentDirectional.centerStart,
              child: Container(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpacing.s6,
                  vertical: AppSpacing.s2,
                ),
                decoration: BoxDecoration(
                  color: plate,
                  borderRadius: BorderRadius.circular(AppRadius.r6),
                ),
                child: Text(
                  label.tr(),
                  maxLines: 1,
                  style: AppTextStyles.bodyMedium.copyWith(color: ink),
                ),
              ),
            ),
    );
  }
}
