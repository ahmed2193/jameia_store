import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../core/design/jameia_assets.dart';
import '../../../../core/responsive/app_size.dart';

/// The search field of the home hero. It is the SAME field in both states —
/// white and elevated over the brand band, flat and grey once the bar has
/// collapsed — so it never leaves the screen while the feed scrolls.
class HomeHeroSearchField extends StatelessWidget {
  const HomeHeroSearchField({
    super.key,
    required this.onTap,
    this.fill = AppColors.white,
    this.shadowAlpha = restingShadowAlpha,
  });

  final VoidCallback onTap;

  /// Field background: white over the band, the flat grey of a collapsed bar.
  final Color fill;

  /// Drop-shadow strength; `0` leaves the field flat.
  final double shadowAlpha;

  /// Shadow of the elevated (expanded) field.
  static const double restingShadowAlpha = 0.10;

  /// The hero reserves this much height for the field.
  static const double height = AppSize.s44;

  static const double _glyphSize = AppSize.s18;
  static const Offset _shadowOffset = Offset(0, AppSize.s1);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.scrimTransparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSize.r12),
        child: Container(
          height: height,
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.s12,
          ),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(AppSize.r12),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryText.withValues(alpha: shadowAlpha),
                blurRadius: AppSize.s3,
                offset: _shadowOffset,
              ),
              BoxShadow(
                color: AppColors.primaryText.withValues(alpha: shadowAlpha),
                blurRadius: AppSize.s2,
                spreadRadius: -AppSize.s1,
                offset: _shadowOffset,
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.search_rounded,
                size: _glyphSize,
                color: kJameiaSearchHint,
              ),
              const SizedBox(width: AppSpacing.s8),
              Expanded(
                child: Text(
                  'home.search_products'.tr(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: AppSize.font14,
                    color: kJameiaSearchHint,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              SvgPicture.asset(
                JameiaAssets.jameiaScanLine,
                width: _glyphSize,
                height: _glyphSize,
                colorFilter: const ColorFilter.mode(
                  AppColors.primaryText,
                  BlendMode.srcIn,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
