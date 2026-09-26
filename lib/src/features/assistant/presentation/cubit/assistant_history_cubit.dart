import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/usecases/get_assistant_conversations_usecase.dart';
import 'assistant_history_state.dart';

/// Page-scoped past conversations: paged loading and pull-to-refresh. List
/// arithmetic lives in `AssistantConversationsFeed`; this only sequences
/// calls.
class AssistantHistoryCubit extends Cubit<AssistantHistoryState>
    with SafeCubitMixin<AssistantHistoryState> {
  AssistantHistoryCubit({required this._getConversations})
    : super(const AssistantHistoryState());

  static const int pageSize = GetAssistantConversationsParams.pageSize;
  static const int _firstPage = 1;

  final GetAssistantConversationsUseCase _getConversations;

  /// Bumped by every first-page load: a next page that was in flight when a
  /// newer first page started no longer follows the list, so it is dropped.
  int _generation = 0;

  /// First load (or retry after an error): full-screen skeleton, then page 1.
  Future<void> load() async {
    safeEmit(state.copyWith(status: AssistantHistoryStatus.loading));
    await _loadFirstPage(AssistantHistoryAction.load);
  }

  /// Pull-to-refresh: page 1 again while the current list stays on screen.
  Future<void> refresh() => _loadFirstPage(AssistantHistoryAction.refresh);

  Future<void> _loadFirstPage(AssistantHistoryAction action) async {
    final generation = ++_generation;
    final result = await _getConversations(
      const GetAssistantConversationsParams(page: _firstPage, limit: pageSize),
    );
    if (generation != _generation) return; // superseded by a newer load
    result.fold(
      (failure) => safeEmit(
        state.copyWith(
          // A failed refresh keeps the list; a failed first load has none.
          status: state.isLoaded
              ? AssistantHistoryStatus.loaded
              : AssistantHistoryStatus.error,
          failure: failure,
          failedAction: action,
        ),
      ),
      (feed) => safeEmit(
        state.copyWith(
          status: AssistantHistoryStatus.loaded,
          feed: feed,
          isLoadingMore: false,
          loadMoreFailed: false,
        ),
      ),
    );
  }

  /// Next page; no-op while one is in flight or when the server has no more.
  Future<void> loadMore() async {
    if (!state.isLoaded || !state.feed.hasMore || state.isLoadingMore) return;
    final generation = _generation;
    safeEmit(state.copyWith(isLoadingMore: true, loadMoreFailed: false));
    final result = await _getConversations(
      GetAssistantConversationsParams(
        page: state.feed.page + 1,
        limit: pageSize,
      ),
    );
    if (generation != _generation) {
      // A refresh replaced the list meanwhile: this page no longer follows it.
      safeEmit(state.copyWith(isLoadingMore: false));
      return;
    }
    result.fold(
      (failure) => safeEmit(
        state.copyWith(
          isLoadingMore: false,
          loadMoreFailed: true,
          failure: failure,
          failedAction: AssistantHistoryAction.loadMore,
        ),
      ),
      (next) => safeEmit(
        state.copyWith(isLoadingMore: false, feed: state.feed.merge(next)),
      ),
    );
  }
}
