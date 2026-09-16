import 'package:flutter/material.dart';

import '../../../../core/design/keeta_assets.dart';
import '../../../../core/design/keeta_icons.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// KeeTa home module title row (`home_special_card_title` / `tiles_area` title)
/// — bold section title with an optional "see all" arrow.
class HomeSectionHeader extends StatelessWidget {
  const HomeSectionHeader({super.key, required this.title, this.onSeeAll});

  final String title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.pageMargin, AppSpacing.s16, AppSpacing.pageMargin, AppSpacing.s8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: AppSize.font18,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryText,
              ),
            ),
          ),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              behavior: HitTestBehavior.opaque,
              child: Image.asset(
                KeetaAssets.sectionTitleArrow,
                width: 16,
                height: 16,
                errorBuilder: (_, _, _) => const Icon(KeetaIcons.arrowRight,
                    size: 16, color: AppColors.secondaryText),
              ),
            ),
        ],
      ),
    );
  }
}
