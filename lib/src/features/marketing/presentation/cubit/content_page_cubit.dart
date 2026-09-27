import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/entities/data_freshness.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../../../core/utils/performance/snapshot_loader_mixin.dart';
import '../../domain/entities/content_page_entity.dart';
import '../../domain/usecases/watch_content_page_usecase.dart';
import 'content_page_state.dart';

/// One CMS page of the backend (`GET /v1/pages/:slug`): about, contact, FAQ,
/// privacy, terms — the device copy first (offline too), then the server's.
/// A reload that fails keeps the page and marks it stale.
class ContentPageCubit extends Cubit<ContentPageState>
    with
        SafeCubitMixin<ContentPageState>,
        SnapshotLoaderMixin<ContentPageState> {
  ContentPageCubit(this._watchPage, {required this._kind})
    : super(const ContentPageState());

  final WatchContentPageUseCase _watchPage;
  final ContentPageKind _kind;

  /// First load, retry, language switch; the page on screen stays meanwhile.
  Future<void> load() {
    if (!state.isLoaded) {
      safeEmit(state.copyWith(status: ContentPageStatus.loading));
    }
    return _read(forceRefresh: false);
  }

  /// The connection came back: one silent refresh when the page is a saved
  /// copy or failed.
  Future<void> onReconnected() => refreshOnReconnect(
    needed: state.freshness.isStale || state.status == ContentPageStatus.error,
    refresh: () => _read(forceRefresh: true),
  );

  Future<void> _read({required bool forceRefresh}) =>
      followSnapshots<ContentPageEntity>(
        _watchPage(WatchContentPageParams(_kind, forceRefresh: forceRefresh)),
        onSnapshot: (snapshot) => safeEmit(
          state.copyWith(
            status: ContentPageStatus.loaded,
            page: snapshot.data,
            freshness: DataFreshness.of(snapshot),
          ),
        ),
        onFailure: (failure) => safeEmit(
          state.copyWith(
            status: state.isLoaded
                ? ContentPageStatus.loaded
                : ContentPageStatus.error,
            freshness: state.freshness.failed(),
            failure: failure,
          ),
        ),
      );
}
