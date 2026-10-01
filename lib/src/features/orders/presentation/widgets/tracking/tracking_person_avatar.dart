import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_icon.dart';

/// A person's disc on the order page: the first letter of their [name] on
/// the green wash, with the [role] glyph in a small white badge at the
/// bottom-end corner (the basket for the picker, the scooter for the
/// driver). The API sends no photo, so none is faked. Decorative.
class TrackingPersonAvatar extends StatelessWidget {
  const TrackingPersonAvatar({
    super.key,
    required this.name,
    required this.role,
  });

  final String name;
  final IconData role;

  static const double _disc = AppSize.s44;
  static const double _badge = AppSize.s20;
  static const double _badgeGlyph = AppSize.s12;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty
        ? ''
        : name.trim().characters.first.toUpperCase();
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: _disc,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.brandLightBg,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Center(
              child: Text(
                initial,
                style: AppTextStyles.headingLarge.copyWith(
                  color: AppColors.brandDeep,
                ),
              ),
            ),
            PositionedDirectional(
              end: 0,
              bottom: 0,
              child: SizedBox.square(
                dimension: _badge,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.brandLightBg),
                  ),
                  child: HeroIcon(
                    role,
                    size: _badgeGlyph,
                    color: AppColors.brandDeep,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
