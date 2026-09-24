import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/routes/route_args/shell_tabs.dart';
import '../../../../core/motion/fly_to_cart.dart';
import '../../../language/presentation/cubit/localization_cubit.dart';
import '../../../language/presentation/cubit/localization_state.dart';
import '../widgets/shell_basket_tab.dart';
import '../widgets/shell_bottom_nav.dart';

/// Jameia MainTabActivity equivalent — 4 tabs (Home / Search / Cart / Mine)
/// over an [IndexedStack] so each tab keeps its scroll + state.
///
/// The router hands over the tab pages ([tabs]); the shell only places them.
/// The Cart tab opens on the cart and switches to the order history, which is
/// told when it is on screen so it re-reads `GET /v1/orders` when the customer
/// comes back to it.
class MainShellPage extends StatefulWidget {
  const MainShellPage({super.key, required this.tabs, this.initialIndex = 0});

  final ShellTabs tabs;
  final int initialIndex;

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  late int _index = widget.initialIndex;

  /// Stable key on the Cart tab's icon — the fly-to-cart destination. Kept
  /// across rebuilds and registered once so its global position stays correct.
  final GlobalKey _cartIconKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    FlyToCart.registerTarget(_cartIconKey);
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
        return Scaffold(
          // Keyed by language so a switch recreates the tab Elements (and thus
          // their State): strings a tab caches in State would otherwise stay
          // in the old language. Cost: tab scroll resets on a language switch.
          body: IndexedStack(
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
