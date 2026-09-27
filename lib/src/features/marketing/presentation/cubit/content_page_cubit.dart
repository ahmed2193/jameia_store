import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../../../core/utils/performance/screen_loader_mixin.dart';
import '../../../../core/utils/performance/snapshot_loader_mixin.dart';
import '../../domain/entities/content_page_entity.dart';
import '../../domain/usecases/watch_content_page_usecase.dart';
import 'content_page_state.dart';

/// One CMS page of the backend (`GET /v1/pages/:slug`): about, contact, FAQ,
/// privacy, terms — the device copy first (offline too), then the server's.
/// A reload that fails keeps the page and marks it stale; the screen flow
/// is the loader mixins'.
class ContentPageCubit extends Cubit<ContentPageState>
    with
        SafeCubitMixin<ContentPageState>,
        SnapshotLoaderMixin<ContentPageState>,
        ScreenLoaderMixin<ContentPageState> {
  ContentPageCubit(this._watchPage, {required this._kind})
    : super(const ContentPageState());

  final WatchContentPageUseCase _watchPage;
  final ContentPageKind _kind;

  /// First load, retry, language switch; the page on screen stays meanwhile.
  Future<void> load() {
    showLoading();
    return _read(forceRefresh: false);
  }

  /// The server's page (the reconnect refresh of a saved or failed one).
  @override
  Future<void> refresh() => _read(forceRefresh: true);

  Future<void> _read({required bool forceRefresh}) =>
      readScreen<ContentPageEntity>(
        _watchPage(WatchContentPageParams(_kind, forceRefresh: forceRefresh)),
        show: (state, snapshot) => state.copyWith(page: snapshot.data),
      );
}
