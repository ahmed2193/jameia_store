import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/widgets/press_row.dart';

/// One row of the address search: a [leading] mark (a disc, a distance
/// under it), the [title] over an optional [subtitle], and a [trailing]
/// mark (the ↖, the dots); it presses like every row. A [trailingButton]
/// keeps its own 48 dp target, so the row's end margin is mostly inside
/// it. No [onTap]: it takes no tap.
class AddressSearchRow extends StatelessWidget {
  const AddressSearchRow({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.trailingButton = false,
    required this.onTap,
  });

  final Widget leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final bool trailingButton;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = this.subtitle;
    final trailing = this.trailing;
    return PressRow(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsetsDirectional.only(
          start: AppSpacing.gutter,
          end: trailingButton ? AppSpacing.s4 : AppSpacing.gutter,
          top: AppSpacing.s8,
          bottom: AppSpacing.s8,
        ),
        child: Row(
          children: [
            leading,
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [title, ?subtitle],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.s8),
              trailing,
            ],
          ],
        ),
      ),
    );
  }
}
