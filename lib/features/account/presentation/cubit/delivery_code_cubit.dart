import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/repositories/account_repository.dart';

enum DeliveryCodeStatus { initial, loading, loaded, error }

/// State for `mach_pro_sailor_c_mine_delivery_code` — the saved delivery code,
/// the editor draft, and a one-frame success flag.
class DeliveryCodeState extends Equatable {
  const DeliveryCodeState({
    this.status = DeliveryCodeStatus.initial,
    this.savedCode = '',
    this.draft = '',
    this.saved = false,
    this.error,
  });

  /// Length KeeTa enforces for the delivery code (`code_edit` is a 4-cell field).
  static const int codeLength = 4;

  final DeliveryCodeStatus status;

  /// The persisted delivery code (mirrors `getUserDeliveryCodeDetail`).
  final String savedCode;

  /// The current editor input (0..[codeLength] digits).
  final String draft;

  /// `true` for one frame after a successful save (drives the pass banner).
  final bool saved;
  final String? error;

  bool get isComplete => draft.length == codeLength;

  /// Enable Save only when the 4 digits form a new value.
  bool get canSave => isComplete && draft != savedCode;

  DeliveryCodeState copyWith({
    DeliveryCodeStatus? status,
    String? savedCode,
    String? draft,
    bool? saved,
    String? error,
  }) =>
      DeliveryCodeState(
        status: status ?? this.status,
        savedCode: savedCode ?? this.savedCode,
        draft: draft ?? this.draft,
        saved: saved ?? this.saved,
        error: error,
      );

  @override
  List<Object?> get props => [status, savedCode, draft, saved, error];
}

/// Page-scoped cubit — resolved via `sl<DeliveryCodeCubit>()`; loads the saved
/// code on construction through [AccountRepository]. Save is a demo no-op
/// (the dummy repository is read-only) that updates local state and flips the
/// success flag.
class DeliveryCodeCubit extends Cubit<DeliveryCodeState>
    with SafeCubitMixin<DeliveryCodeState> {
  DeliveryCodeCubit(this._repository) : super(const DeliveryCodeState()) {
    load();
  }

  final AccountRepository _repository;

  Future<void> load() async {
    safeEmit(state.copyWith(status: DeliveryCodeStatus.loading));
    final result = await _repository.getDeliveryCode();
    result.fold(
      (failure) => safeEmit(state.copyWith(
        status: DeliveryCodeStatus.error,
        error: failure.message,
      )),
      (code) => safeEmit(state.copyWith(
        status: DeliveryCodeStatus.loaded,
        savedCode: code,
        draft: code,
      )),
    );
  }

  void edit(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    final clipped = digits.length > DeliveryCodeState.codeLength
        ? digits.substring(0, DeliveryCodeState.codeLength)
        : digits;
    safeEmit(state.copyWith(draft: clipped, saved: false));
  }

  /// Demo-persist the new code (the dummy repository is read-only, so this only
  /// updates local state and flips the success flag).
  void save() {
    if (!state.canSave) return;
    safeEmit(state.copyWith(savedCode: state.draft, saved: true));
  }
}
