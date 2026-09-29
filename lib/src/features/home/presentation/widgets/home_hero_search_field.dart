import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/motion/press_scale.dart';
import '../../../../core/responsive/app_size.dart';
import 'home_search_hint.dart';

/// The search pill of the home header — the same field whether the header is
/// open or collapsed into the pinned bar, so search never leaves the screen
/// while the feed scrolls. Its hint suggests things to look for, one after
/// another ([HomeSearchHint]).
class HomeHeroSearchField extends StatelessWidget {
  const HomeHeroSearchField({super.key, required this.onTap});

  final VoidCallback onTap;

  /// The header reserves this much height for the field.
  static const double height = AppSize.s44;

  static const double _glyphSize = AppSize.s20;

  @override
  Widget build(BuildContext context) {
    final hint = 'home.search_products'.tr();
    return Semantics(
      button: true,
      label: hint,
      // The node replaces the child's semantics, its tap action included.
      excludeSemantics: true,
      onTap: onTap,
      child: PressScale(
        child: Material(
          color: AppColors.mediumBackground,
          shape: const StadiumBorder(
            side: BorderSide(color: AppColors.divider),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            // Opening search is navigation: no haptic (§9.5).
            onTap: onTap,
            child: SizedBox(
              height: height,
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpacing.s14,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search_rounded,
                      size: _glyphSize,
                      color: kHeroSearchHint,
                    ),
                    const SizedBox(width: AppSpacing.s10),
                    Expanded(
                      child: HomeSearchHint(
                        style: AppTextStyles.subheadingLarge.copyWith(
                          color: kHeroSearchHint,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
