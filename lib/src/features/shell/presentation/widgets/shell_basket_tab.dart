import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/routes/route_args/shell_tabs.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../cart/presentation/cubit/cart_state.dart';
import 'shell_basket_switch.dart';

/// The Cart tab: a pill switch over two views, the cart (default) and the
/// order history.
///
/// Both views stay alive once built, so switching back and forth keeps each
/// one's scroll and state. The history is only built the first time it is
/// chosen — opening the app on the cart costs no `GET /v1/orders` — and it is
/// told when it is on screen, so it re-reads the list every time the customer
/// comes back to it.
class ShellBasketTab extends StatefulWidget {
  const ShellBasketTab({
    super.key,
    required this.tabs,
    required this.active,
    required this.onBrowse,
  });

  final ShellTabs tabs;

  /// `true` while the Cart tab is the shell tab on screen.
  final bool active;

  /// Leaves for the Home tab (an empty cart's "add items").
  final VoidCallback onBrowse;

  @override
  State<ShellBasketTab> createState() => _ShellBasketTabState();
}

class _ShellBasketTabState extends State<ShellBasketTab> {
  ShellBasketView _view = ShellBasketView.cart;
  bool _historyBuilt = false;

  void _show(ShellBasketView view) {
    if (view == _view) return;
    setState(() {
      _view = view;
      if (view == ShellBasketView.orderHistory) _historyBuilt = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final onHistory = _view == ShellBasketView.orderHistory;
    // Dark status-bar icons: the tab has no AppBar to set them, and the Home
    // tab leaves them light for its orange header — white on this white
    // header they vanished.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: ColoredBox(
        color: AppColors.mediumBackground,
        child: Column(
          children: [
            ColoredBox(
              color: AppColors.white,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    AppSpacing.s16,
                    AppSpacing.s8,
                    AppSpacing.s16,
                    AppSpacing.s10,
                  ),
                  child: BlocSelector<CartCubit, CartState, int>(
                    selector: (state) => state.totalQty,
                    builder: (context, count) => ShellBasketSwitch(
                      view: _view,
                      cartCount: count,
                      onChanged: _show,
                    ),
                  ),
                ),
              ),
            ),
            const Divider(
              height: AppSize.s0_5,
              thickness: AppSize.s0_5,
              color: AppColors.divider,
            ),
            Expanded(
              // The views sit under this header, which already took the status
              // bar: they must not pad for it again.
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: IndexedStack(
                  index: _view.index,
                  children: [
                    widget.tabs.cart(widget.onBrowse),
                    if (_historyBuilt)
                      widget.tabs.orderHistory(widget.active && onHistory)
                    else
                      const SizedBox.shrink(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
