import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/responsive/app_size.dart';
import 'coupon_stub.dart';

/// Friendly empty state of a coupon list: the [icon] in a warm gradient
/// circle that pops in and then gently floats, above the [message].
/// Scrolls when a large text scale makes it taller than the room it has.
class CouponsEmptyView extends StatelessWidget {
  const CouponsEmptyView({
    super.key,
    required this.message,
    this.icon = Icons.confirmation_number_outlined,
  });

  final String message;
  final IconData icon;

  static const double _disc = AppSize.s96;
  static const double _haloAlpha = 0.6;
  static const double _halo = AppSize.s120;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.s24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: constraints.maxHeight - AppSpacing.s24 * 2,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PopScale.onMount(
                  child: FloatLoop(
                    child: SizedBox.square(
                      dimension: _halo,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accent3Light.withValues(
                            alpha: _haloAlpha,
                          ),
                        ),
                        child: Center(
                          child: SizedBox.square(
                            dimension: _disc,
                            child: DecoratedBox(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: AlignmentDirectional.topStart,
                                  end: AlignmentDirectional.bottomEnd,
                                  colors: CouponStub.gradient,
                                ),
                              ),
                              child: Icon(
                                icon,
                                size: AppSize.s44,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.s16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.subheadingLarge.copyWith(
                    color: AppColors.secondaryText,
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
