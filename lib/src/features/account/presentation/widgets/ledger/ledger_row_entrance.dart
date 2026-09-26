import 'package:flutter/widgets.dart';

import '../../../../../config/theme/app_spacing.dart';

/// First-load entrance of one history row (or day title): fades in while it
/// rises [_rise] into place, driven by the list's single entrance
/// controller. No [animation] (a row past the first few, a later page, a
/// refresh, a row scrolled back into view) → the row as is.
class LedgerRowEntrance extends StatelessWidget {
  const LedgerRowEntrance({super.key, this.animation, required this.child});

  static const double _rise = AppSpacing.s8;

  final Animation<double>? animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final progress = animation;
    if (progress == null) return child;
    return FadeTransition(
      opacity: progress,
      child: AnimatedBuilder(
        animation: progress,
        builder: (_, row) => Transform.translate(
          offset: Offset(0, _rise * (1 - progress.value)),
          child: row,
        ),
        child: child,
      ),
    );
  }
}
