import 'package:flutter/material.dart';

import '../../../../../../config/theme/app_colors.dart';
import '../../../../../../config/theme/app_shadows.dart';
import '../../../../../../config/theme/app_text_styles.dart';
import '../../../../../../core/motion/change_bump.dart';
import '../../../../../../core/motion/motion_widgets.dart';
import '../../../../../../core/responsive/app_size.dart';

/// The cart demo's cart: a white disc that pops in with [appear], bumps
/// when [count] changes and shows a red count once something is in it.
class AssistantOnboardingCartBadge extends StatelessWidget {
  const AssistantOnboardingCartBadge({
    super.key,
    required this.count,
    required this.appear,
  });

  final int count;
  final double appear;

  static const double _disc = AppSize.s44;
  static const double _count = AppSize.s20;
  static const double _countOut = -AppSize.s2;
  static const BoxDecoration _face = BoxDecoration(
    color: AppColors.white,
    shape: BoxShape.circle,
    boxShadow: AppShadows.low,
  );
  static const BoxDecoration _dot = BoxDecoration(
    color: AppColors.accent1,
    shape: BoxShape.circle,
  );

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: appear,
      child: ChangeBump(
        value: count,
        child: SizedBox.square(
          dimension: _disc,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: _face,
                  child: Icon(
                    Icons.shopping_cart_outlined,
                    size: AppSize.s22,
                    color: AppColors.primaryText,
                  ),
                ),
              ),
              if (count > 0)
                PositionedDirectional(
                  top: _countOut,
                  end: _countOut,
                  child: PopScale(
                    popKey: count,
                    child: SizedBox.square(
                      dimension: _count,
                      child: DecoratedBox(
                        decoration: _dot,
                        child: Center(
                          child: Text(
                            '$count',
                            style: AppTextStyles.tag.copyWith(
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
