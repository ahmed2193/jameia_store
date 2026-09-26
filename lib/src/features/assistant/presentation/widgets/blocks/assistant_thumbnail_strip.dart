import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/jameia_image.dart';

/// A row of small pictures (cart lines, order items). Decorative: the card
/// already says how many items there are.
class AssistantThumbnailStrip extends StatelessWidget {
  const AssistantThumbnailStrip({super.key, required this.urls});

  final List<String> urls;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Row(
        children: [
          for (final url in urls)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSpacing.s6),
              child: JameiaImage(
                url: url,
                width: AppSize.s40,
                height: AppSize.s40,
                radius: AppRadius.r4,
              ),
            ),
        ],
      ),
    );
  }
}
