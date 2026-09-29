import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/motion/fade_through_switcher.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../cubit/address_book_cubit.dart';
import '../../cubit/address_book_state.dart';
import 'address_list_empty_view.dart';
import 'address_list_skeleton.dart';
import 'address_list_view.dart';

/// Switches the address screen on the book status — the bones cross-fade
/// into the book, other swaps fade through ([FadeThroughSwitcher]). A first
/// sync that failed for want of a connection says "Checking your
/// connection…", then "No connection" ([FailureView]); the app root syncs
/// again when the connection returns. Delete
/// progress and one-shot failures never rebuild it (rows and the page
/// listener own those).
class AddressListBody extends StatelessWidget {
  const AddressListBody({super.key});

  static const Object _emptyKey = #empty;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AddressBookCubit, AddressBookState>(
      buildWhen: (previous, current) =>
          previous.status != current.status ||
          previous.book != current.book ||
          previous.loadFailure != current.loadFailure,
      builder: (context, state) => FadeThroughSwitcher(
        // initial and loading share the bones; an empty book is a screen
        // of its own.
        stateKey: switch (state.status) {
          AddressBookStatus.initial => AddressBookStatus.loading,
          AddressBookStatus.loaded when state.book.isEmpty => _emptyKey,
          final status => status,
        },
        crossFade: true,
        child: switch (state.status) {
          AddressBookStatus.initial ||
          AddressBookStatus.loading => const AddressListSkeleton(),
          AddressBookStatus.signedOut => HeroStateView.signedOut(
            message: 'addr.sign_in_prompt'.tr(),
          ),
          AddressBookStatus.error => FailureView(
            failure: state.loadFailure,
            onRetry: () => context.read<AddressBookCubit>().refresh(),
          ),
          AddressBookStatus.loaded when state.book.isEmpty =>
            const AddressListEmptyView(),
          AddressBookStatus.loaded => AddressListView(book: state.book),
        },
      ),
    );
  }
}
