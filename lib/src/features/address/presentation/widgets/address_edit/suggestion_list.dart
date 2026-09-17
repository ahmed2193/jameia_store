import 'package:flutter/material.dart';

import '../../../../../core/design/jameia_icons.dart';
import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/widgets/jameia_map.dart';

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
      elevation: 4,
      shadowColor: AppColors.overlayDivider,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 260),
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s4),
          itemCount: items.length,
          separatorBuilder: (context, index) => const Divider(
            height: 0.5,
            thickness: 0.5,
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
                    const Icon(
                      JameiaIcons.location,
                      size: 16,
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
