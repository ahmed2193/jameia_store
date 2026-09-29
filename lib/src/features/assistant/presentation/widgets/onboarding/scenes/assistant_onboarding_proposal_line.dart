import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

import '../../../../../../config/theme/app_colors.dart';
import '../../../../../../config/theme/app_spacing.dart';
import '../../../../../../config/theme/app_text_styles.dart';
import '../../../../../../core/responsive/app_size.dart';
import 'assistant_onboarding_item.dart';
import 'assistant_onboarding_item_glyph.dart';

/// One line of the cart demo's proposal — the item and how many — that
/// slides in from the start edge as [appear] goes to `1`.
class AssistantOnboardingProposalLine extends StatelessWidget {
  const AssistantOnboardingProposalLine({
    super.key,
    required this.item,
    required this.appear,
    this.glyphKey,
  });

  final AssistantOnboardingItem item;
  final double appear;

  /// Marks the glyph (a flight to the cart takes off from it).
  final GlobalKey? glyphKey;

  static const double _slide = AppSize.s12;
  static const double _glyph = AppSize.s22;

  @override
  Widget build(BuildContext context) {
    final shown = appear.clamp(0.0, 1.0);
    final fromStart = Directionality.of(context) == TextDirection.ltr
        ? -_slide
        : _slide;
    return Opacity(
      opacity: shown,
      child: Transform.translate(
        offset: Offset(fromStart * (1 - shown), 0),
        child: Row(
          children: [
            AssistantOnboardingItemGlyph(
              key: glyphKey,
              item: item,
              size: _glyph,
            ),
            const SizedBox(width: AppSpacing.s8),
            Expanded(
              child: Text(
                item.labelKey.tr(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.primaryText,
                ),
              ),
            ),
            Text(
              '×${item.quantity}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
