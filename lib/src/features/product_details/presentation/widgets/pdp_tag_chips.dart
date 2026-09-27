import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/domain/entities/catalog_merch_tag.dart';

/// The product's merchandising tags at the top of the sheet, Hero
/// style: every tag it wears ("Best seller", "Fresh") as a flat grey chip,
/// wrapping on a narrow screen. The labels are the listing cards' own.
class PdpTagChips extends StatelessWidget {
  const PdpTagChips({super.key, required this.tags});

  final List<CatalogMerchTag> tags;

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.bodyLarge.copyWith(
      color: AppColors.secondaryText,
    );
    return Wrap(
      spacing: AppSpacing.s8,
      runSpacing: AppSpacing.s8,
      children: [
        for (final tag in tags)
          DecoratedBox(
            decoration: const BoxDecoration(
              color: AppColors.smallBackground,
              borderRadius: BorderRadius.all(Radius.circular(AppRadius.r6)),
            ),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.s8,
                vertical: AppSpacing.s4,
              ),
              child: Text(tag.labelKey.tr(), style: style),
            ),
          ),
      ],
    );
  }
}
