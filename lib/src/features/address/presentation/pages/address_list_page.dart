import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../core/navigation/navigation.dart';
import '../../../../core/responsive/content_clamp.dart';
import '../../../../core/widgets/connectivity_scope.dart';
import '../../../../core/widgets/hero_title_bar.dart';
import '../cubit/address_book_cubit.dart';
import '../cubit/address_book_state.dart';
import '../widgets/address_list/address_add_bar.dart';
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
      _offerUndo(context, book, deletedId);
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

  /// "Address deleted · Undo". The Undo window is the snack's whole life
  /// (I2): the held DELETE goes out only once the snack closed without the
  /// action (timed out, replaced, swiped away) — so an Undo the customer can
  /// still see always works. An Undo that finds nothing to undo (the
  /// session ended meanwhile) says so instead of closing as if it had.
  void _offerUndo(BuildContext context, AddressBookCubit book, String id) {
    final messenger = ScaffoldMessenger.of(context);
    var undone = false;
    final snack = showHeroSnackBar(
      context,
      'addr.deleted'.tr(),
      tone: HeroSnackTone.success,
      actionLabel: 'core.undo'.tr(),
      onAction: () => undone = book.undoDelete(id),
    );
    if (snack == null) {
      book.releaseDelete(id);
      return;
    }
    unawaited(
      snack.closed.then((reason) {
        if (reason != SnackBarClosedReason.action) {
          book.releaseDelete(id);
        } else if (!undone) {
          showHeroSnackBarOn(
            messenger,
            'addr.undo_too_late'.tr(),
            tone: HeroSnackTone.warning,
          );
        }
      }),
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
      child: Scaffold(
        backgroundColor: AppColors.mediumBackground,
        appBar: HeroTitleBar(title: 'addr.my_addresses'.tr()),
        body: const SafeArea(
          top: false,
          child: ContentClamp(child: AddressListBody()),
        ),
        bottomNavigationBar: const AddressAddBar(),
      ),
    );
  }
}
