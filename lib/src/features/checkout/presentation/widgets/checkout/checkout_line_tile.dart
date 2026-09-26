import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/domain/entities/cart_line_entity.dart';
import '../../../../../core/domain/entities/cart_line_ref.dart';
import '../../../../cart/presentation/cubit/cart_cubit.dart';
import 'checkout_line_row.dart';

/// The row of the cart line [lineRef]. It selects that one line (compared by
/// value), so a re-price after a destination change rebuilds only the rows
/// whose line actually changed — and only the visible ones, since the list
/// builds lazily.
class CheckoutLineTile extends StatelessWidget {
  const CheckoutLineTile({super.key, required this.lineRef});

  /// A row's identity in the items list: its line, not its position.
  static Key keyFor(CartLineRef ref) => ValueKey<String>('checkout-line:$ref');

  final CartLineRef lineRef;

  @override
  Widget build(BuildContext context) {
    final line = context.select<CartCubit, CartLineEntity?>(
      (cubit) => cubit.state.cart.lines
          .where((line) => line.ref == lineRef)
          .firstOrNull,
    );
    if (line == null) return const SizedBox.shrink();
    return CheckoutLineRow(line: line);
  }
}
