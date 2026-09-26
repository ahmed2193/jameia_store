import 'package:flutter/material.dart';

import '../../../../../core/domain/entities/cart_line_entity.dart';
import '../../../../../core/domain/entities/cart_line_ref.dart';
import '../../../../../core/domain/entities/cart_offer_line_entity.dart';
import '../../cubit/cart_lines_layout.dart';
import 'cart_line_row.dart';
import 'cart_offer_line_tile.dart';

/// A row that just left the cart, drawn as the customer last saw it while it
/// folds away: a paid line (a bin tap at 1 folds a row showing 1) or a gift.
/// Its stepper keeps the enabled look; the leaving transition blocks taps.
/// It never takes the live tile's key, so a line added back gets a new row
/// beside the one still folding.
class CartLineGhost extends StatelessWidget {
  const CartLineGhost._({this.line, this.offer});

  /// The ghost of row [id] from [layout], the list as it was drawn, with
  /// [lines] the paid lines of that moment; null when the row is unknown
  /// (it then goes at once).
  static CartLineGhost? of(
    Object id,
    CartLinesLayout layout,
    List<CartLineEntity> lines,
  ) {
    if (id is CartLineRef) {
      for (final line in lines) {
        if (line.ref == id) return CartLineGhost._(line: line);
      }
      return null;
    }
    final offer = layout.offerFor(id);
    return offer == null ? null : CartLineGhost._(offer: offer);
  }

  final CartLineEntity? line;
  final CartOfferLineEntity? offer;

  static void _ignore() {}

  @override
  Widget build(BuildContext context) {
    final paid = line;
    final gift = offer;
    if (paid != null) {
      return CartLineRow(
        line: paid,
        onIncrement: _ignore,
        onDecrement: _ignore,
        onRemoveLine: _ignore,
      );
    }
    return gift == null
        ? const SizedBox.shrink()
        : CartOfferLineTile(line: gift);
  }
}
