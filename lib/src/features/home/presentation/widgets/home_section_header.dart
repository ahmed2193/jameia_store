import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/responsive/app_size.dart';
import '../../domain/entities/home_icon.dart';
import 'home_accent_palette.dart';
import 'home_icon_view.dart';

/// Title row of a home block: the backend's icon on its accent disc, the bold
/// title and an optional "View all".
class HomeSectionHeader extends StatelessWidget {
  const HomeSectionHeader({
    super.key,
    required this.title,
    this.icon = const HomeIcon(),
    this.accent = HomeAccent.none,
    this.onSeeAll,
    this.fill = AppColors.white,
  });

  final String title;
  final HomeIcon icon;
  final HomeAccent accent;
  final VoidCallback? onSeeAll;

  /// The surface the header sits on. A themed block is washed in the accent
  /// family its icon uses, so on those the disc would be the colour of the
  /// card it sits on: there it goes white instead.
  final Color fill;

  @override
  Widget build(BuildContext context) {
    final disc = HomeAccentPalette.wash(accent);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.pageMargin,
        AppSpacing.s6,
        AppSpacing.pageMargin,
        AppSpacing.s10,
      ),
      child: Row(
        children: [
          if (!icon.isEmpty) ...[
            Container(
              width: AppSize.s28,
              height: AppSize.s28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: disc == fill ? AppColors.white : disc,
                shape: BoxShape.circle,
              ),
              child: HomeIconView(
                icon: icon,
                size: AppSize.s16,
                color: HomeAccentPalette.strong(accent),
              ),
            ),
            const SizedBox(width: AppSpacing.s8),
          ],
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.headingLarge.copyWith(
                fontWeight: AppTextStyles.bold,
              ),
            ),
          ),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              behavior: HitTestBehavior.opaque,
              // A real action, in the colour the storefront gives its
              // actions — not grey text trailing the heading.
              child: Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: AppSpacing.s8,
                  top: AppSpacing.s4,
                  bottom: AppSpacing.s4,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'catalog.view_all'.tr(),
                      style: AppTextStyles.captionLarge.copyWith(
                        color: kJameiaViewAll,
                        fontWeight: AppTextStyles.bold,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: AppSize.s16,
                      color: kJameiaViewAll,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
