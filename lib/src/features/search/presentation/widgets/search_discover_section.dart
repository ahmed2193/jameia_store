import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import 'search_chip.dart';

/// One titled block of the discover screen: a heading (with an optional text
/// action such as "Clear") over a wrap of chips. Nothing is drawn for an empty
/// block.
class SearchDiscoverSection extends StatelessWidget {
  const SearchDiscoverSection({
    super.key,
    required this.title,
    required this.labels,
    required this.onTapIndex,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final List<String> labels;
  final ValueChanged<int> onTapIndex;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    if (labels.isEmpty) return const SizedBox.shrink();
    final action = actionLabel;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.s16,
        AppSpacing.s16,
        AppSpacing.s16,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.headingSmall.copyWith(
                    fontWeight: AppTextStyles.bold,
                  ),
                ),
              ),
              if (action != null)
                GestureDetector(
                  onTap: onAction,
                  behavior: HitTestBehavior.opaque,
                  child: Text(
                    action,
                    style: AppTextStyles.captionLarge.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.s10),
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            children: [
              for (final (index, label) in labels.indexed)
                SearchChip(label: label, onTap: () => onTapIndex(index)),
            ],
          ),
        ],
      ),
    );
  }
}
