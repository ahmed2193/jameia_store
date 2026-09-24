import 'package:flutter/widgets.dart';

/// What the main shell shows in each tab. The router builds these, because
/// only `config/routes` may import pages of several features: the shell just
/// places them.
///
/// Each builder must return a NEW, non-const widget on every call — the shell
/// rebuilds its tabs on a language switch and a canonical const instance would
/// short-circuit that rebuild.
@immutable
class ShellTabs {
  const ShellTabs({
    required this.home,
    required this.search,
    required this.cart,
    required this.orderHistory,
    required this.mine,
  });

  final WidgetBuilder home;
  final WidgetBuilder search;

  /// The cart, the Cart tab's default view. [onBrowse] takes the customer
  /// back to shopping (the Home tab) from an empty cart.
  final Widget Function(VoidCallback onBrowse) cart;

  /// Past and running orders, the Cart tab's second view. [active] is `true`
  /// while it is the view on screen, so it can re-read the list when the
  /// customer comes back to it.
  final Widget Function(bool active) orderHistory;

  final WidgetBuilder mine;
}
