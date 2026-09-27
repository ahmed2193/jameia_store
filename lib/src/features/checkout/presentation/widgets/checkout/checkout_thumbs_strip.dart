import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../../cart/presentation/cubit/cart_state.dart';
import '../../../domain/entities/checkout_thumbs.dart';
import 'checkout_pieces_label.dart';
import 'checkout_thumb_slot.dart';

/// The order-summary strip: as many fixed 56 dp picture slots as fit (up to
/// [CheckoutThumbs.maxSlots]), then "N pcs ›" at the end. One tap target
/// ([onTap] opens the items sheet), read as its pieces count.
///
/// It selects [CheckoutThumbs] (compared by value), so a sync flip or a
/// re-price that changes no shown picture or count rebuilds nothing; the
/// slots have a fixed size, so a change never moves the layout.
class CheckoutThumbsStrip extends StatelessWidget {
  const CheckoutThumbsStrip({super.key, required this.onTap});

  final VoidCallback onTap;

  static const double _thumb = AppSize.s56;
  static const double _gap = AppSpacing.s8;

  static const BorderRadius _radius = BorderRadius.all(
    Radius.circular(AppRadius.card),
  );

  /// How many slots a [width] wide strip holds (1..[CheckoutThumbs.maxSlots]).
  static int slotsFor(double width) => ((width + _gap) / (_thumb + _gap))
      .floor()
      .clamp(1, CheckoutThumbs.maxSlots);

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Semantics(
        button: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: _radius,
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              vertical: AppSpacing.s4,
            ),
            child: Row(
              children: [
                Expanded(
                  child: ExcludeSemantics(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final max = slotsFor(constraints.maxWidth);
                        return BlocSelector<
                          CartCubit,
                          CartState,
                          CheckoutThumbs
                        >(
                          selector: (state) =>
                              CheckoutThumbs.of(state.cart, max: max),
                          builder: (context, thumbs) => Row(
                            children: [
                              for (var i = 0; i < max; i++) ...[
                                if (i > 0) const SizedBox(width: _gap),
                                CheckoutThumbSlot(
                                  thumb: thumbs.slots.elementAtOrNull(i),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.s8),
                const CheckoutPiecesLabel(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
