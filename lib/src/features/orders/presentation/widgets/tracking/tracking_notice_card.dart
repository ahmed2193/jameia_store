import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_icon.dart';
import '../../../../../core/widgets/hero_surface_card.dart';

/// A notice on the tracking page (cancelled, changed while picking): a white
/// hairline card with a small muted icon plate, a bold title and grey detail
/// lines. The colour cue lives in the icon (and a red title for bad news), so
/// every text stays readable on white.
class TrackingNoticeCard extends StatelessWidget {
  const TrackingNoticeCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.titleColor = AppColors.primaryText,
    this.lines = const [],
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final Color titleColor;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return HeroSurfaceCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: SizedBox.square(
              dimension: AppSize.s40,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: AppColors.smallBackground,
                  shape: BoxShape.circle,
                ),
                child: HeroIcon(icon, size: AppSize.s24, color: iconColor),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTextStyles.itemTitleStrong.copyWith(
                    color: titleColor,
                  ),
                ),
                // Detail sentences: the cancellation note, or the unavailable
                // count plus one per substituted product — that one grows
                // with the order (not bounded).
                for (final detail in lines) ...[
                  const SizedBox(height: AppSpacing.s4),
                  Text(detail, style: AppTextStyles.meta),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
