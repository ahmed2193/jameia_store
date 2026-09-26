import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';

/// A titled horizontal rail of [AssistantPillChip]s. Short by nature (a
/// reply names a handful), so it sizes to its pills instead of a fixed
/// height — the pills grow with the text scale.
class AssistantPillRail extends StatelessWidget {
  const AssistantPillRail({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: AppTextStyles.headingSmall),
        ),
        const SizedBox(height: AppSpacing.s8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final (index, chip) in children.indexed)
                Padding(
                  padding: EdgeInsetsDirectional.only(
                    start: index == 0 ? 0 : AppSpacing.s8,
                  ),
                  child: chip,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
