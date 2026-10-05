import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../core/motion/entrance_cascade_item.dart';
import '../../../../core/motion/press_scale.dart';
import '../../../../core/responsive/app_size.dart';
import 'home_first_order_chevron.dart';
import 'home_first_order_headline.dart';
import 'home_first_order_rider.dart';

/// The first-order free-delivery bar that sits on the shell's tab bar: the
/// Hero rider riding in on the brand-deep green, "[Free delivery] on your
/// first order", and the chevron that opens the details ([onTap]). Its top
/// corners round off over the feed like a tab pulled up from the bar below.
///
/// It arrives with motion: the rider drives in, the line and the chevron
/// rise in after it ([EntranceCascadeItem]), then the ride, the chip's
/// light sweep and the chevron's nudge play for the ambient budget. A press
/// dips the content, never the bar itself (it is glued to the tab bar).
class HomeFirstOrderBanner extends StatelessWidget {
  const HomeFirstOrderBanner({super.key, required this.onTap});

  final VoidCallback onTap;

  static const double _rider = AppSize.s52;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'home.first_order_bar_label'.tr(),
      // Replaces the children's semantics, the tap action included.
      excludeSemantics: true,
      onTap: onTap,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.brandDeep,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.media),
          ),
        ),
        child: SafeArea(
          top: false,
          child: PressScale(
            onTap: onTap,
            child: const Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                AppSpacing.s4,
                AppSpacing.s10,
                AppSpacing.s12,
                AppSpacing.s10,
              ),
              child: Row(
                children: [
                  HomeFirstOrderRider(width: _rider),
                  SizedBox(width: AppSpacing.s8),
                  Expanded(
                    child: EntranceCascadeItem.single(
                      index: 2,
                      child: HomeFirstOrderHeadline(),
                    ),
                  ),
                  SizedBox(width: AppSpacing.s8),
                  EntranceCascadeItem.single(
                    index: 4,
                    child: HomeFirstOrderChevron(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
