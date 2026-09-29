import 'package:flutter/widgets.dart';

import 'entrance_arrival.dart';

/// Holds a touch inside an entering item until the item has LANDED (backlog
/// B2-03, "one primary motion per moment"): [builder] gets `landed: false`
/// while the nearest `EntranceCascadeItem` is still rising in, then
/// `true` once — so a badge pops, a stamp lands or a sweep starts after the
/// card that carries it, not together with it. Outside an entrance, for an
/// item that simply shows (a later row, reduced motion) or one that has
/// already landed, it is `true` from the first build. Rebuilds once, on the
/// landing, not per frame.
class AfterArrival extends StatefulWidget {
  const AfterArrival({super.key, required this.builder});

  final Widget Function(BuildContext context, bool landed) builder;

  @override
  State<AfterArrival> createState() => _AfterArrivalState();
}

class _AfterArrivalState extends State<AfterArrival> {
  Animation<double>? _arrival;
  bool _landed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arrival = EntranceArrival.of(context);
    if (arrival == _arrival) return;
    _arrival?.removeStatusListener(_statusChanged);
    _arrival = arrival;
    if (arrival.isCompleted) {
      _landed = true;
    } else if (!_landed) {
      arrival.addStatusListener(_statusChanged);
    }
  }

  void _statusChanged(AnimationStatus status) {
    if (!status.isCompleted) return;
    _arrival?.removeStatusListener(_statusChanged);
    if (mounted) setState(() => _landed = true);
  }

  @override
  void dispose() {
    _arrival?.removeStatusListener(_statusChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _landed);
}
