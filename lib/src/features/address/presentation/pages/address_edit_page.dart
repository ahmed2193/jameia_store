import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/domain/entities/hero_address_entity.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/motion/haptics.dart';
import '../../../../core/motion/success_beat.dart';
import '../../../../core/navigation/navigation.dart';
import '../../../../core/widgets/cubit_busy_overlay.dart';
import '../../../auth/presentation/cubit/auth_session_cubit.dart';
import '../../domain/entities/new_address_seed.dart';
import '../cubit/address_book_cubit.dart';
import '../cubit/address_edit_cubit.dart';
import '../cubit/address_edit_state.dart';
import '../cubit/address_picker_cubit.dart';
import '../cubit/address_picker_state.dart';
import '../widgets/address_edit/address_edit_view.dart';
import '../widgets/address_edit/location_notice_labels.dart';

/// Create / edit an address: place the pin on the map (a fixed pin over a
/// map that moves under it), fill in the form, save
/// (`POST /v1/account/addresses` or `PATCH …/:addressId` with the changed
/// fields). The saved address goes to the app-global `AddressBookCubit`
/// (memory + device copy) and the route pops with it.
class AddressEditPage extends StatelessWidget {
  const AddressEditPage({super.key, this.address});

  /// The address being edited; `null` for "New address".
  final HeroAddressEntity? address;

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
      if (saved == state.original) {
        context.pop(saved);
        return;
      }
      context.read<AddressBookCubit>().applySaved(saved);
      unawaited(_afterSaved(context, saved));
      return;
    }
    if (state.rejected) {
      showHeroSnackBar(
        context,
        'addr.fix_errors'.tr(),
        tone: HeroSnackTone.warning,
      );
      return;
    }
    final failure = state.failure;
    if (failure == null) return;
    // A save: offline it says so, and the form keeps every value.
    showFailureSnackBar(context, failure, action: true);
    if (state.isEditing && failure is NotFoundFailure) {
      // Deleted on another device: refresh the book and leave the form.
      context.read<AddressBookCubit>().refresh();
      context.pop();
    }
  }

  /// The overlay's check draws and holds (docs/motion B2-04), then the
  /// route pops with the saved address.
  Future<void> _afterSaved(
    BuildContext context,
    HeroAddressEntity saved,
  ) async {
    Haptics.done();
    await SuccessBeat.hold(context);
    if (!context.mounted) return;
    showHeroSnackBar(context, 'addr.saved'.tr(), tone: HeroSnackTone.success);
    context.pop(saved);
  }

  /// A read of the confirmed pin that landed after Confirm stopped waiting
  /// fills what the form still lacks.
  void _onPlaceRead(BuildContext context, AddressPickerState state) {
    final place = state.place;
    if (place != null) context.read<AddressEditCubit>().pinReadLate(place);
  }

  /// "Find me" could not move the map: why, and — when a setting can fix
  /// it — the way there.
  void _onNotice(BuildContext context, AddressPickerState state) {
    final notice = state.notice;
    if (notice == null) return;
    final picker = context.read<AddressPickerCubit>();
    final text = locationNoticeText(notice);
    showHeroSnackBar(
      context,
      text.message,
      tone: HeroSnackTone.warning,
      actionLabel: text.action,
      onAction: text.action == null
          ? null
          : () => unawaited(picker.openSettings(notice)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = address;
    // Read here, not in a provider's create (which may not listen); the view
    // passes later changes on.
    final languageCode = context.locale.languageCode;
    // One instance: toggling PopScope while saving never rebuilds the map.
    final view = AddressEditView(
      isEdit: editing != null,
      // No pin yet: the map comes first, on the customer.
      startsOnMap: editing?.location == null,
    );
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) {
            final book = context.read<AddressBookCubit>().state;
            final customer = context.read<AuthSessionCubit>().state.customer;
            return sl<AddressEditCubit>(
              param1: editing,
              param2: NewAddressSeed(
                // "First address" only when the server's book is known to
                // be empty.
                isDefault: book.isSynced && book.book.isEmpty,
                // The number the customer signed in with.
                customerPhone: customer?.phone ?? '',
              ),
            );
          },
        ),
        BlocProvider(
          create: (context) {
            // An address with a pin opens the map on it, already read.
            final pinned = editing?.location == null
                ? null
                : context.read<AddressEditCubit>().state.draft.pinnedPlace;
            return sl<AddressPickerCubit>(param1: pinned)..start(
              languageCode: languageCode,
              findMe: editing?.location == null,
            );
          },
        ),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<AddressEditCubit, AddressEditState>(
            listenWhen: _listenWhen,
            listener: _onState,
          ),
          BlocListener<AddressPickerCubit, AddressPickerState>(
            listenWhen: (previous, next) => next.notice != null,
            listener: _onNotice,
          ),
          BlocListener<AddressPickerCubit, AddressPickerState>(
            listenWhen: (previous, next) =>
                next.place != null && previous.place != next.place,
            listener: _onPlaceRead,
          ),
        ],
        // Saving holds the whole screen (map, form, back) until the reply.
        child: CubitBusyOverlay<AddressEditCubit, AddressEditState>(
          busyOf: (state) => state.isSaving,
          doneOf: (state) =>
              state.status == AddressEditStatus.saved &&
              state.saved != null &&
              state.saved != state.original,
          failOf: (state) => !state.isSaving && state.failure != null,
          doneLabel: 'addr.saved'.tr(),
          child: Scaffold(
            backgroundColor: AppColors.mediumBackground,
            // The form lifts its own Save bar; the map never resizes.
            resizeToAvoidBottomInset: false,
            // Leaving while the save is in flight would drop its reply.
            body: BlocSelector<AddressEditCubit, AddressEditState, bool>(
              selector: (state) => state.isSaving,
              builder: (context, saving) =>
                  PopScope(canPop: !saving, child: view),
            ),
          ),
        ),
      ),
    );
  }
}
