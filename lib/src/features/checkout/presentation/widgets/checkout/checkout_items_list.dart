import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../../cart/presentation/cubit/cart_state.dart';
import 'checkout_gift_row.dart';
import 'checkout_line_tile.dart';

/// The rows of the items sheet: the paid lines, then the free gifts.
///
/// Lazy: it hugs a short basket (`shrinkWrap`) and, under the sheet's
/// finite max height, lays out only what shows of a long one. Rows differ in
/// height (one- or two-line names, tags, "Remove"), so there is no
/// prototype row. The list follows only WHICH rows there are, in order (line
/// refs and gift keys); a price or quantity change is the row's own
/// business (each row watches its line). Rows are keyed, so one that shifts
/// when another goes keeps its element.
class CheckoutItemsList extends StatelessWidget {
  const CheckoutItemsList({super.key});

  /// Both carts list the same lines and gifts in the same order.
  static bool _sameRows(CartState previous, CartState current) {
    final before = previous.cart;
    final after = current.cart;
    if (identical(before.lines, after.lines) &&
        identical(before.offerLines, after.offerLines)) {
      return true;
    }
    if (before.lines.length != after.lines.length ||
        before.offerLines.length != after.offerLines.length) {
      return false;
    }
    for (var i = 0; i < before.lines.length; i++) {
      if (before.lines[i].ref != after.lines[i].ref) return false;
    }
    for (var i = 0; i < before.offerLines.length; i++) {
      if (before.offerLines[i].key != after.offerLines[i].key) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartCubit, CartState>(
      buildWhen: (previous, current) => !_sameRows(previous, current),
      builder: (context, state) {
        final refs = [for (final line in state.cart.lines) line.ref];
        final gifts = [for (final gift in state.cart.offerLines) gift.key];
        final keys = <Key>[
          for (final ref in refs) CheckoutLineTile.keyFor(ref),
          for (final gift in gifts) CheckoutGiftRow.keyFor(gift),
        ];
        return ListView.builder(
          // Finite max height (the sheet frame), so this stays lazy.
          shrinkWrap: true,
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.s12,
            0,
            AppSpacing.s12,
            AppSpacing.s12,
          ),
          itemCount: keys.length,
          findChildIndexCallback: (key) {
            final index = keys.indexOf(key);
            return index < 0 ? null : index;
          },
          itemBuilder: (_, index) => index < refs.length
              ? CheckoutLineTile(key: keys[index], lineRef: refs[index])
              : CheckoutGiftRow(
                  key: keys[index],
                  giftKey: gifts[index - refs.length],
                ),
        );
      },
    );
  }
}
