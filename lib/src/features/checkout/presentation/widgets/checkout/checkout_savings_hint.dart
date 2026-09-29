import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/domain/entities/cart_savings.dart';
import '../../../../../core/domain/entities/cart_top_saving.dart';
import '../../../../../core/motion/float_loop.dart';
import '../../../../../core/motion/pop_switcher.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../cart/presentation/cubit/cart_cubit.dart';
import '../../cubit/checkout_cubit.dart';
import '../../cubit/checkout_state.dart';
import 'checkout_hint_bubble.dart';
import 'checkout_ui_controller.dart';

/// The "KD x off this item" bubble riding on "Place order": it follows the
/// button through the page's [CheckoutUiController.barLink], its end edge
/// just inside the button's end and its tail on the button's top.
///
/// It points at the basket line that saves the most against its struck
/// price ([CartSavings.top]) and stays away when no line does. It arrives
/// once the route has settled (a pop from its tail), floats for a few legs
/// and rests. A tap on it, any scroll the customer makes, or a failed place
/// dismisses it for the rest of the visit ([CheckoutUiController.hintDismissed]);
/// a scroll the page makes (a blocked tap) does not. It is gone once the
/// order is placed.
class CheckoutSavingsHint extends StatefulWidget {
  const CheckoutSavingsHint({super.key});

  @override
  State<CheckoutSavingsHint> createState() => _CheckoutSavingsHintState();
}

class _CheckoutSavingsHintState extends State<CheckoutSavingsHint> {
  /// Three float cycles (up and back), then rest.
  static const int _floatLegs = 6;

  /// How far inside the button's end edge the bubble's end edge sits.
  static const double _endInset = AppSpacing.s4;

  /// The route this page arrived on, while its entrance still runs.
  Animation<double>? _entrance;
  bool _waiting = false;
  bool _armed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_waiting || _armed) return;
    _waiting = true;
    final entrance = ModalRoute.of(context)?.animation;
    if (entrance == null || entrance.isCompleted) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _arm());
      return;
    }
    _entrance = entrance..addStatusListener(_onEntrance);
  }

  void _onEntrance(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _entrance?.removeStatusListener(_onEntrance);
    _entrance = null;
    _arm();
  }

  void _arm() {
    if (!mounted || _armed) return;
    setState(() => _armed = true);
  }

  @override
  void dispose() {
    _entrance?.removeStatusListener(_onEntrance);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final placed = context.select<CheckoutCubit, bool>(
      (cubit) => cubit.state.status == CheckoutStatus.placed,
    );
    if (placed) return const SizedBox.shrink();
    final checkout = context.read<CheckoutCubit>();
    final top = context.select<CartCubit, CartTopSaving?>(
      (cubit) => CartSavings.of(
        cubit.state.cart,
        quotedDeliveryFeeFils: checkout.state.selection?.deliveryFeeFils,
      ).top,
    );
    final ui = context.read<CheckoutUiController>();
    final direction = Directionality.of(context);
    final rtl = direction == TextDirection.rtl;
    return CompositedTransformFollower(
      link: ui.barLink,
      showWhenUnlinked: false,
      targetAnchor: AlignmentDirectional.topEnd.resolve(direction),
      followerAnchor: AlignmentDirectional.bottomEnd.resolve(direction),
      offset: Offset(rtl ? _endInset : -_endInset, 0),
      child: ValueListenableBuilder<bool>(
        valueListenable: ui.hintDismissed,
        builder: (context, dismissed, _) {
          final shown = _armed && !dismissed ? top : null;
          // Keyed on whether a bubble shows, not on which line it names: a
          // new top line updates the bubble in place, so the float keeps
          // its counted legs (one bounded loop per visit) instead of
          // popping and floating again.
          return PopSwitcher(
            stateKey: shown != null,
            alignment: AlignmentDirectional.bottomCenter,
            child: shown == null
                ? const SizedBox.shrink()
                : GestureDetector(
                    onTap: () => ui.hintDismissed.value = true,
                    child: FloatLoop(
                      amplitude: AppSize.s3,
                      count: _floatLegs,
                      // The bubble's picture is recorded once; each float
                      // frame only moves its layer.
                      child: RepaintBoundary(
                        child: CheckoutHintBubble(
                          imageUrl: shown.imageUrl,
                          savingKd: shown.savingKd,
                          quantity: shown.quantity,
                        ),
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }
}
