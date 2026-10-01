import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../../config/theme/app_colors.dart';
import '../../../../../../config/theme/app_shadows.dart';
import '../../../../../../config/theme/app_spacing.dart';
import '../../../../../../config/theme/app_text_styles.dart';
import '../../../../../../core/design/hero_icons.dart';
import '../../../../../../core/responsive/app_size.dart';
import '../../../../../../core/widgets/hero_icon.dart';
import 'assistant_onboarding_item.dart';
import 'assistant_onboarding_item_glyph.dart';

/// One suggestion in the ask demo: the item on a white card with a green
/// "+", rising and popping in as [appear] goes to `1`. Keeps its place in
/// the row while hidden.
class AssistantOnboardingProductTile extends StatelessWidget {
  const AssistantOnboardingProductTile({
    super.key,
    required this.item,
    required this.appear,
  });

  final AssistantOnboardingItem item;
  final double appear;

  static const double _width = AppSize.s88;
  static const double _height = AppSize.s84;
  static const double _rise = AppSize.s16;
  static const double _glyph = AppSize.s36;
  static const double _plus = AppSize.s20;
  static const BoxDecoration _card = BoxDecoration(
    color: AppColors.white,
    borderRadius: BorderRadius.all(Radius.circular(AppRadius.r3)),
    boxShadow: AppShadows.low,
  );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _width,
      height: _height,
      child: Transform.translate(
        offset: Offset(0, (1 - appear.clamp(0.0, 1.0)) * _rise),
        child: Transform.scale(
          scale: appear,
          child: DecoratedBox(
            decoration: _card,
            child: Stack(
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s6,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AssistantOnboardingItemGlyph(item: item, size: _glyph),
                        const SizedBox(height: AppSpacing.s6),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            item.labelKey.tr(),
                            maxLines: 1,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.primaryText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const PositionedDirectional(
                  top: AppSpacing.s6,
                  end: AppSpacing.s6,
                  child: SizedBox.square(
                    dimension: _plus,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: HeroIcon(
                        HeroIcons.plus,
                        size: AppSize.s14,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
