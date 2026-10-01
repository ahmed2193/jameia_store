import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_text_styles.dart';
import '../responsive/app_size.dart';
import './hero_icon.dart';

/// A quiet grey pill: a small icon and one line of secondary text — the look
/// of the notes over data that is not live ("Updated 12 minutes ago", "Last
/// known status · 5:55 PM"). The glyph is a `HeroIcons` [icon] (e.g. the
/// clock of the stale note).
class InfoPill extends StatelessWidget {
  const InfoPill({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const ShapeDecoration(
      color: AppColors.smallBackground,
      shape: StadiumBorder(),
    ),
    child: Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.s10,
        vertical: AppSpacing.s4,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HeroIcon(icon, size: AppSize.s14, color: AppColors.secondaryText),
          const SizedBox(width: AppSpacing.s4),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.captionLarge.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
