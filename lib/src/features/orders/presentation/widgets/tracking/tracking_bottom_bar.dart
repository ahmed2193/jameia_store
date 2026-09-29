import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/domain/entities/order_entity.dart';
import '../../../../../core/motion/collapse_reveal.dart';
import '../../../../../core/motion/deferred_value.dart';
import '../../../../../core/motion/motion.dart';
import '../../cubit/order_tracking_cubit.dart';
import '../../cubit/order_tracking_state.dart';
import 'tracking_reorder_bar.dart';

/// The page's foot: the "Reorder" bar once the order is finished. It rises
/// last when a cancel lands (after the panel, the notice and the cancel
/// button — backlog B2-03); a finished order opened later shows it with
/// its content. Rebuilds only when the order finishes or its lines change.
class TrackingBottomBar extends StatelessWidget {
  const TrackingBottomBar({super.key});

  static bool _changed(
    OrderTrackingState previous,
    OrderTrackingState current,
  ) {
    final before = previous.order;
    final after = current.order;
    return before?.isTerminal != after?.isTerminal ||
        !listEquals(before?.lines, after?.lines);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrderTrackingCubit, OrderTrackingState>(
      buildWhen: _changed,
      builder: (context, state) {
        final OrderEntity? order = state.order;
        final finished = order != null && order.isTerminal;
        // Keyed by the order: the first read of a finished order shows the
        // bar at once; only a change on screen waits its turn.
        return DeferredValue<bool>(
          key: ValueKey<String?>(order?.id),
          value: finished,
          delay: AppMotion.slow,
          builder: (context, shown) => CollapseReveal(
            visible: shown,
            child: order == null
                ? const SizedBox.shrink()
                : TrackingReorderBar(
                    items: order.reorderItems,
                    image: order.reorderImage,
                  ),
          ),
        );
      },
    );
  }
}
