import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/domain/entities/cart_line_entity.dart';
import '../../../../../core/domain/entities/cart_line_ref.dart';
import '../../cubit/cart_cubit.dart';
import 'cart_line_row.dart';

/// One paid line on the cart page, wired to the cubit: it selects its own
/// line by [lineRef] and draws it with [CartLineRow]. The lines sliver hands
/// back the same tile on every rebuild, so a tap on one stepper rebuilds
/// that tile only — every other line compares equal and stays.
class CartLineTile extends StatelessWidget {
  const CartLineTile({super.key, required this.lineRef});

  final CartLineRef lineRef;

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
      onDecrement: () => context.read<CartCubit>().decrement(line),
      onRemoveLine: () => context.read<CartCubit>().removeLine(line),
    );
  }
}
