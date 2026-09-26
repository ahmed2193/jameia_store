import 'package:flutter/widgets.dart';

/// Hands one piece's arrival (0 → 1, from whatever reveals it — a listing's
/// reveal clock) down to the touches inside it that land a beat later — a
/// card's "Save" badge, the marker under its price. Outside a scope
/// everything simply shows.
class ShelfArrivalScope extends InheritedWidget {
  const ShelfArrivalScope({
    super.key,
    required this.arrival,
    required super.child,
  });

  final Animation<double> arrival;

  /// The piece's arrival; already complete for a piece that simply shows.
  static Animation<double> of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<ShelfArrivalScope>()
          ?.arrival ??
      kAlwaysCompleteAnimation;

  @override
  bool updateShouldNotify(ShelfArrivalScope oldWidget) =>
      oldWidget.arrival != arrival;
}
