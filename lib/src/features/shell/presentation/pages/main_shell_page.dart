import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/routes/route_args/shell_arrival.dart';
import '../../../../config/routes/route_args/shell_tabs.dart';
import '../../../../core/motion/fly_to_cart.dart';
import '../../../language/presentation/cubit/localization_cubit.dart';
import '../../../language/presentation/cubit/localization_state.dart';
import '../widgets/shell_basket_tab.dart';
import '../widgets/shell_bottom_nav.dart';
import '../widgets/shell_session_keyed.dart';
import '../widgets/shell_tab_stack.dart';

/// Hero MainTabActivity equivalent — 4 tabs (Home / Search / Cart / Mine)
/// over a [ShellTabStack] so each tab keeps its scroll + state (the tab
/// coming on screen fades in; hidden tabs tick nothing).
///
/// The router hands over the tab pages ([tabs]); the shell only places them.
/// The Cart tab opens on the cart and switches to the order history, which is
/// told when it is on screen so it re-reads `GET /v1/orders` when the customer
/// comes back to it.
///
/// A `go` back to a shell already in the stack keeps this State (same page
/// type and key); its fresh [arrival] moves it to the tab it names. Its tabs
/// are rebuilt only when a new session begins ([ShellSessionKeyed]).
class MainShellPage extends StatefulWidget {
  const MainShellPage({
    super.key,
    required this.tabs,
    this.initialIndex = 0,
    this.arrival,
  });

  final ShellTabs tabs;
  final int initialIndex;

  /// The `go` that brought the shell on screen; a new one selects its tab.
  final ShellArrival? arrival;

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  late int _index = widget.arrival?.tab.index ?? widget.initialIndex;

  /// Stable key on the Cart tab's icon — the fly-to-cart destination. Kept
  /// across rebuilds and registered once so its global position stays correct.
  final GlobalKey _cartIconKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    FlyToCart.registerTarget(_cartIconKey);
  }

  @override
  void didUpdateWidget(MainShellPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final arrival = widget.arrival;
    if (arrival != null && !identical(arrival, oldWidget.arrival)) {
      _index = arrival.tab.index;
    }
  }

  void _select(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    // The whole shell is rebuilt via BlocBuilder<LocalizationCubit> so the tab
    // bodies AND the bottom-nav labels re-localize the instant the language
    // changes — even while this shell is OFFSTAGE (Settings pushed on top):
    // BlocBuilder listens to the cubit stream directly, independent of route
    // visibility. easy_localization's `context.setLocale` alone does NOT do this
    // — `.tr()` is context-free, so on a live switch only Directionality-driven
    // layout rebuilds; cached text widgets keep their old-language strings.
    //
    // The tab builders return fresh (non-const) instances for the same reason:
    // a canonical const tab would short-circuit `IndexedStack.updateChild`.
    return BlocBuilder<LocalizationCubit, LocalizationState>(
      buildWhen: (p, c) => p.locale != c.locale,
      builder: (context, state) {
        final tabs = widget.tabs;
        // Keyed by language so a switch recreates the tab Elements (and thus
        // their State): strings a tab caches in State would otherwise stay
        // in the old language. Cost: tab scroll resets on a language switch.
        // A new session (a sign-in over the kept shell) rebuilds them too,
        // with fresh page cubits.
        final body = ShellSessionKeyed(
          child: ShellTabStack(
            key: ValueKey(state.languageCode),
            index: _index,
            children: [
              tabs.home(context),
              tabs.search(context),
              ShellBasketTab(
                tabs: tabs,
                active: _index == ShellBottomNav.cartTab,
                onBrowse: () => _select(ShellBottomNav.homeTab),
              ),
              tabs.mine(context),
            ],
          ),
        );
        final overlay = tabs.overlay;
        return Scaffold(
          // The overlay (the assistant's buddy) floats over the tab bodies,
          // above the bottom nav; the bodies pass through it untouched.
          body: overlay == null ? body : overlay(ShellTab.values[_index], body),
          bottomNavigationBar: ShellBottomNav(
            index: _index,
            cartIconKey: _cartIconKey,
            onTap: _select,
          ),
        );
      },
    );
  }
}
