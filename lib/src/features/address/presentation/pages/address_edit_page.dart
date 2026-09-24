import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../core/domain/entities/jameia_address_entity.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/navigation/navigation.dart';
import '../../../../core/utils/failure_message.dart';
import '../cubit/address_book_cubit.dart';
import '../cubit/address_edit_cubit.dart';
import '../cubit/address_edit_state.dart';
import '../widgets/address_edit/address_edit_view.dart';

/// Create / edit an address: pick the pin on the map, fill the form, save
/// (`POST /v1/account/addresses` or `PATCH …/:addressId` with the changed
/// fields). The saved address goes to the app-global `AddressBookCubit`
/// (memory + device copy) and the route pops with it.
class AddressEditPage extends StatelessWidget {
  const AddressEditPage({super.key, this.address});

  /// The address being edited; `null` for "New address".
  final JameiaAddressEntity? address;

  static bool _listenWhen(
    AddressEditState previous,
    AddressEditState current,
  ) =>
      previous.status != current.status ||
      current.rejected ||
      (current.failure != null && previous.failure != current.failure);

  void _onState(BuildContext context, AddressEditState state) {
    final saved = state.saved;
    if (state.status == AddressEditStatus.saved && saved != null) {
      if (saved != state.original) {
        context.read<AddressBookCubit>().applySaved(saved);
        showJameiaSnackBar(context, 'addr.saved'.tr());
      }
      context.pop(saved);
      return;
    }
    if (state.rejected) {
      showJameiaSnackBar(context, 'addr.fix_errors'.tr());
      return;
    }
    final failure = state.failure;
    if (failure == null) return;
    showJameiaSnackBar(context, failure.localizedMessage);
    if (state.isEditing && _isGone(failure)) {
      // Deleted on another device: refresh the book and leave the form.
      context.read<AddressBookCubit>().refresh();
      context.pop();
    }
  }

  static bool _isGone(Failure failure) =>
      failure is ServerFailure && failure.statusCode == _notFound;

  static const int _notFound = 404;

  @override
  Widget build(BuildContext context) {
    // One instance: toggling PopScope while saving never rebuilds the map.
    final view = AddressEditView(isEdit: address != null);
    return BlocProvider(
      create: (context) {
        final book = context.read<AddressBookCubit>().state;
        // "First address" only when the server's book is known to be empty.
        final isFirstAddress = book.isSynced && book.book.isEmpty;
        return sl<AddressEditCubit>(param1: address, param2: isFirstAddress);
      },
      child: BlocListener<AddressEditCubit, AddressEditState>(
        listenWhen: _listenWhen,
        listener: _onState,
        // Leaving while the save is in flight would drop its reply.
        child: BlocSelector<AddressEditCubit, AddressEditState, bool>(
          selector: (state) => state.isSaving,
          builder: (context, saving) => PopScope(canPop: !saving, child: view),
        ),
      ),
    );
  }
}
