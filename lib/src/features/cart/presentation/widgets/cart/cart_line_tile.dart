import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/domain/entities/cart_line_entity.dart';
import '../../../../../core/domain/entities/cart_line_ref.dart';
import '../../../../../core/navigation/navigation.dart';
import '../../cubit/cart_cubit.dart';
import 'cart_line_row.dart';

/// One paid line on the cart page, wired to the cubit: it selects its own
/// line by [lineRef] and draws it with [CartLineRow]. The lines sliver hands
/// back the same tile on every rebuild, so a tap on one stepper rebuilds
/// that tile only — every other line compares equal and stays.
///
/// A "−" that takes the last piece away removes the line; the snack bar
/// that says so offers "Undo" (docs/motion B3-03), which puts the piece
/// back.
class CartLineTile extends StatelessWidget {
  const CartLineTile({super.key, required this.lineRef});

  final CartLineRef lineRef;

  void _decrement(BuildContext context, CartLineEntity line) {
    final cart = context.read<CartCubit>();
    cart.decrement(line);
    if (line.quantity > 1) return;
    showHeroSnackBar(
      context,
      'cart.line_removed'.tr(namedArgs: {'name': line.product.name}),
      actionLabel: 'core.undo'.tr(),
      onAction: () => cart.increment(line),
    );
  }

  @override
  Widget build(BuildContext context) {
    final line = context.select<CartCubit, CartLineEntity?>(
      (cubit) => cubit.state.cart.lineFor(lineRef),
    );
    if (line == null) return const SizedBox.shrink(); // removed mid-frame
    return CartLineRow(
      line: line,
      onIncrement: () {
        if (!line.canIncrement) return;
        context.read<CartCubit>().increment(line);
      },
      onDecrement: () => _decrement(context, line),
      onRemoveLine: () => context.read<CartCubit>().removeLine(line),
    );
  }
}
