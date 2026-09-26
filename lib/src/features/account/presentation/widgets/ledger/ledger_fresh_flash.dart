import 'package:flutter/widgets.dart';

import '../../../../../config/theme/app_colors.dart';

/// Tint behind a history row a pull-to-refresh just brought in: it starts
/// brand-green and fades out once ([color] is the list's one flash
/// animation). The row itself is cached in its own layer while the tint
/// repaints.
class LedgerFreshFlash extends StatelessWidget {
  const LedgerFreshFlash({super.key, required this.color, required this.child});

  final Animation<Color?> color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: color,
      builder: (_, row) => ColoredBox(
        color: color.value ?? AppColors.scrimTransparent,
        child: row,
      ),
      child: RepaintBoundary(child: child),
    );
  }
}
