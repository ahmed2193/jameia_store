import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/responsive/app_size.dart';
import 'home_layout.dart';
import 'home_loop.dart';

/// The minimum-order bar under the feed: a bag, how much to start adding
/// ("Start adding KD 2.500 to place your order!"), an info button that
/// explains the minimum, and the empty track the basket fills towards it.
/// The bag wiggles now and then, as if asking to be filled.
class HomeMinOrderBar extends StatelessWidget {
  const HomeMinOrderBar({
    super.key,
    required this.message,
    required this.onInfo,
  });

  final String message;
  final VoidCallback onInfo;

  static const double _glyph = AppSize.s22;
  static const double _track = AppSize.s4;

  /// A wiggle on the bag's handles: left, right, smaller, still.
  static final Animatable<double> _wiggle = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0, end: 0.22), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 0.22, end: -0.18), weight: 1),
    TweenSequenceItem(tween: Tween(begin: -0.18, end: 0.1), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 0.1, end: -0.05), weight: 1),
    TweenSequenceItem(tween: Tween(begin: -0.05, end: 0), weight: 1),
  ]).chain(CurveTween(curve: AppMotion.machEaseInOut));

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            HomeLayout.gutter,
            AppSpacing.s10,
            AppSpacing.s10,
            AppSpacing.s12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  // Pops in as the bar arrives, then wiggles now and then.
                  PopScale.onMount(
                    child: HomeLoop(
                      period: AppMotion.sheen ~/ 4,
                      rest: AppMotion.sheen,
                      builder: (context, t, child) => Transform.rotate(
                        angle: _wiggle.transform(t),
                        alignment: Alignment.topCenter,
                        child: child,
                      ),
                      child: const Icon(
                        Icons.shopping_bag_outlined,
                        size: _glyph,
                        color: AppColors.primaryText,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s10),
                  Expanded(
                    child: Text(
                      message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: AppTextStyles.medium,
                      ),
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: 'home.min_order_info_label'.tr(),
                    // Replaces the child's semantics, its tap action included.
                    excludeSemantics: true,
                    onTap: onInfo,
                    child: GestureDetector(
                      onTap: onInfo,
                      behavior: HitTestBehavior.opaque,
                      child: const Padding(
                        padding: EdgeInsets.all(AppSpacing.s6),
                        child: Icon(
                          Icons.info_outline_rounded,
                          size: _glyph,
                          color: AppColors.primaryText,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s8),
              Container(
                height: _track,
                // The track ends where the text does, not under the info
                // button's tap padding.
                margin: const EdgeInsetsDirectional.only(end: AppSpacing.s6),
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
