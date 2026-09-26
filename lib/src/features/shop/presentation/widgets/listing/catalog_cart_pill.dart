import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/routes.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/fly_to_cart.dart';
import '../../../../../core/widgets/view_cart_pill.dart';

/// The "View cart" card of a catalogue page's bottom bar: the basket's count,
/// subtotal and delivery line, a tap opens the cart. While its page is on
/// screen, products added on the page fly into its basket. A page behind another route
/// (the pill can appear there when the product page on top fills the basket)
/// never takes the flights; it takes them back once uncovered.
class CatalogCartPill extends StatefulWidget {
  const CatalogCartPill({
    super.key,
    required this.count,
    required this.totalKd,
    this.deliveryKd,
  });

  final int count;
  final double totalKd;
  final double? deliveryKd;

  @override
  State<CatalogCartPill> createState() => _CatalogCartPillState();
}

class _CatalogCartPillState extends State<CatalogCartPill> {
  final GlobalKey _disc = GlobalKey();

  /// Whether [_disc] is on the fly-to-cart destination stack.
  bool _isTarget = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // A route behind another is offstage with its tickers off: the disc is
    // hidden there, so it must not sit above the visible surface's own
    // target. Uncovered, it goes back on top of the stack.
    final onScreen = TickerMode.valuesOf(context).enabled;
    if (onScreen == _isTarget) return;
    _isTarget = onScreen;
    if (onScreen) {
      FlyToCart.pushTarget(_disc);
    } else {
      FlyToCart.popTarget(_disc);
    }
  }

  @override
  void dispose() {
    if (_isTarget) FlyToCart.popTarget(_disc);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s8,
        ),
        child: ViewCartPill(
          count: widget.count,
          totalKd: widget.totalKd,
          deliveryKd: widget.deliveryKd,
          targetKey: _disc,
          onTap: () => context.push(Routes.cartPreview),
        ),
      ),
    );
  }
}
