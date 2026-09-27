import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../../../core/utils/performance/screen_loader_mixin.dart';
import '../../../../core/utils/performance/snapshot_loader_mixin.dart';
import '../../domain/entities/assistant_conversations_feed.dart';
import '../../domain/usecases/get_assistant_conversations_usecase.dart';
import '../../domain/usecases/watch_assistant_conversations_usecase.dart';
import 'assistant_history_state.dart';

/// Page-scoped past conversations: the first page paints from the device
/// copy (offline too), then the server's; the next pages and
/// pull-to-refresh ask the server. List arithmetic lives in
/// `AssistantConversationsFeed`, the screen flow in the loader mixins; this
/// only maps the pages.
class AssistantHistoryCubit extends Cubit<AssistantHistoryState>
    with
        SafeCubitMixin<AssistantHistoryState>,
        SnapshotLoaderMixin<AssistantHistoryState>,
        ScreenLoaderMixin<AssistantHistoryState>,
        PagedScreenMixin<AssistantHistoryState> {
  AssistantHistoryCubit({
    required this._watchFirstPage,
    required this._getConversations,
  }) : super(const AssistantHistoryState());

  static const int pageSize = GetAssistantConversationsParams.pageSize;

  final WatchAssistantConversationsUseCase _watchFirstPage;
  final GetAssistantConversationsUseCase _getConversations;

  /// First load (or retry after an error): the skeleton only while nothing
  /// is on screen, then page 1 — the saved copy first.
  Future<void> load() {
    showLoading();
    return _readFirstPage(forceRefresh: false);
  }

  /// Pull-to-refresh: the server's page 1 while the current list stays on
  /// screen.
  @override
  Future<void> refresh() => _readFirstPage(forceRefresh: true);

  Future<void> _readFirstPage({required bool forceRefresh}) =>
      readScreen<AssistantConversationsFeed>(
        _watchFirstPage(
          WatchAssistantConversationsParams(
            limit: pageSize,
            forceRefresh: forceRefresh,
          ),
        ),
        show: (state, snapshot) => state.copyWith(feed: snapshot.data),
      );

  /// Next page; a no-op while one is in flight, when the server has no more,
  /// and after a failed page unless [retry].
  @override
  Future<void> loadMore({bool retry = false}) =>
      loadNextPage<AssistantConversationsFeed>(
        hasMore: state.feed.hasMore,
        retry: retry,
        fetch: () => _getConversations(
          GetAssistantConversationsParams(
            page: state.feed.page + 1,
            limit: pageSize,
          ),
        ),
        merge: (state, next) => state.copyWith(feed: state.feed.merge(next)),
      );
}
