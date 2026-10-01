import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/hero_icon.dart';

/// One condition line under an offer ("On orders over KD 5.000", "Up to
/// KD 3.000 off", "Valid until …"): a small grey glyph and the text.
/// [emphasized] lines (what the cart must hold) read in ink.
class OfferTermRow extends StatelessWidget {
  const OfferTermRow({
    super.key,
    required this.icon,
    required this.text,
    this.emphasized = false,
  });

  final IconData icon;
  final String text;
  final bool emphasized;

  static const double _glyph = AppSize.s16;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: HeroIcon(icon, size: _glyph, color: AppColors.secondaryText),
        ),
        const SizedBox(width: AppSpacing.s6),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              color: emphasized
                  ? AppColors.primaryText
                  : AppColors.secondaryText,
              fontWeight: emphasized
                  ? AppTextStyles.medium
                  : AppTextStyles.regular,
            ),
          ),
        ),
      ],
    );
  }
}
