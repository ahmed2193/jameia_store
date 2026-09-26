import 'package:flutter/widgets.dart';

/// Hands the listing's entrance clock ([ListingReveal]) down to the pieces
/// that come in with it: 0 → 1 once per arrival of a list.
class ListingRevealScope extends InheritedWidget {
  const ListingRevealScope({
    super.key,
    required this.reveal,
    required super.child,
  });

  final Animation<double> reveal;

  /// The entrance clock; always complete outside a listing.
  static Animation<double> of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<ListingRevealScope>()
          ?.reveal ??
      kAlwaysCompleteAnimation;

  @override
  bool updateShouldNotify(ListingRevealScope oldWidget) =>
      oldWidget.reveal != reveal;
}
