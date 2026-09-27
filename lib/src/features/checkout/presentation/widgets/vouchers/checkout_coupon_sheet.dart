import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/domain/entities/cart_coupon_entity.dart';
import '../../../../../core/motion/haptics.dart';
import '../../../../../core/utils/failure_message.dart';
import '../../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../../cart/presentation/cubit/cart_state.dart';
import '../checkout/checkout_sheet_frame.dart';
import 'checkout_code_apply_button.dart';
import 'checkout_code_field.dart';

/// The coupon code sheet (`POST /v1/cart/coupon`), in the checkout sheet
/// shell with a sticker "Apply". It closes with `true` only once the cart
/// carries the code that was sent (compared ignoring case) — replacing a
/// code waits for the new one to land. A code of the wrong length is
/// refused before any call. A refusal shakes the field and shows one line:
/// the server's own coupon message, or "Couldn't apply the code. Try
/// again." when the cart would not take it (another action was running) —
/// never a stale failure of something else.
class CheckoutCouponSheet extends StatefulWidget {
  const CheckoutCouponSheet({super.key});

  @override
  State<CheckoutCouponSheet> createState() => _CheckoutCouponSheetState();
}

class _CheckoutCouponSheetState extends State<CheckoutCouponSheet> {
  final TextEditingController _controller = TextEditingController();

  /// Bumped on every refusal, to shake the field.
  int _refusals = 0;
  String? _error;

  /// The text the error was about; editing it clears the error.
  String _refusedText = '';

  /// The code sent and not seen on the cart yet.
  String? _awaiting;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onEdit);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onEdit)
      ..dispose();
    super.dispose();
  }

  void _onEdit() {
    if (_error != null && _controller.text != _refusedText) {
      setState(() => _error = null);
    }
  }

  void _refuse(String message) {
    Haptics.warning();
    setState(() {
      _error = message;
      _refusedText = _controller.text;
      _refusals++;
    });
  }

  void _onBlocked() {
    if (!CartCouponEntity.acceptsCode(_controller.text)) {
      _refuse('checkout.code_length'.tr());
    }
  }

  Future<void> _apply() async {
    if (_awaiting != null || _done) return;
    final code = _controller.text.trim();
    if (!CartCouponEntity.acceptsCode(code)) {
      _refuse('checkout.code_length'.tr());
      return;
    }
    final cart = context.read<CartCubit>();
    final before = cart.state;
    setState(() {
      _error = null;
      _awaiting = code;
    });
    final applied = await cart.applyCoupon(code);
    if (!mounted || _done) return;
    if (!applied) {
      // A cart that would not start the call (busy) leaves its state alone:
      // whatever failure it holds is not this code's.
      final after = cart.state;
      final failure =
          !identical(before, after) && after.failedAction == CartAction.coupon
          ? after.failure
          : null;
      _awaiting = null;
      _refuse(failure?.localizedMessage ?? 'checkout.code_try_again'.tr());
      return;
    }
    _landed(cart.state.cart.coupon);
  }

  /// Closes the sheet once [coupon] is the code that was sent.
  void _landed(CartCouponEntity? coupon) {
    final sent = _awaiting;
    if (sent == null || _done || coupon == null) return;
    if (coupon.code.toLowerCase() != sent.toLowerCase()) return;
    setState(() {
      _awaiting = null;
      _done = true;
    });
    Haptics.success();
    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CartCubit, CartState>(
      listenWhen: (previous, current) =>
          previous.cart.coupon != current.cart.coupon,
      listener: (_, state) => _landed(state.cart.coupon),
      child: CheckoutSheetFrame(
        title: 'checkout.code_sheet_title'.tr(),
        footer: CheckoutCodeApplyButton(
          controller: _controller,
          loading: _awaiting != null,
          success: _done,
          onPressed: _apply,
          onBlocked: _onBlocked,
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.s12,
            0,
            AppSpacing.s12,
            AppSpacing.s16,
          ),
          child: CheckoutCodeField(
            controller: _controller,
            shakeKey: _refusals,
            error: _error,
            onSubmitted: _apply,
          ),
        ),
      ),
    );
  }
}
