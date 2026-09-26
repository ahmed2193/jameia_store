import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/cart_entity.dart';
import '../../../../core/domain/entities/cart_line_ref.dart';
import '../../../../core/domain/entities/cart_offer_line_entity.dart';

/// The STRUCTURE of the cart's list — which paid lines (by [CartLineRef])
/// and which gifts — compared by value.
///
/// The lines sliver selects this instead of `cart.lines`: every tap hands
/// out a fresh `lines` list (the projection re-sums the cart), so a list
/// selected by identity rebuilt the whole list and every visible row per
/// tap. A quantity change leaves this value equal, and so does a server
/// reply that only moves an offer's progress (the deals strip selects that),
/// so only the tapped row (which selects its own line) rebuilds.
/// Presentation-only; the cubit is untouched.
class CartLinesLayout extends Equatable {
  CartLinesLayout.of(CartEntity cart)
    : refs = <CartLineRef>[for (final line in cart.lines) line.ref],
      offerLines = cart.offerLines;

  /// Prefix of a gift row's identity in [ids].
  static const String offerPrefix = 'offer:';

  /// The identity of [offer]'s row in [ids].
  static String offerId(CartOfferLineEntity offer) =>
      '$offerPrefix${offer.key}';

  /// Paid lines, in the cart's order.
  final List<CartLineRef> refs;

  /// Gift lines, drawn after the paid ones.
  final List<CartOfferLineEntity> offerLines;

  /// One identity per row, in list order: each paid line's [CartLineRef],
  /// then [offerId] per gift.
  late final List<Object> ids = <Object>[
    ...refs,
    for (final offer in offerLines) offerId(offer),
  ];

  late final Map<Object, int> _index = <Object, int>{
    for (var i = 0; i < ids.length; i++) ids[i]: i,
  };

  /// The row of [id] in [ids], or null when it is not in the list.
  int? indexOf(Object id) => _index[id];

  /// The gift whose row is [id], or null when [id] is not a gift here.
  CartOfferLineEntity? offerFor(Object id) {
    final index = _index[id];
    return index == null || index < refs.length
        ? null
        : offerLines[index - refs.length];
  }

  // Equatable compares the lists element by element.
  @override
  List<Object?> get props => [refs, offerLines];
}

/// How the rows moved from one [CartLinesLayout.ids] to the next, in the
/// terms an animated list takes: indices [removed] from the old rows and
/// [added] in the new ones. [keptOrder] says the rows present in both kept
/// their relative order — only then can removals and inserts replay the
/// change; otherwise the list is rebuilt as it is.
class CartLinesChange {
  factory CartLinesChange(List<Object> before, List<Object> next) {
    final beforeSet = before.toSet();
    final nextSet = next.toSet();
    final keptBefore = <Object>[
      for (final id in before)
        if (nextSet.contains(id)) id,
    ];
    final keptNext = <Object>[
      for (final id in next)
        if (beforeSet.contains(id)) id,
    ];
    var keptOrder = keptBefore.length == keptNext.length;
    for (var i = 0; keptOrder && i < keptBefore.length; i++) {
      keptOrder = keptBefore[i] == keptNext[i];
    }
    return CartLinesChange._(
      removed: <int>[
        for (var i = 0; i < before.length; i++)
          if (!nextSet.contains(before[i])) i,
      ],
      added: <int>[
        for (var j = 0; j < next.length; j++)
          if (!beforeSet.contains(next[j])) j,
      ],
      keptOrder: keptOrder,
    );
  }

  const CartLinesChange._({
    required this.removed,
    required this.added,
    required this.keptOrder,
  });

  /// Indices in the old rows, ascending.
  final List<int> removed;

  /// Indices in the new rows, ascending.
  final List<int> added;
  final bool keptOrder;

  /// The same rows, possibly reordered.
  bool get isReorder => removed.isEmpty && added.isEmpty;

  /// Rows that come or go.
  int get size => removed.length + added.length;
}
