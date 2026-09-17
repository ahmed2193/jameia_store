import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/motion/fly_to_cart.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../language/presentation/cubit/localization_cubit.dart';
import '../../../language/presentation/cubit/localization_state.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../../../search/presentation/pages/search_page.dart';
import '../../../orders/presentation/pages/orders_page.dart';
import '../../../account/presentation/pages/mine_page.dart';

/// Jameia MainTabActivity equivalent — 4 tabs (Home / Search / Orders / Mine) over
/// an [IndexedStack] so each tab keeps its scroll + state. The Orders tab carries
/// a cart-count badge fed by the global [CartCubit].
class MainShellPage extends StatefulWidget {
  const MainShellPage({super.key, this.initialIndex = 0});
  final int initialIndex;

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  late int _index = widget.initialIndex;

  /// Stable key on the Orders-tab cart icon — the fly-to-cart destination. Kept
  /// across rebuilds and registered once so its global position stays correct.
  final GlobalKey _cartIconKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    FlyToCart.registerTarget(_cartIconKey);
  }

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
    // The tab instances are also deliberately NON-const: a const/cached tab is
    // canonicalized to an identical widget, so `IndexedStack.updateChild` would
    // short-circuit (identical → no rebuild) and skip re-localization. Fresh
    // instances rebuild while preserving State (scroll, cubits, loaded data)
    // via element reuse (same runtimeType + key → didUpdateWidget).
    return BlocBuilder<LocalizationCubit, LocalizationState>(
      buildWhen: (p, c) => p.locale != c.locale,
      builder: (context, state) {
        final tabs = <Widget>[
          // ignore: prefer_const_constructors
          HomePage(),
          // ignore: prefer_const_constructors
          SearchPage(),
          // ignore: prefer_const_constructors
          OrdersPage(),
          // ignore: prefer_const_constructors
          MinePage(),
        ];
        return Scaffold(
          // Key the IndexedStack by language so a switch recreates the tab
          // Elements (and thus their State). A plain rebuild only re-runs each
          // tab's build(); it does NOT re-run initState, so any strings a tab
          // caches in State (e.g. MinePage's menu list) would stay in the old
          // language. Re-keying forces fresh State → initState → caches rebuilt
          // in the new locale. Cost: tab scroll/position resets on a language
          // switch (a rare, deliberate action) — an acceptable trade-off.
          body: IndexedStack(
            key: ValueKey(state.languageCode),
            index: _index,
            children: tabs,
          ),
          bottomNavigationBar: _JameiaBottomNav(
            index: _index,
            cartIconKey: _cartIconKey,
            onTap: (i) => setState(() => _index = i),
          ),
        );
      },
    );
  }
}

class _JameiaBottomNav extends StatelessWidget {
  const _JameiaBottomNav({
    required this.index,
    required this.cartIconKey,
    required this.onTap,
  });
  final int index;
  final GlobalKey cartIconKey;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    // Rebuild the nav only when the cart *count* changes (not on every cart
    // emit — a subtotal-only change, e.g. VIP re-price, no longer repaints it).
    return BlocSelector<CartCubit, CartState, int>(
      selector: (s) => s.totalQty,
      builder: (context, cartQty) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          border: Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 56,
            child: Row(
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  label: 'tab_home'.tr(),
                  selected: index == 0,
                  onTap: () => onTap(0),
                ),
                _NavItem(
                  icon: Icons.search_rounded,
                  label: 'tab_search'.tr(),
                  selected: index == 1,
                  onTap: () => onTap(1),
                ),
                _NavItem(
                  icon: Icons.receipt_long_rounded,
                  label: 'tab_orders'.tr(),
                  selected: index == 2,
                  badge: cartQty,
                  iconKey: cartIconKey,
                  onTap: () => onTap(2),
                ),
                _NavItem(
                  icon: Icons.person_rounded,
                  label: 'tab_mine'.tr(),
                  selected: index == 3,
                  onTap: () => onTap(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge = 0,
    this.iconKey,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int badge;

  /// Attached to the rendered icon for the Orders tab so [FlyToCart] can locate
  /// the cart destination's global position.
  final GlobalKey? iconKey;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primaryText : AppColors.tertiaryText;
    return Expanded(
      child: PressScale(
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // Subtle selected-state scale-up (1.0 → 1.12), reduced-motion
                  // safe via AnimatedScale honouring disableAnimations.
                  AnimatedScale(
                    scale: selected ? 1.12 : 1.0,
                    duration: MotionGuard.duration(context, AppMotion.fast),
                    curve: MotionGuard.curve(context, AppMotion.signature),
                    child: Icon(icon, key: iconKey, size: 24, color: color),
                  ),
                  if (badge > 0)
                    PositionedDirectional(
                      end: -8,
                      top: -4,
                      child: PopScale(
                        popKey: badge,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          decoration: const BoxDecoration(
                            color: AppColors.finalPrice,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$badge',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.captionSmall.copyWith(
                              color: AppColors.white,
                              fontWeight: AppTextStyles.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: MotionGuard.duration(context, AppMotion.fast),
                curve: MotionGuard.curve(context, AppMotion.signature),
                style: AppTextStyles.captionSmall.copyWith(
                  color: color,
                  fontWeight: selected
                      ? AppTextStyles.bold
                      : AppTextStyles.regular,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
