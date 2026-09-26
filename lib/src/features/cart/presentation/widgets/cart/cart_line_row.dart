import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/domain/entities/cart_line_entity.dart';
import '../../../../../core/motion/fade_through_switcher.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/widgets/jameia_text_link.dart';
import 'cart_line_frame.dart';
import 'cart_line_info.dart';
import 'cart_qty_stepper.dart';

/// One paid line as drawn: picture, name (+ variant), unit price with the
/// struck "was" price, the server's note if any, and the stepper. A line
/// that cannot be bought any more offers "Remove" instead of the stepper
/// (cross-faded when it flips); a line still on its way to the server is
/// dimmed. Pure: it takes the line and the actions, so the same row also
/// draws a line that is folding away.
class CartLineRow extends StatelessWidget {
  const CartLineRow({
    super.key,
    required this.line,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemoveLine,
  });

  static const double _pendingOpacity = 0.6;
  static const double _settledOpacity = 1;

  final CartLineEntity line;

  /// One more piece (the stepper's "+").
  final VoidCallback onIncrement;

  /// One piece less; at 1 it removes the line (the bin).
  final VoidCallback onDecrement;

  /// Drops a line that blocks checkout ("Remove").
  final VoidCallback onRemoveLine;

  @override
  Widget build(BuildContext context) {
    final blocked = line.blocksCheckout;
    return AnimatedOpacity(
      opacity: line.isLocalOnly ? _pendingOpacity : _settledOpacity,
      duration: MotionGuard.duration(context, AppMotion.fast),
      child: CartLineFrame(
        imageUrl: line.product.image,
        body: CartLineInfo(line: line),
        trailing: FadeThroughSwitcher(
          stateKey: blocked,
          alignment: AlignmentDirectional.centerEnd,
          child: blocked
              ? JameiaTextLink(
                  label: 'cart.remove'.tr(),
                  navigates: false,
                  onTap: onRemoveLine,
                )
              : CartQtyStepper(
                  qty: line.quantity,
                  canIncrement: line.canIncrement,
                  onIncrement: onIncrement,
                  onDecrement: onDecrement,
                ),
        ),
      ),
    );
  }
}
