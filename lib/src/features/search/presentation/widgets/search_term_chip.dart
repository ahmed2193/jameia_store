import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/motion/haptics.dart';
import '../../../../core/motion/press_scale.dart';
import '../../../../core/responsive/app_size.dart';

/// An outlined pill chip of the search screen (docs/design_system.md): white,
/// a hairline border, an ink label and an optional grey leading icon. The
/// pill is 36 dp tall inside a 44 dp tap target; a long term ellipsizes.
class SearchTermChip extends StatelessWidget {
  const SearchTermChip({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
  });

  static const double _pillHeight = AppSize.s36;
  static const double _maxWidth = AppSize.s240;
  static const double _pressedScale = 0.97;

  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final icon = this.icon;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: PressScale(
        onTap: onTap,
        haptic: HapticKind.selection,
        pressedScale: _pressedScale,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSize.s44,
            maxWidth: _maxWidth,
          ),
          child: Center(
            widthFactor: 1,
            child: DecoratedBox(
              decoration: const ShapeDecoration(
                color: AppColors.white,
                shape: StadiumBorder(
                  side: BorderSide(color: AppColors.divider),
                ),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: _pillHeight),
                child: Padding(
                  padding: EdgeInsetsDirectional.only(
                    start: icon == null ? AppSpacing.s16 : AppSpacing.s12,
                    end: AppSpacing.s16,
                    top: AppSpacing.s6,
                    bottom: AppSpacing.s6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(
                          icon,
                          size: AppSize.s18,
                          color: AppColors.secondaryText,
                        ),
                        const SizedBox(width: AppSpacing.s6),
                      ],
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.label,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
