import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/hero_assets.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/brand_mark.dart';
import '../../../../../core/widgets/labeled_field_box.dart';
import '../../../domain/entities/phone_number.dart';

/// The "Prefix" box: Kuwait's flag (drawn, never mirrored) and `+965`. Hero
/// delivers in Kuwait only, so it is a label, not a picker (no caret
/// promising a choice); a tap on it moves on to the number ([onTap]).
class LoginPrefixBox extends StatelessWidget {
  const LoginPrefixBox({super.key, required this.onTap});

  final VoidCallback onTap;

  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  /// The flag is 2:1; a hairline keeps its white stripe off the white box.
  static const double _flagWidth = AppSize.s20;
  static const double _flagHeight = AppSize.s10;
  static const BorderRadius _flagRadius = BorderRadius.all(
    Radius.circular(AppSize.r2),
  );
  static const BoxDecoration _flagEdge = BoxDecoration(
    borderRadius: _flagRadius,
    border: Border.fromBorderSide(
      BorderSide(color: AppColors.shadowInk10, width: 0),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return LabeledFieldBox(
      label: 'auth.prefix_label'.tr(),
      onTap: onTap,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: _flagEdge,
              child: ClipRRect(
                borderRadius: _flagRadius,
                child: const BrandMark(
                  HeroAssets.flagKuwait,
                  size: _flagWidth,
                  height: _flagHeight,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.s6),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  PhoneNumber.kuwaitDialCode,
                  maxLines: 1,
                  style: AppTextStyles.headingLarge.copyWith(
                    fontFeatures: _tabular,
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
