import 'package:flutter/widgets.dart';

/// Hands one entering item's arrival (0 → 1, linear, from its
/// [EntranceCascadeItem]) down to the touches inside it that land a beat
/// later — a card's "Save" badge, the marker under its price, a section
/// header's icon. An item that simply shows (a later row, a row scrolled
/// back to, reduced motion) hands down a finished arrival; outside any item
/// everything reads as arrived.
class EntranceArrival extends InheritedWidget {
  const EntranceArrival({
    super.key,
    required this.arrival,
    required super.child,
  });

  final Animation<double> arrival;

  /// The nearest item's arrival; already complete outside an entering item.
  static Animation<double> of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<EntranceArrival>()?.arrival ??
      kAlwaysCompleteAnimation;

  @override
  bool updateShouldNotify(EntranceArrival oldWidget) =>
      oldWidget.arrival != arrival;
}
