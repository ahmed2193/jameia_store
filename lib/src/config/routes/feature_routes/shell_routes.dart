// The builders return fresh instances on purpose (see ShellTabs).
// ignore_for_file: prefer_const_constructors
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/navigation.dart';
import '../../../features/account/presentation/pages/mine_page.dart';
import '../../../features/assistant/domain/entities/assistant_thought_place.dart';
import '../../../features/assistant/presentation/pages/assistant_buddy_layer_page.dart';
import '../../../features/cart/presentation/pages/cart_tab_page.dart';
import '../../../features/home/presentation/pages/home_page.dart';
import '../../../features/orders/presentation/pages/orders_page.dart';
import '../../../features/search/presentation/pages/search_page.dart';
import '../../../features/shell/presentation/pages/main_shell_page.dart';
import '../route_args/shell_entrance.dart';
import '../route_args/shell_tabs.dart';
import '../routes.dart';

Widget _home(BuildContext _) => HomePage();
Widget _search(BuildContext _) => SearchPage();
Widget _cart(VoidCallback onBrowse) => CartTabPage(onBrowse: onBrowse);
Widget _orderHistory(bool active) => OrdersPage(active: active, embedded: true);
Widget _mine(BuildContext _) => MinePage();

/// The assistant's buddy over the tabs: it greets on Home only, keeps its
/// launcher off the Cart tab (the checkout bar lives there), and its lines
/// suit the tab — offers and finds while browsing, finding and choosing in
/// search, help with a problem in the account.
Widget _assistant(ShellTab tab, Widget child) => AssistantBuddyLayerPage(
  place: tab.name,
  greetHere: tab == ShellTab.home,
  launcherHere: tab != ShellTab.cart,
  thoughtPlace: switch (tab) {
    ShellTab.home => AssistantThoughtPlace.browsing,
    ShellTab.search => AssistantThoughtPlace.searching,
    ShellTab.mine => AssistantThoughtPlace.account,
    ShellTab.cart => AssistantThoughtPlace.elsewhere,
  },
  child: child,
);

/// The four tabs of [MainShellPage]: Home / Search / Cart (+ order history) /
/// Mine, with the assistant's buddy floating over them.
const ShellTabs _tabs = ShellTabs(
  home: _home,
  search: _search,
  cart: _cart,
  orderHistory: _orderHistory,
  mine: _mine,
  overlay: _assistant,
);

/// Main tab shell plus the stand-alone tab pages. [Routes.shell] and
/// [Routes.home] both land on [MainShellPage].
final List<RouteBase> shellRoutes = <RouteBase>[
  GoRoute(
    path: Routes.shell,
    // From the splash the app fades in over it (Hero-style hand-off);
    // every other entrance keeps the standard page motion.
    pageBuilder: (_, state) => state.extra == ShellEntrance.splash
        ? HeroFadeThroughPage<Object?>(
            key: state.pageKey,
            name: state.uri.path,
            child: const MainShellPage(tabs: _tabs),
          )
        : HeroTransitionPage<Object?>(
            key: state.pageKey,
            name: state.uri.path,
            child: const MainShellPage(tabs: _tabs),
          ),
  ),
  GoRoute(
    path: Routes.home,
    pageBuilder: (_, state) => HeroTransitionPage<Object?>(
      key: state.pageKey,
      name: state.uri.path,
      child: const MainShellPage(tabs: _tabs),
    ),
  ),
  GoRoute(
    path: Routes.search,
    pageBuilder: (_, state) => HeroTransitionPage<Object?>(
      key: state.pageKey,
      name: state.uri.path,
      child: const SearchPage(),
    ),
  ),
  GoRoute(
    path: Routes.orders,
    pageBuilder: (_, state) => HeroTransitionPage<Object?>(
      key: state.pageKey,
      name: state.uri.path,
      child: const OrdersPage(),
    ),
  ),
  GoRoute(
    path: Routes.mine,
    pageBuilder: (_, state) => HeroTransitionPage<Object?>(
      key: state.pageKey,
      name: state.uri.path,
      child: const MinePage(),
    ),
  ),
];
