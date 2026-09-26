import 'package:flutter/material.dart';

import '../../config/theme/app_spacing.dart';
import '../responsive/content_clamp.dart';
import 'order_card_skeleton.dart';
import 'skeletonized.dart';

/// Orders-list skeleton: order cards as shimmering bones (a still bone under
/// reduced motion), in the list's own gutters, so the first page lands where
/// its skeleton was. Only on screen while the first page loads.
///
/// A non-scrolling list rather than a fixed column: in the Cart tab the
/// orders sit under the tab's switch and above the bottom nav, and the cards
/// are taller than that space on a small phone — a column overflowed there,
/// a list just clips the last card.
class OrdersSkeleton extends StatelessWidget {
  const OrdersSkeleton({super.key});

  static const int _cards = 3;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: ContentClamp(
      child: Skeletonized(
        loading: true,
        child: ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.gutter,
            AppSpacing.s16,
            AppSpacing.gutter,
            0,
          ),
          itemCount: _cards,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s12),
          itemBuilder: (_, _) => const OrderCardSkeleton(),
        ),
      ),
    ),
  );
}
