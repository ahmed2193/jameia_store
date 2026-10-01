import 'package:flutter/material.dart';

import '../../../../../core/design/hero_icons.dart';
import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_icon.dart';
import '../../../../../core/widgets/hero_map.dart';

/// Autocomplete results dropdown floating under the search box.
class SuggestionList extends StatelessWidget {
  const SuggestionList({super.key, required this.items, required this.onPick});
  final List<({String title, String subtitle, LatLng pos})> items;
  final ValueChanged<({String title, String subtitle, LatLng pos})> onPick;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppRadius.card),
      elevation: AppSize.s4,
      shadowColor: AppColors.overlayDivider,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: AppSize.s260),
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s4),
          itemCount: items.length,
          separatorBuilder: (context, index) => const Divider(
            height: AppSize.s0_5,
            thickness: AppSize.s0_5,
            color: AppColors.divider,
          ),
          itemBuilder: (context, i) {
            final it = items[i];
            return InkWell(
              onTap: () => onPick(it),
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpacing.s12,
                  vertical: AppSpacing.s10,
                ),
                child: Row(
                  children: [
                    const HeroIcon(
                      HeroIcons.pinFill,
                      size: AppSize.s16,
                      color: AppColors.secondaryText,
                    ),
                    const SizedBox(width: AppSpacing.s10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            it.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.headingSmall.copyWith(
                              fontWeight: AppTextStyles.medium,
                            ),
                          ),
                          Text(
                            it.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.captionLarge.copyWith(
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
