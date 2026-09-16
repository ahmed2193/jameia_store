import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/data/models/models.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/entities/keeta_address_entity.dart';
import '../../domain/repositories/address_repository.dart';

enum AddressListStatus { initial, loading, loaded, empty, error }

/// State for the saved-address list / picker. The default address is hoisted to
/// the top by the repository to mirror KeeTa's ordering. Holds framework-free
/// [KeetaAddressEntity]s; the screen reverse-maps to the core [KeetaAddress]
/// only at the picker-pop / edit-deep-link boundaries.
class AddressListState extends Equatable {
  const AddressListState({
    this.status = AddressListStatus.initial,
    this.addresses = const [],
    this.error,
  });

  final AddressListStatus status;
  final List<KeetaAddressEntity> addresses;
  final String? error;

  AddressListState copyWith({
    AddressListStatus? status,
    List<KeetaAddressEntity>? addresses,
    String? error,
  }) =>
      AddressListState(
        status: status ?? this.status,
        addresses: addresses ?? this.addresses,
        error: error ?? this.error,
      );

  @override
  List<Object?> get props => [status, addresses, error];
}

/// Serves the saved-address list from the persisted [KeetaRepository] address
/// book (through [AddressRepository]). Resolved via `sl<AddressListCubit>()`;
/// loads on construction.
class AddressListCubit extends Cubit<AddressListState>
    with SafeCubitMixin<AddressListState> {
  AddressListCubit(this._repository) : super(const AddressListState()) {
    load();
  }

  final AddressRepository _repository;

  Future<void> load() async {
    safeEmit(state.copyWith(status: AddressListStatus.loading));
    final result = await _repository.getAddresses();
    result.fold(
      (failure) => safeEmit(state.copyWith(
        status: AddressListStatus.error,
        error: failure.message,
      )),
      (addresses) => safeEmit(state.copyWith(
        status: addresses.isEmpty
            ? AddressListStatus.empty
            : AddressListStatus.loaded,
        addresses: addresses,
      )),
    );
  }

  /// Add or update a saved address (the editor already persisted it; this
  /// re-commits + reloads so the row shows immediately). Add vs. update is chosen
  /// by whether the id is already in the list — both persist identically.
  ///
  /// Takes the core [KeetaAddress] (the composed persistence payload popped by
  /// the editor) — a deliberate P2.9 write boundary.
  Future<void> upsert(KeetaAddress a) async {
    final exists = state.addresses.any((e) => e.id == a.id);
    final result =
        exists ? await _repository.updateAddress(a) : await _repository.addAddress(a);
    await result.fold(
      (failure) async => safeEmit(state.copyWith(
        status: AddressListStatus.error,
        error: failure.message,
      )),
      (_) => load(),
    );
  }

  /// Delete a saved address (`DELUSERADDRESS`) then reload the list.
  Future<void> delete(String id) async {
    final result = await _repository.deleteAddress(id);
    await result.fold(
      (failure) async => safeEmit(state.copyWith(
        status: AddressListStatus.error,
        error: failure.message,
      )),
      (_) => load(),
    );
  }
}
