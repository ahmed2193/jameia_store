import 'package:flutter/material.dart';

import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';

/// One chip in the results filter row.
class ResultChipData {
  const ResultChipData({
    required this.label,
    required this.onTap,
    this.icon,
    this.dropdown = false,
    this.selected = false,
    this.separatorAfter = false,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool dropdown;
  final bool selected;

  /// Draw a 1×15dp vertical separator after this chip (after "Sort by").
  final bool separatorAfter;
}

/// Jameia `c_search_shop` horizontal filter-chip row (white background). Chips are
/// 36dp grey pills with an optional leading icon and a trailing "▾"; a hairline
/// separator follows the "Sort by" chip.
class ResultFilterBar extends StatelessWidget {
  const ResultFilterBar({super.key, required this.chips});

  final List<ResultChipData> chips;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.white,
      child: SizedBox(
        height: 52,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 9,
            vertical: AppSpacing.s8,
          ),
          itemCount: chips.length,
          itemBuilder: (context, i) {
            final c = chips[i];
            return Row(
              children: [
                _Chip(data: c),
                if (c.separatorAfter)
                  Container(
                    width: 1,
                    height: 15,
                    margin: const EdgeInsetsDirectional.symmetric(
                      horizontal: 7,
                    ),
                    color: AppColors.separatorInk10,
                  )
                else
                  const SizedBox(width: AppSpacing.s8),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.data});
  final ResultChipData data;

  @override
  Widget build(BuildContext context) {
    const fg = AppColors.primaryText;
    return PressScale(
      onTap: data.onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: data.selected
              ? AppColors
                    .brandLightBg // subtle active tint
              : AppColors.mediumBackground, // #F5F6FA
          borderRadius: BorderRadius.circular(AppSize.r18),
          border: data.selected
              ? Border.all(color: AppColors.primary, width: 1)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (data.icon != null) ...[
              Icon(data.icon, size: 16, color: fg),
              const SizedBox(width: AppSpacing.s6),
            ],
            Text(
              data.label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: fg,
                fontWeight: data.selected
                    ? AppTextStyles.bold
                    : AppTextStyles.medium,
              ),
            ),
            if (data.dropdown) ...[
              const SizedBox(width: AppSpacing.s4),
              Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: fg),
            ],
          ],
        ),
      ),
    );
  }
}
