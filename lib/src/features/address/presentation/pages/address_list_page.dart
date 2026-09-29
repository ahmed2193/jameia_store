import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../core/navigation/navigation.dart';
import '../../../../core/responsive/content_clamp.dart';
import '../../../../core/widgets/connectivity_scope.dart';
import '../cubit/address_book_cubit.dart';
import '../cubit/address_book_state.dart';
import '../widgets/address_list/address_add_bar.dart';
import '../widgets/address_list/address_list_app_bar.dart';
import '../widgets/address_list/address_list_body.dart';

/// Mine → "My addresses" (also the address picker from Home: a tapped row
/// pops the route with that address).
///
/// Reads the app-global `AddressBookCubit`, which already holds the book
/// (device copy + a sync on sign-in), so the list is instant. Opening the
/// page syncs only when this session has not reached the server yet (launch
/// offline, a guest → sign-in prompt).
///
/// A confirmed delete is optimistic (B1-17): the row folds away at once and
/// "Address deleted · Undo" offers it back while the delete waits; a
/// refused delete brings the row back in place with the reason — told on
/// the app's messenger even when the customer has left the list by then.
class AddressListPage extends StatefulWidget {
  const AddressListPage({super.key});

  @override
  State<AddressListPage> createState() => _AddressListPageState();
}

class _AddressListPageState extends State<AddressListPage> {
  @override
  void initState() {
    super.initState();
    unawaited(context.read<AddressBookCubit>().ensureSynced());
  }

  static bool _listenWhen(
    AddressBookState previous,
    AddressBookState current,
  ) =>
      current.deletedId != null ||
      (current.failure != null && previous.failure != current.failure);

  void _onState(BuildContext context, AddressBookState state) {
    final deletedId = state.deletedId;
    if (deletedId != null) {
      // App-global: Undo still works once this page is gone.
      final book = context.read<AddressBookCubit>();
      showHeroSnackBar(
        context,
        'addr.deleted'.tr(),
        tone: HeroSnackTone.success,
        actionLabel: 'core.undo'.tr(),
        onAction: () => book.undoDelete(deletedId),
      );
      unawaited(
        _tellRefusalAfterLeaving(
          book,
          deletedId,
          ScaffoldMessenger.of(context),
          offline: ConnectivityScope.readIsOffline(context),
        ),
      );
      return;
    }
    final failure = state.failure;
    // A failed first load / the sign-in prompt is rendered by the body.
    if (failure == null || !state.isLoaded) return;
    // A delete is the customer's action; a sync is a read.
    showFailureSnackBar(
      context,
      failure,
      action: state.failedAction == AddressBookAction.delete,
    );
  }

  /// The delete of [id] answers after the Undo window. While this page is up
  /// its listener tells a refusal; once the customer has left, nobody would
  /// — the row just comes back — so it is told here, on the app's
  /// [messenger] read at the delete.
  Future<void> _tellRefusalAfterLeaving(
    AddressBookCubit book,
    String id,
    ScaffoldMessengerState messenger, {
    required bool offline,
  }) async {
    final outcome = await book.stream.firstWhere(
      (state) => !state.deletingIds.contains(id),
      orElse: () => book.state,
    );
    final failure = outcome.failure;
    if (mounted ||
        failure == null ||
        outcome.failedAction != AddressBookAction.delete) {
      return;
    }
    showActionFailureSnackBarOn(messenger, failure, offline: offline);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AddressBookCubit, AddressBookState>(
      listenWhen: _listenWhen,
      listener: _onState,
      child: const Scaffold(
        backgroundColor: AppColors.mediumBackground,
        appBar: AddressListAppBar(),
        body: SafeArea(
          top: false,
          child: ContentClamp(child: AddressListBody()),
        ),
        bottomNavigationBar: AddressAddBar(),
      ),
    );
  }
}
