import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/entities/address_label.dart';
import '../../../../core/domain/entities/geo_point_entity.dart';
import '../../../../core/domain/entities/jameia_address_entity.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/entities/address_draft.dart';
import '../../domain/entities/address_field.dart';
import '../../domain/usecases/add_address_usecase.dart';
import '../../domain/usecases/update_address_usecase.dart';
import 'address_edit_state.dart';

/// Create / edit address form (page-scoped, `registerFactoryParam`): holds
/// the draft and saves it — `POST /v1/account/addresses` for a new address,
/// `PATCH …/:addressId` with the changed fields for an existing one. The page
/// hands the saved address to the app-global `AddressBookCubit`.
class AddressEditCubit extends Cubit<AddressEditState>
    with SafeCubitMixin<AddressEditState> {
  AddressEditCubit({
    required this._addAddress,
    required this._updateAddress,
    JameiaAddressEntity? original,
    bool isFirstAddress = false,
  }) : super(
         AddressEditState(
           original: original,
           // A customer's first address becomes the default one.
           draft: original == null
               ? AddressDraft(isDefault: isFirstAddress)
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

  /// The customer confirmed the pin; the reverse-geocoded parts pre-fill the
  /// form (an empty part never wipes what was typed).
  void pinConfirmed(
    GeoPointEntity location, {
    String city = '',
    String block = '',
    String street = '',
    String building = '',
    String apartment = '',
  }) => _edit(
    state.draft.pinnedAt(
      location,
      city: city,
      block: block,
      street: street,
      building: building,
      apartment: apartment,
    ),
  );

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

  void _finish(Either<Failure, JameiaAddressEntity> result) => result.fold(
    (failure) => safeEmit(
      state.copyWith(status: AddressEditStatus.editing, failure: failure),
    ),
    (address) => safeEmit(
      state.copyWith(status: AddressEditStatus.saved, saved: address),
    ),
  );
}
