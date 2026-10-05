import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/responsive/app_size.dart';
import '../glyph_disc.dart';

/// What leads a row of the address search, Google Maps style: a glyph on a
/// disc and, under it, how far the place is ([distance]). Every row's is as
/// wide, so the names line up; a long distance shrinks rather than wraps.
class SuggestionLeading extends StatelessWidget {
  const SuggestionLeading({
    super.key,
    required this.icon,
    this.distance,
    this.color = AppColors.smallBackground,
  });

  final IconData icon;

  /// "2.4 km"; none: the disc alone.
  final String? distance;
  final Color color;

  static const double width = AppSize.s56;

  @override
  Widget build(BuildContext context) {
    final distance = this.distance;
    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GlyphDisc(icon: icon, color: color),
          if (distance != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(top: AppSpacing.s4),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  distance,
                  maxLines: 1,
                  style: AppTextStyles.captionLarge.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
