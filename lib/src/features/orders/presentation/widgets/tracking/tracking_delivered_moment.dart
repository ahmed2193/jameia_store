import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/domain/entities/order_status.dart';
import '../../../../../core/motion/confetti_burst.dart';
import '../../../../../core/motion/deferred_value.dart';
import '../../../../../core/motion/haptics.dart';
import '../../../../../core/motion/motion.dart';

/// The delivered moment (docs/motion backlog B2-04): when the order turns
/// delivered WHILE the customer watches, the success haptic fires with the
/// stage disc's pop into the success art, then — once that pop has landed —
/// one short confetti burst over the status panel. Bounded: one burst, a
/// fixed seed, nothing under reduced motion (the haptic stays: it is not
/// movement). Opening an order that was delivered long ago plays nothing.
class TrackingDeliveredMoment extends StatefulWidget {
  const TrackingDeliveredMoment({
    super.key,
    required this.status,
    required this.child,
  });

  final OrderStatus status;
  final Widget child;

  @override
  State<TrackingDeliveredMoment> createState() =>
      _TrackingDeliveredMomentState();
}

class _TrackingDeliveredMomentState extends State<TrackingDeliveredMoment> {
  /// Fewer pieces than a checkout celebration: a moment, not a party.
  static const int _pieces = 28;

  static const List<Color> _colors = [
    AppColors.primary,
    AppColors.proAmber,
    AppColors.brandDarkBg,
    AppColors.brandDeep,
  ];

  /// Moments played so far; `null` until the first.
  int? _moment;

  @override
  void didUpdateWidget(TrackingDeliveredMoment oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status == OrderStatus.delivered ||
        widget.status != OrderStatus.delivered) {
      return;
    }
    Haptics.success();
    _moment = (_moment ?? 0) + 1;
  }

  @override
  Widget build(BuildContext context) => DeferredValue<int?>(
    value: _moment,
    // After the disc's pop (one medium step), never on the same frame.
    delay: AppMotion.medium,
    builder: (context, moment) => ConfettiBurst(
      playKey: moment,
      colors: _colors,
      count: _pieces,
      child: widget.child,
    ),
  );
}
