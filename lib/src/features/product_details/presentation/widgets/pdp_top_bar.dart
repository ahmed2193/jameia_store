import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_shadows.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/responsive/app_size.dart';
import 'pdp_back_button.dart';
import 'pdp_cart_action.dart';

/// The product page's top bar, status bar included: the round white back
/// button at the reading start and the cart at the end, over the gallery.
/// As the gallery scrolls away ([progress] 0 → 1) a white bar fades in under
/// them with the product's name rising into place, and a soft shadow lifts
/// it once it is solid.
///
/// Only the buttons take touches while the bar is see-through, so the photo
/// under it still opens the viewer and scrolls; the solid bar keeps its taps.
class PdpTopBar extends StatelessWidget {
  const PdpTopBar({
    super.key,
    required this.progress,
    required this.title,
    required this.topInset,
  });

  final ValueListenable<double> progress;
  final String title;

  /// The status bar's height: the bar paints under it.
  final double topInset;

  static const double barHeight = AppSize.s64;

  /// The buttons sit on the page's 16 dp gutters.
  static const double sideInset = AppSpacing.s16;

  /// How far below its place the name starts rising as it fades in.
  static const double titleRise = AppSpacing.s8;

  @override
  Widget build(BuildContext context) {
    final rise = MotionGuard.reduced(context) ? 0.0 : titleRise;
    return SizedBox(
      height: topInset + barHeight,
      child: Stack(
        children: [
          Positioned.fill(
            child: ValueListenableBuilder<double>(
              valueListenable: progress,
              builder: (context, p, _) => IgnorePointer(
                ignoring: p < 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: p),
                    boxShadow: p >= 1 ? AppShadows.barBottom : null,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsetsDirectional.only(
              top: topInset,
              start: sideInset,
              end: sideInset,
            ),
            child: SizedBox(
              height: barHeight,
              child: Row(
                children: [
                  const PdpBackButton(),
                  const SizedBox(width: AppSpacing.s16),
                  Expanded(
                    child: IgnorePointer(
                      child: ValueListenableBuilder<double>(
                        valueListenable: progress,
                        builder: (context, p, child) => ExcludeSemantics(
                          excluding: p <= 0,
                          child: Opacity(
                            opacity: p,
                            child: Transform.translate(
                              offset: Offset(0, (1 - p) * rise),
                              child: child,
                            ),
                          ),
                        ),
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.subheadingLarge.copyWith(
                            color: AppColors.primaryText,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s16),
                  const PdpCartAction(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
