import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/data/keeta_repository.dart';
import '../../../../core/data/models/models.dart';

/// State for the saved-address list / picker. Sealed so the screen `switch`es
/// exhaustively (loading / error / loaded).
sealed class AddressListState extends Equatable {
  const AddressListState();
  @override
  List<Object?> get props => [];
}

class AddressListLoading extends AddressListState {
  const AddressListLoading();
}

class AddressListError extends AddressListState {
  const AddressListError();
}

class AddressListLoaded extends AddressListState {
  final List<KeetaAddress> addresses;
  const AddressListLoaded(this.addresses);

  @override
  List<Object?> get props => [addresses];
}

/// Serves the saved-address list from the dummy [KeetaRepository]. Default
/// address is hoisted to the top to mirror KeeTa's ordering.
class AddressListCubit extends Cubit<AddressListState> {
  AddressListCubit(this._repo) : super(const AddressListLoading());

  final KeetaRepository _repo;

  void load() {
    try {
      final sorted = [..._repo.addresses]
        ..sort((a, b) => (b.isDefault ? 1 : 0).compareTo(a.isDefault ? 1 : 0));
      emit(AddressListLoaded(sorted));
    } catch (_) {
      emit(const AddressListError());
    }
  }
}
