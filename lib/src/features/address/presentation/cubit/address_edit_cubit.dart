import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/entities/address_label.dart';
import '../../../../core/domain/entities/hero_address_entity.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/entities/address_draft.dart';
import '../../domain/entities/address_field.dart';
import '../../domain/entities/building_type.dart';
import '../../domain/entities/new_address_seed.dart';
import '../../domain/entities/pinned_place.dart';
import '../../domain/usecases/add_address_usecase.dart';
import '../../domain/usecases/update_address_usecase.dart';
import 'address_edit_state.dart';

/// Create / edit address form (page-scoped, `registerFactoryParam`): holds
/// the draft — a new one starts from a [NewAddressSeed] — and saves it — `POST /v1/account/addresses` for a new address,
/// `PATCH …/:addressId` with the changed fields for an existing one. The page
/// hands the saved address to the app-global `AddressBookCubit`.
class AddressEditCubit extends Cubit<AddressEditState>
    with SafeCubitMixin<AddressEditState> {
  AddressEditCubit({
    required this._addAddress,
    required this._updateAddress,
    HeroAddressEntity? original,
    NewAddressSeed seed = const NewAddressSeed(),
  }) : super(
         AddressEditState(
           original: original,
           draft: original == null
               ? AddressDraft.seeded(seed)
               : AddressDraft.fromAddress(original),
         ),
       );

  final AddAddressUseCase _addAddress;
  final UpdateAddressUseCase _updateAddress;

  void labelChanged(AddressLabel label) =>
      _edit(state.draft.copyWith(label: label));

  void fieldChanged(AddressField field, String value) =>
      _edit(state.draft.withField(field, value));

  void defaultChanged(bool isDefault) =>
      _edit(state.draft.copyWith(isDefault: isDefault));

  void buildingTypeChanged(BuildingType type) =>
      _edit(state.draft.withBuildingType(type));

  /// The customer confirmed the pin at [place]: the address follows it,
  /// what the map read there fills the form (`AddressDraft.pinnedAt`).
  void pinConfirmed(PinnedPlace place) => safeEmit(
    state.copyWith(
      draft: state.draft.pinnedAt(place.location, parts: place.parts),
    ),
  );

  /// The map read the pin the form holds only after Confirm stopped waiting
  /// for it: what it read fills the parts still empty. A read of any other
  /// spot is not this address's.
  void pinReadLate(PinnedPlace place) {
    final draft = state.draft;
    if (!draft.hasPin || place.isBare || place.location != draft.location) {
      return;
    }
    final filled = draft.filledFrom(place.parts);
    if (filled != draft) safeEmit(state.copyWith(draft: filled));
  }

  Future<void> save() async {
    if (state.isSaving || state.status == AddressEditStatus.saved) return;
    if (!state.draft.isValid) {
      safeEmit(state.copyWith(showErrors: true, rejected: true));
      return;
    }
    final original = state.original;
    if (original == null) {
      safeEmit(state.copyWith(status: AddressEditStatus.saving));
      _finish(await _addAddress(AddAddressParams(draft: state.draft)));
      return;
    }
    final update = state.update;
    if (update.isEmpty) {
      // Nothing changed: done without a request.
      safeEmit(
        state.copyWith(status: AddressEditStatus.saved, saved: original),
      );
      return;
    }
    safeEmit(state.copyWith(status: AddressEditStatus.saving));
    _finish(
      await _updateAddress(
        UpdateAddressParams(id: original.id, update: update),
      ),
    );
  }

  void _edit(AddressDraft draft) => safeEmit(state.copyWith(draft: draft));

  void _finish(Either<Failure, HeroAddressEntity> result) => result.fold(
    (failure) => safeEmit(
      state.copyWith(status: AddressEditStatus.editing, failure: failure),
    ),
    (address) => safeEmit(
      state.copyWith(status: AddressEditStatus.saved, saved: address),
    ),
  );
}
