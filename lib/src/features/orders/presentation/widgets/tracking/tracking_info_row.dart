import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_icon.dart';

/// One fact on the order page: a 24 dp [icon] (or a [leading] picture of the
/// same size), then its lines — the first in the row style, the rest as grey
/// meta. Read out as one node.
class TrackingInfoRow extends StatelessWidget {
  const TrackingInfoRow({
    super.key,
    required this.lines,
    this.icon,
    this.leading,
    this.iconColor = AppColors.primaryText,
  }) : assert(icon != null || leading != null, 'a row needs a glyph');

  final IconData? icon;

  /// Wins over [icon] (an SVG plate).
  final Widget? leading;
  final List<String> lines;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: SizedBox.square(
              dimension: AppSize.s24,
              child:
                  leading ??
                  HeroIcon(icon!, size: AppSize.s24, color: iconColor),
            ),
          ),
          const SizedBox(width: AppSpacing.s16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < lines.length; i++)
                  Text(
                    lines[i],
                    style: i == 0
                        ? AppTextStyles.itemTitle
                        : AppTextStyles.meta,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
