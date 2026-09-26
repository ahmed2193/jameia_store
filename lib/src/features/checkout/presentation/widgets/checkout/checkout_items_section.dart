import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/domain/entities/cart_line_ref.dart';
import '../../../../../core/widgets/thin_divider.dart';
import '../../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../../cart/presentation/cubit/cart_state.dart';
import 'checkout_line_tile.dart';
import 'checkout_section_title.dart';

/// The cart lines being ordered — a SLIVER for the checkout scroll view: the
/// section title, then one flat row per line with hairlines between them,
/// built lazily (a big cart lays out only what is on screen).
///
/// The list follows only WHICH lines there are, in order: a quantity or price
/// change is the row's own business (each row watches its line). Rows are
/// keyed by their line, so one that shifts when another goes keeps its row.
class CheckoutItemsSection extends StatelessWidget {
  const CheckoutItemsSection({super.key});

  /// Both carts list the same lines in the same order.
  static bool _sameLines(CartState previous, CartState current) {
    final before = previous.cart.lines;
    final after = current.cart.lines;
    if (identical(before, after)) return true;
    if (before.length != after.length) return false;
    for (var i = 0; i < before.length; i++) {
      if (before[i].ref != after[i].ref) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: CheckoutSectionTitle('checkout.items_title'.tr()),
        ),
        BlocBuilder<CartCubit, CartState>(
          buildWhen: (previous, current) => !_sameLines(previous, current),
          builder: (context, state) {
            final refs = <CartLineRef>[
              for (final line in state.cart.lines) line.ref,
            ];
            return SliverList.separated(
              itemCount: refs.length,
              findItemIndexCallback: (key) {
                final index = refs.indexWhere(
                  (ref) => CheckoutLineTile.keyFor(ref) == key,
                );
                return index < 0 ? null : index;
              },
              separatorBuilder: (_, _) =>
                  const ThinDivider(indent: AppSpacing.gutter),
              itemBuilder: (_, index) => CheckoutLineTile(
                key: CheckoutLineTile.keyFor(refs[index]),
                lineRef: refs[index],
              ),
            );
          },
        ),
      ],
    );
  }
}
