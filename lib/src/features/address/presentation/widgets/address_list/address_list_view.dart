import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/entrance_cascade.dart';
import '../../../../../core/motion/list_item_transition.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/widgets/branded_refresh.dart';
import '../../../domain/entities/address_book.dart';
import '../../cubit/address_book_cubit.dart';
import 'address_row.dart';
import 'address_rows_change.dart';

/// The book as one white grouped card (RE §5), built lazily. Rows are keyed
/// by address id, so a delete or a sync keeps every other row's element;
/// the first rows cascade in once, when the book first arrives. A row that
/// leaves (a delete) fades and folds its gap; one that comes back in place
/// (an Undo, a refused delete) or arrives opens its gap and fades in (B1-17)
/// — a few rows at a time, while motion is allowed; anything else lands at
/// once.
class AddressListView extends StatefulWidget {
  const AddressListView({super.key, required this.book});

  final AddressBook book;

  @override
  State<AddressListView> createState() => _AddressListViewState();
}

class _AddressListViewState extends State<AddressListView> {
  static const int _maxAnimated = 4;

  GlobalKey<SliverAnimatedListState> _listKey =
      GlobalKey<SliverAnimatedListState>();

  static List<String> _idsOf(AddressBook book) => [
    for (final address in book.addresses) address.id,
  ];

  @override
  void didUpdateWidget(AddressListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.book != widget.book) _replay(oldWidget.book, widget.book);
  }

  /// Plays the move from [before] to [next] on the animated list; a reorder
  /// mixed with rows that come or go gets a fresh list instead.
  void _replay(AddressBook before, AddressBook next) {
    final change = AddressRowsChange(_idsOf(before), _idsOf(next));
    if (change.isReorder) return; // the keyed rows move as they are
    final list = _listKey.currentState;
    if (!change.keptOrder || list == null) {
      _listKey = GlobalKey<SliverAnimatedListState>();
      return;
    }
    final animate =
        change.size <= _maxAnimated && !MotionGuard.reduced(context);
    final duration = animate ? AppMotion.medium : Duration.zero;
    final lastBefore = before.addresses.length - 1;
    // Removals from the end, then inserts from the start: indices count as if
    // each removal happened at once (SliverAnimatedList's contract).
    for (final i in change.removed.reversed) {
      final gone = before.addresses[i];
      list.removeItem(
        i,
        (_, animation) => animate
            ? ListItemTransition(
                animation: animation,
                leaving: true,
                child: AddressRow(
                  address: gone,
                  index: i,
                  isFirst: i == 0,
                  isLast: i == lastBefore,
                ),
              )
            : const SizedBox.shrink(),
        duration: duration,
      );
    }
    for (final j in change.added) {
      list.insertItem(j, duration: duration);
    }
  }

  @override
  Widget build(BuildContext context) {
    final addresses = widget.book.addresses;
    final lastIndex = addresses.length - 1;
    final indexById = <String, int>{
      for (var index = 0; index < addresses.length; index++)
        addresses[index].id: index,
    };
    return BrandedRefresh(
      onRefresh: () => context.read<AddressBookCubit>().refresh(),
      child: EntranceCascade(
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.s12),
              sliver: SliverAnimatedList(
                key: _listKey,
                initialItemCount: addresses.length,
                findChildIndexCallback: (key) =>
                    key is ValueKey<String> ? indexById[key.value] : null,
                itemBuilder: (_, index, animation) => ListItemTransition(
                  // Constant shape: a row keeps its element once its
                  // animation ends.
                  key: ValueKey<String>(addresses[index].id),
                  animation: animation,
                  child: AddressRow(
                    address: addresses[index],
                    index: index,
                    isFirst: index == 0,
                    isLast: index == lastIndex,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
