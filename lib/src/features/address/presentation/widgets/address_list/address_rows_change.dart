/// How the list's rows moved between two books, by address id: the rows
/// [removed] from the old ones and [added] in the new ones. [keptOrder] says
/// the rows present in both kept their order, so the change can play as
/// folds and openings in place.
class AddressRowsChange {
  factory AddressRowsChange(List<String> before, List<String> next) {
    final beforeSet = before.toSet();
    final nextSet = next.toSet();
    final keptBefore = <String>[
      for (final id in before)
        if (nextSet.contains(id)) id,
    ];
    final keptNext = <String>[
      for (final id in next)
        if (beforeSet.contains(id)) id,
    ];
    var keptOrder = keptBefore.length == keptNext.length;
    for (var i = 0; keptOrder && i < keptBefore.length; i++) {
      keptOrder = keptBefore[i] == keptNext[i];
    }
    return AddressRowsChange._(
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

  const AddressRowsChange._({
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
