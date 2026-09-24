import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/entities/service_region_item_entity.dart';
import '../../domain/usecases/get_service_regions_usecase.dart';
import '../../domain/usecases/switch_region_usecase.dart';

/// Re-export the framework-free region row type so the screen imports it via the
/// cubit (mirrors the old `ServiceRegionItem` re-export).
export '../../domain/entities/service_region_item_entity.dart'
    show ServiceRegionItemEntity;

enum ChooseLocationStatus { initial, loading, loaded, empty, error }

/// State for the region / serviceable-COUNTRY picker (`choose_location_page`).
/// Plain white single-select list — NO map. Default selection = the persisted
/// active region (NOT first); [canConfirm] gates the Confirm CTA. Holds
/// framework-free [ServiceRegionItemEntity]s; the screen reverse-maps to the
/// core `ServiceRegionItem` only at the confirm-pop boundary.
class ChooseLocationState extends Equatable {
  const ChooseLocationState({
    this.status = ChooseLocationStatus.initial,
    this.regions = const [],
    this.selectedId,
    this.activeRegion = '',
    this.error,
  });

  final ChooseLocationStatus status;

  /// All serviceable regions (the hard-coded anchors).
  final List<ServiceRegionItemEntity> regions;

  /// Selected region's two-letter code, or null when nothing is chosen.
  final String? selectedId;

  /// The repository's active region code — seeds the default selection and
  /// drives the region-switch detection.
  final String activeRegion;

  final String? error;

  /// True once a region is picked — gates the Confirm CTA.
  bool get canConfirm => selectedId != null;

  ChooseLocationState copyWith({
    ChooseLocationStatus? status,
    List<ServiceRegionItemEntity>? regions,
    String? selectedId,
    String? activeRegion,
    String? error,
  }) => ChooseLocationState(
    status: status ?? this.status,
    regions: regions ?? this.regions,
    selectedId: selectedId ?? this.selectedId,
    activeRegion: activeRegion ?? this.activeRegion,
    error: error ?? this.error,
  );

  @override
  List<Object?> get props => [status, regions, selectedId, activeRegion, error];
}

/// Drives the serviceable-region picker. Loads the anchors + active region on
/// construction with single-select + region-switch detection against the repo's
/// active region. Resolved via `sl<ChooseLocationCubit>()`.
class ChooseLocationCubit extends Cubit<ChooseLocationState>
    with SafeCubitMixin<ChooseLocationState> {
  ChooseLocationCubit(this._getServiceRegions, this._switchRegion)
    : super(const ChooseLocationState()) {
    load();
  }

  final GetServiceRegionsUseCase _getServiceRegions;
  final SwitchRegionUseCase _switchRegion;

  /// Load the region anchors + active region. Default selection = the active
  /// region (`lastSelectedRegion`), NOT first.
  Future<void> load() async {
    safeEmit(state.copyWith(status: ChooseLocationStatus.loading));
    final result = await _getServiceRegions(const NoParams());
    result.fold(
      (failure) => safeEmit(
        state.copyWith(
          status: ChooseLocationStatus.error,
          error: failure.message,
        ),
      ),
      (opts) {
        final active = opts.activeRegion;
        final hasActive = opts.regions.any(
          (r) => r.region == active && r.enabled,
        );
        safeEmit(
          state.copyWith(
            status: opts.regions.isEmpty
                ? ChooseLocationStatus.empty
                : ChooseLocationStatus.loaded,
            regions: opts.regions,
            activeRegion: active,
            selectedId: hasActive ? active : null,
          ),
        );
      },
    );
  }

  /// Re-fetch the region list (the Refresh CTA on the error view).
  Future<void> handleRefreshData() => load();

  /// Single-select a region by its two-letter code.
  void select(String id) {
    if (state.status == ChooseLocationStatus.loaded) {
      safeEmit(state.copyWith(selectedId: id));
    }
  }

  /// The currently-selected region, or null.
  ServiceRegionItemEntity? get selected {
    final id = state.selectedId;
    if (id == null) return null;
    for (final r in state.regions) {
      if (r.region == id) return r;
    }
    return null;
  }

  /// True when selecting [id] would switch AWAY from the repo's active region
  /// (drives the region-switch confirm sheet).
  bool isSwitch(String id) => id != state.activeRegion;

  /// Commit a region switch (`switchRegion` + `com.jameia.changed.region`).
  Future<void> switchRegion(String region) async {
    await _switchRegion(SwitchRegionParams(region: region));
  }
}
