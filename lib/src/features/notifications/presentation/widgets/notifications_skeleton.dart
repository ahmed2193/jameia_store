import 'package:flutter/material.dart';

import '../../../../config/theme/app_spacing.dart';
import '../../../../core/responsive/content_clamp.dart';
import '../../../../core/widgets/skeletonized.dart';
import '../../../../core/widgets/thin_divider.dart';
import 'notification_tile_skeleton.dart';

/// What the inbox shows on a first load with nothing saved: rows of
/// [NotificationTileSkeleton]s with the list's own dividers. Rows past a
/// short screen are clipped, never scrolled.
class NotificationsSkeleton extends StatelessWidget {
  const NotificationsSkeleton({super.key});

  static const int _rows = 7;

  @override
  Widget build(BuildContext context) {
    return ContentClamp(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Skeletonized(
          loading: true,
          child: Column(
            children: [
              for (var i = 0; i < _rows; i++) ...const [
                NotificationTileSkeleton(),
                ThinDivider(indent: AppSpacing.s16),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
