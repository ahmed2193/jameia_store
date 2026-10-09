import 'package:flutter/widgets.dart';

/// The main shell's tabs, in bottom-nav order.
enum ShellTab { home, search, cart, mine }

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
    this.overlay,
    this.scope,
    this.tabBarTop,
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

  /// Floats over the tab bodies ([child]) — the assistant's buddy — told
  /// which [ShellTab] is on screen. `null`: nothing floats.
  final Widget Function(ShellTab tab, Widget child)? overlay;

  /// Wraps the whole shell — the tab bodies AND the tab bar ([shell]) — with
  /// what a tab shares with the bars around the tabs (the home tab tells the
  /// first-order bar whether it shows). `null`: nothing shared.
  final Widget Function(Widget shell)? scope;

  /// Stands right on top of the tab bar, under the tab bodies (the
  /// first-order free-delivery bar), told which [ShellTab] is on screen.
  /// `null`: nothing there.
  final Widget Function(ShellTab tab)? tabBarTop;
}
