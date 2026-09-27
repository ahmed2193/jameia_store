import 'package:dartz/dartz.dart';

import '../../../../core/data/repositories/base_repository_mixin.dart';
import '../../../../core/data/repositories/cached_repository_mixin.dart';
import '../../../../core/domain/entities/data_snapshot.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/assistant_action_result.dart';
import '../../domain/entities/assistant_availability.dart';
import '../../domain/entities/assistant_conversations_feed.dart';
import '../../domain/entities/assistant_handoff_ticket.dart';
import '../../domain/entities/assistant_message_entity.dart';
import '../../domain/entities/assistant_stream_event.dart';
import '../../domain/entities/assistant_thread.dart';
import '../../domain/repositories/assistant_repository.dart';
import '../datasources/assistant_history_cache_data_source.dart';
import '../datasources/assistant_remote_data_source.dart';
import '../mappers/assistant_message_mapper.dart';
import '../models/assistant_conversation_model.dart';

class AssistantRepositoryImpl
    with BaseRepositoryMixin, CachedRepositoryMixin
    implements AssistantRepository {
  const AssistantRepositoryImpl(this._remote, {required this._cache});

  final AssistantRemoteDataSource _remote;

  /// The history's first page as last shown (signed-in customer only).
  final AssistantHistoryCacheDataSource _cache;

  static const int _firstPage = 1;

  @override
  Future<Either<Failure, AssistantAvailability>> getAvailability() =>
      execute(() async => (await _remote.getAvailability()).toEntity());

  @override
  Future<Either<Failure, AssistantConversationsFeed>> getConversations({
    required int page,
    required int limit,
  }) => execute(
    () async => (await _remote.getConversations(
      page: page,
      limit: limit,
    )).model.toEntity(),
  );

  @override
  Stream<DataSnapshot<AssistantConversationsFeed>> watchFirstPage({
    required int limit,
    bool forceRefresh = false,
  }) => cachedRead<AssistantConversationsPageModel, AssistantConversationsFeed>(
    cache: _cache.firstPage(limit: limit),
    fetch: () => _remote.getConversations(page: _firstPage, limit: limit),
    toEntity: (model) => model.toEntity(),
    forceRefresh: forceRefresh,
  );

  @override
  Future<Either<Failure, AssistantThread>> getConversation(String id) =>
      execute(() async => (await _remote.getConversation(id)).toEntity());

  /// Transport failures (validation 400, 401, 429 after retries, offline, a
  /// dropped connection) reach the listener as a `Failure` stream error.
  @override
  Stream<AssistantStreamEvent> sendMessage({
    required String message,
    String? conversationId,
  }) => guardStream(
    _remote
        .sendMessage(message: message, conversationId: conversationId)
        .map((model) => model.toEntity()),
  );

  @override
  Future<Either<Failure, AssistantActionResult>> confirmAction(
    String actionId,
  ) => execute(() async => (await _remote.confirmAction(actionId)).toEntity());

  @override
  Future<Either<Failure, AssistantHandoffTicket>> requestHandoff(
    String conversationId,
  ) => execute(
    () async => (await _remote.requestHandoff(conversationId)).toEntity(),
  );

  @override
  Future<Either<Failure, Unit>> rateMessage({
    required String messageId,
    required AssistantFeedback feedback,
  }) => execute(() async {
    await _remote.rateMessage(
      messageId: messageId,
      feedback: AssistantMessageMapper.feedbackWire(feedback),
    );
    return unit;
  });
}
