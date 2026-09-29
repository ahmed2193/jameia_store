import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/order_progress_entities.dart';

/// What picking did to one ordered line.
enum OrderLineOutcome { kept, unavailable, substituted }

/// The picker's changes by line key, so each receipt row can say "Out of
/// stock" or "Replaced with …" beside the product it concerns. Built once
/// per order from `picking` (unavailable lines, substituted lines); an order
/// nobody picked yet has no changes.
class OrderLineChanges extends Equatable {
  const OrderLineChanges._(this._unavailable, this._substitutions);

  factory OrderLineChanges.of(OrderPickingEntity? picking) {
    if (picking == null || !picking.hasChanges) return empty;
    return OrderLineChanges._(
      Set.unmodifiable(picking.unavailableLineKeys),
      Map.unmodifiable({
        for (final row in picking.substitutions) row.lineKey: row,
      }),
    );
  }

  static const OrderLineChanges empty = OrderLineChanges._(
    <String>{},
    <String, OrderSubstitutionEntity>{},
  );

  final Set<String> _unavailable;
  final Map<String, OrderSubstitutionEntity> _substitutions;

  bool get isEmpty => _unavailable.isEmpty && _substitutions.isEmpty;

  /// A substitution wins over "unavailable": the line was replaced.
  OrderLineOutcome outcomeOf(String lineKey) {
    if (_substitutions.containsKey(lineKey)) {
      return OrderLineOutcome.substituted;
    }
    if (_unavailable.contains(lineKey)) return OrderLineOutcome.unavailable;
    return OrderLineOutcome.kept;
  }

  /// What replaced the line, when it was substituted.
  OrderSubstitutionEntity? substitutionOf(String lineKey) =>
      _substitutions[lineKey];

  @override
  List<Object?> get props => [_unavailable, _substitutions];
}
