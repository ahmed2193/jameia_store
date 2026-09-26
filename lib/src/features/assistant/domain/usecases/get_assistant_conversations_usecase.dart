import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/assistant_conversations_feed.dart';
import '../repositories/assistant_repository.dart';

class GetAssistantConversationsParams extends Equatable {
  const GetAssistantConversationsParams({this.page = 1, this.limit = pageSize});

  /// The history screen's page size.
  static const int pageSize = 20;

  /// Backend bound for `limit`.
  static const int maxLimit = 100;

  final int page;
  final int limit;

  @override
  List<Object?> get props => [page, limit];
}

class GetAssistantConversationsUseCase
    implements
        UseCase<AssistantConversationsFeed, GetAssistantConversationsParams> {
  const GetAssistantConversationsUseCase(this._repository);

  final AssistantRepository _repository;

  /// Out-of-range paging is clamped to the backend bounds (page ≥ 1,
  /// limit 1..100) instead of earning a 400.
  @override
  Future<Either<Failure, AssistantConversationsFeed>> call(
    GetAssistantConversationsParams params,
  ) => _repository.getConversations(
    page: params.page < 1 ? 1 : params.page,
    limit: params.limit.clamp(1, GetAssistantConversationsParams.maxLimit),
  );
}
