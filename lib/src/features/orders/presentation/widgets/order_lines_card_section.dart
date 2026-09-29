import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../core/widgets/thin_divider.dart';
import 'order_lines_toggle.dart';

/// The order page's look of the item list (a sliver): the rows [list] on a
/// white hairline card, under an optional [leading] block, with the
/// "Show N more" toggle at the foot while the list [foldable].
class OrderLinesCardSection extends StatelessWidget {
  const OrderLinesCardSection({
    super.key,
    required this.list,
    required this.foldable,
    required this.expanded,
    required this.hidden,
    required this.onToggle,
    this.leading,
  });

  static const BoxDecoration _card = BoxDecoration(
    color: AppColors.white,
    borderRadius: BorderRadius.all(Radius.circular(AppRadius.media)),
    border: Border.fromBorderSide(BorderSide(color: AppColors.divider)),
  );

  /// The rows, a sliver.
  final Widget list;
  final Widget? leading;
  final bool foldable;
  final bool expanded;

  /// Rows past the fold.
  final int hidden;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final leading = this.leading;
    return SliverPadding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.gutter,
      ),
      sliver: DecoratedSliver(
        decoration: _card,
        sliver: SliverPadding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.s16,
            vertical: AppSpacing.s4,
          ),
          sliver: SliverMainAxisGroup(
            slivers: [
              if (leading != null)
                SliverToBoxAdapter(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [leading, const ThinDivider()],
                  ),
                ),
              list,
              if (foldable)
                SliverToBoxAdapter(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const ThinDivider(),
                      OrderLinesToggle(
                        expanded: expanded,
                        hidden: hidden,
                        onPressed: onToggle,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
