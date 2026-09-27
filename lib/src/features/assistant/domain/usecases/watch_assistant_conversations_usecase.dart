import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/data_snapshot.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/assistant_conversations_feed.dart';
import '../repositories/assistant_repository.dart';
import 'get_assistant_conversations_usecase.dart';

class WatchAssistantConversationsParams extends Equatable {
  const WatchAssistantConversationsParams({
    this.limit = GetAssistantConversationsParams.pageSize,
    this.forceRefresh = false,
  });

  final int limit;

  /// Pull to refresh / reconnect: skip the saved copy.
  final bool forceRefresh;

  @override
  List<Object?> get props => [limit, forceRefresh];
}

/// The history's first page: the signed-in customer's saved copy first,
/// then the server's; failures on the error channel. Later pages are
/// [GetAssistantConversationsUseCase]'s — never kept. [limit] is clamped to
/// the backend bounds (1..100) like the paged read.
class WatchAssistantConversationsUseCase
    implements
        StreamUseCase<
          DataSnapshot<AssistantConversationsFeed>,
          WatchAssistantConversationsParams
        > {
  const WatchAssistantConversationsUseCase(this._repository);

  final AssistantRepository _repository;

  @override
  Stream<DataSnapshot<AssistantConversationsFeed>> call(
    WatchAssistantConversationsParams params,
  ) => _repository.watchFirstPage(
    limit: params.limit.clamp(1, GetAssistantConversationsParams.maxLimit),
    forceRefresh: params.forceRefresh,
  );
}
