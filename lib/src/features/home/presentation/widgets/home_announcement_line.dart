import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/responsive/app_size.dart';
import '../../domain/entities/home_announcement_item.dart';
import 'home_icon_view.dart';

/// One line of the announcement strip: the backend's icon on a translucent
/// disc, then the message. The disc pops as the line arrives, so the eye is
/// caught by the new announcement and not by the text sliding under it.
class HomeAnnouncementLine extends StatelessWidget {
  const HomeAnnouncementLine({super.key, required this.item});

  final HomeAnnouncementItem item;

  static const double _disc = AppSize.s24;
  static const double _discAlpha = 0.16;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PopScale.onMount(
          child: Container(
            width: _disc,
            height: _disc,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: _discAlpha),
              shape: BoxShape.circle,
            ),
            child: HomeIconView(
              icon: item.icon,
              size: AppSize.s14,
              color: AppColors.white,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.s8),
        Expanded(
          child: Text(
            item.text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.captionLarge.copyWith(
              color: AppColors.white,
              fontWeight: AppTextStyles.medium,
            ),
          ),
        ),
      ],
    );
  }
}
