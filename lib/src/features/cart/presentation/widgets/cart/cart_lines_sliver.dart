import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/domain/entities/cart_line_entity.dart';
import '../../../../../core/domain/entities/cart_line_ref.dart';
import '../../../../../core/motion/list_item_transition.dart';
import '../../../../../core/motion/motion.dart';
import '../../cubit/cart_cubit.dart';
import '../../cubit/cart_lines_layout.dart';
import '../../cubit/cart_state.dart';
import 'cart_line_ghost.dart';
import 'cart_line_separated.dart';
import 'cart_line_tile.dart';
import 'cart_offer_line_tile.dart';

/// The paid lines, then the gifts, as one lazy animated sliver with hairlines
/// between rows. It selects the list's STRUCTURE ([CartLinesLayout]) itself,
/// so a quantity tap or a progress-only reply never rebuilds it. A line that
/// arrives opens its gap and fades in; a line that leaves fades and closes —
/// at most four rows per change, only while the page is on screen and
/// motion is allowed. Anything else (a clear, a big change, the hidden Cart
/// tab) lands at once, and a pure reorder moves the rows as they are. Rows
/// keep their element across inserts and removals (keyed, with an index
/// callback), and each paid row is one cached widget that rebuilds only
/// through its own line.
class CartLinesSliver extends StatefulWidget {
  const CartLinesSliver({super.key});

  @override
  State<CartLinesSliver> createState() => _CartLinesSliverState();
}

class _CartLinesSliverState extends State<CartLinesSliver> {
  static const int _maxAnimated = 4;

  GlobalKey<SliverAnimatedListState> _listKey =
      GlobalKey<SliverAnimatedListState>();

  /// The structure the list was last drawn from.
  CartLinesLayout? _layout;

  /// One widget per paid row, handed back on every rebuild so the framework
  /// skips it: a row rebuilds only when its own line changes.
  final Map<CartLineRef, Widget> _tiles = <CartLineRef, Widget>{};

  // The paid lines of the last two snapshots that changed them: a line that
  // just left folds away as the customer last saw it. Keeping them costs two
  // assignments per snapshot.
  List<CartLineEntity> _linesNow = const <CartLineEntity>[];
  List<CartLineEntity> _linesBefore = const <CartLineEntity>[];

  @override
  void initState() {
    super.initState();
    _linesNow = context.read<CartCubit>().state.cart.lines;
  }

  void _onLines(BuildContext context, CartState state) {
    _linesBefore = _linesNow;
    _linesNow = state.cart.lines;
  }

  /// Moves the animated list from the last drawn structure to [next]. Rows
  /// that stay the same (gift data only, or a rebuild for another reason)
  /// replay nothing, so this is safe to run on every build.
  void _moveTo(CartLinesLayout next) {
    final before = _layout;
    _layout = next;
    if (before == null || listEquals(before.ids, next.ids)) return;
    _replay(CartLinesChange(before.ids, next.ids), before, next);
    _tiles.removeWhere((ref, _) => next.indexOf(ref) == null);
  }

  /// Replays [change] on the animated list; a reorder mixed with rows that
  /// come or go gets a fresh list instead.
  void _replay(
    CartLinesChange change,
    CartLinesLayout old,
    CartLinesLayout next,
  ) {
    if (change.isReorder) return; // the keyed rows move as they are
    final list = _listKey.currentState;
    if (!change.keptOrder || list == null) {
      _listKey = GlobalKey<SliverAnimatedListState>();
      return;
    }
    // TickerMode is read without subscribing: showing or hiding the tab must
    // not rebuild the list.
    final animate =
        next.ids.isNotEmpty &&
        change.size <= _maxAnimated &&
        !MotionGuard.reduced(context) &&
        TickerMode.getValuesNotifier(context).value.enabled;
    // Removals from the end, then inserts from the start: indices count as if
    // each removal happened at once (SliverAnimatedList's contract).
    for (final i in change.removed.reversed) {
      final ghost = animate
          ? CartLineGhost.of(old.ids[i], old, _linesBefore)
          : null;
      list.removeItem(
        i,
        (_, animation) => ghost == null
            ? const SizedBox.shrink()
            : ListItemTransition(
                animation: animation,
                leaving: true,
                child: CartLineSeparated(first: i == 0, child: ghost),
              ),
        duration: ghost == null ? Duration.zero : AppMotion.medium,
      );
    }
    for (final j in change.added) {
      list.insertItem(j, duration: animate ? AppMotion.medium : Duration.zero);
    }
  }

  int? _findIndex(Key key) =>
      key is ValueKey<Object> ? _layout?.indexOf(key.value) : null;

  @override
  Widget build(BuildContext context) {
    final layout = context.select<CartCubit, CartLinesLayout>(
      (cubit) => CartLinesLayout.of(cubit.state.cart),
    );
    _moveTo(layout);
    return BlocListener<CartCubit, CartState>(
      listenWhen: (previous, current) =>
          !identical(previous.cart.lines, current.cart.lines),
      listener: _onLines,
      child: SliverAnimatedList(
        key: _listKey,
        initialItemCount: layout.ids.length,
        findChildIndexCallback: _findIndex,
        itemBuilder: (context, index, animation) {
          final refs = layout.refs;
          final row = index < refs.length
              ? _tiles[refs[index]] ??= CartLineTile(
                  key: ValueKey<CartLineRef>(refs[index]),
                  lineRef: refs[index],
                )
              : CartOfferLineTile(line: layout.offerLines[index - refs.length]);
          // Constant shape (never the bare row once settled): the row keeps
          // its element when its animation ends.
          return ListItemTransition(
            key: ValueKey<Object>(layout.ids[index]),
            animation: animation,
            child: CartLineSeparated(first: index == 0, child: row),
          );
        },
      ),
    );
  }
}
