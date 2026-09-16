import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/entities/punctual_landing.dart';
import '../../domain/repositories/marketing_repository.dart';

enum PunctualStatus { initial, loading, loaded, error }

/// State for the on-time guarantee landing (`mach_pro_sailor_c_punctual`).
///
/// Loading → loaded/error, matching the live page's `landing` fetch. The
/// currently-open FAQ index is carried on the state so the accordion can toggle
/// without re-fetching, loaded through the [MarketingRepository].
class PunctualState extends Equatable {
  const PunctualState({
    this.status = PunctualStatus.initial,
    this.landing,
    this.expandedFaq = -1,
    this.error,
  });

  final PunctualStatus status;

  /// Resolved landing payload; null until [PunctualStatus.loaded].
  final PunctualLanding? landing;

  /// Index of the currently-open FAQ row, or `-1` when all collapsed.
  final int expandedFaq;
  final String? error;

  PunctualState copyWith({
    PunctualStatus? status,
    PunctualLanding? landing,
    int? expandedFaq,
    String? error,
  }) =>
      PunctualState(
        status: status ?? this.status,
        landing: landing ?? this.landing,
        expandedFaq: expandedFaq ?? this.expandedFaq,
        error: error ?? this.error,
      );

  @override
  List<Object?> get props => [status, landing, expandedFaq, error];
}

/// Page-scoped cubit for the on-time guarantee landing.
///
/// Resolved via `sl<PunctualCubit>()`; loads the promise/steps/FAQ content on
/// construction directly from the [MarketingRepository] (dummy stand-in for the
/// live `v1/order/late/compensation/landing` call), so the screen renders a
/// loading skeleton then data/error with retry.
class PunctualCubit extends Cubit<PunctualState>
    with SafeCubitMixin<PunctualState> {
  PunctualCubit(this._repository) : super(const PunctualState()) {
    load();
  }

  final MarketingRepository _repository;

  /// Fetch the landing payload. Emits loading → loaded/error; safe to call again
  /// from the error-state retry button.
  Future<void> load() async {
    safeEmit(state.copyWith(status: PunctualStatus.loading));
    final result = await _repository.getPunctualLanding();
    result.fold(
      (failure) => safeEmit(state.copyWith(
        status: PunctualStatus.error,
        error: failure.message,
      )),
      (landing) => safeEmit(state.copyWith(
        status: PunctualStatus.loaded,
        landing: landing,
      )),
    );
  }

  /// Toggle a FAQ row open/closed (single-open accordion).
  void toggleFaq(int index) {
    if (state.status != PunctualStatus.loaded) return;
    safeEmit(state.copyWith(
      expandedFaq: state.expandedFaq == index ? -1 : index,
    ));
  }
}
