import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_shadows.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import 'mine_menu_cell.dart';
import 'mine_menu_divider.dart';
import 'mine_menu_entry.dart';

/// A titled group of Mine menu rows on one white card (radius 16, soft
/// shadow). The card is a [Material] so the rows' touch highlight paints on
/// it, clipped to the rounded corners.
class MineMenuSection extends StatelessWidget {
  const MineMenuSection({
    super.key,
    required this.title,
    required this.entries,
  });

  final String title;
  final List<MineMenuEntry> entries;

  static final BorderRadius _radius = BorderRadius.circular(AppRadius.r3);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(
            start: AppSpacing.s20,
            end: AppSpacing.s20,
            bottom: AppSpacing.s8,
          ),
          child: Semantics(
            header: true,
            child: Text(
              title,
              style: AppTextStyles.subheadingMedium.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.s16,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: _radius,
              boxShadow: AppShadows.low,
            ),
            child: Material(
              color: AppColors.white,
              borderRadius: _radius,
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (var i = 0; i < entries.length; i++) ...[
                    if (i != 0) const MineMenuDivider(),
                    MineMenuCell(
                      icon: entries[i].icon,
                      plate: entries[i].plate,
                      label: entries[i].label,
                      tone: entries[i].tone,
                      badgeCount: entries[i].badgeCount,
                      trailing: entries[i].trailing,
                      onTap: () => context.push(entries[i].route),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
