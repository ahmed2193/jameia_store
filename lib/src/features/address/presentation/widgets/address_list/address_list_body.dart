import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/routes.dart';
import '../../../../../core/utils/failure_message.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../cubit/address_book_cubit.dart';
import '../../cubit/address_book_state.dart';
import 'address_list_empty_view.dart';
import 'address_list_skeleton.dart';
import 'address_list_view.dart';

/// Switches the address screen on the book status. Delete progress and
/// one-shot failures never rebuild it (rows and the page listener own those).
class AddressListBody extends StatelessWidget {
  const AddressListBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AddressBookCubit, AddressBookState>(
      buildWhen: (previous, current) =>
          previous.status != current.status ||
          previous.book != current.book ||
          previous.loadFailure != current.loadFailure,
      builder: (context, state) => switch (state.status) {
        AddressBookStatus.initial ||
        AddressBookStatus.loading => const AddressListSkeleton(),
        AddressBookStatus.signedOut => EmptyStateView(
          message: 'addr.sign_in_prompt'.tr(),
          icon: Icons.lock_outline_rounded,
          actionLabel: 'auth.log_in_or_sign_up'.tr(),
          onAction: () => context.go(Routes.login),
        ),
        AddressBookStatus.error => ErrorView(
          message: state.loadFailure?.localizedMessage,
          onRetry: () => context.read<AddressBookCubit>().refresh(),
        ),
        AddressBookStatus.loaded when state.book.isEmpty =>
          const AddressListEmptyView(),
        AddressBookStatus.loaded => AddressListView(book: state.book),
      },
    );
  }
}
