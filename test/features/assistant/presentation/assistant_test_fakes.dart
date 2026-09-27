import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:hero_mart/src/core/domain/entities/data_snapshot.dart';
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/features/assistant/domain/entities/assistant_action_result.dart';
import 'package:hero_mart/src/features/assistant/domain/entities/assistant_availability.dart';
import 'package:hero_mart/src/features/assistant/domain/entities/assistant_block.dart';
import 'package:hero_mart/src/features/assistant/domain/entities/assistant_conversation_entity.dart';
import 'package:hero_mart/src/features/assistant/domain/entities/assistant_conversations_feed.dart';
import 'package:hero_mart/src/features/assistant/domain/entities/assistant_handoff_ticket.dart';
import 'package:hero_mart/src/features/assistant/domain/entities/assistant_message_entity.dart';
import 'package:hero_mart/src/features/assistant/domain/entities/assistant_rich_text.dart';
import 'package:hero_mart/src/features/assistant/domain/entities/assistant_stream_event.dart';
import 'package:hero_mart/src/features/assistant/domain/entities/assistant_thread.dart';
import 'package:hero_mart/src/features/assistant/domain/repositories/assistant_repository.dart';
import 'package:hero_mart/src/features/assistant/domain/usecases/confirm_assistant_action_usecase.dart';
import 'package:hero_mart/src/features/assistant/domain/usecases/get_assistant_availability_usecase.dart';
import 'package:hero_mart/src/features/assistant/domain/usecases/get_assistant_conversation_usecase.dart';
import 'package:hero_mart/src/features/assistant/domain/usecases/get_assistant_conversations_usecase.dart';
import 'package:hero_mart/src/features/assistant/domain/usecases/rate_assistant_message_usecase.dart';
import 'package:hero_mart/src/features/assistant/domain/usecases/request_assistant_handoff_usecase.dart';
import 'package:hero_mart/src/features/assistant/domain/usecases/send_assistant_message_usecase.dart';
import 'package:hero_mart/src/features/assistant/domain/usecases/watch_assistant_conversations_usecase.dart';
import 'package:hero_mart/src/features/assistant/presentation/cubit/assistant_availability_cubit.dart';
import 'package:hero_mart/src/features/assistant/presentation/cubit/assistant_chat_cubit.dart';
import 'package:hero_mart/src/features/assistant/presentation/cubit/assistant_history_cubit.dart';

import '../../../core/data/snapshot_test_fakes.dart';

/// One call the test answers when it wants to (a gated fake).
class Gate<T> {
  Gate(this.args);

  final Object? args;
  final Completer<T> _completer = Completer<T>();

  Future<T> get future => _completer.future;
  bool get isOpen => _completer.isCompleted;
  void open(T value) => _completer.complete(value);
}

/// An `AssistantRepository` whose every call waits for the test: read the
/// pending calls, then answer them (`gate.open(...)`) or push stream frames.
class FakeAssistantRepository implements AssistantRepository {
  final List<Gate<Either<Failure, AssistantAvailability>>> availability = [];
  final List<Gate<Either<Failure, AssistantConversationsFeed>>> lists = [];
  final List<Gate<Either<Failure, AssistantThread>>> threads = [];
  final List<Gate<Either<Failure, AssistantActionResult>>> confirms = [];
  final List<Gate<Either<Failure, AssistantHandoffTicket>>> handoffs = [];
  final List<Gate<Either<Failure, Unit>>> ratings = [];
  final List<FakeTurnStream> sends = [];

  /// The history's first page as saved on the device (none by default):
  /// [watchFirstPage] shows it first, then waits on [lists] like
  /// [getConversations].
  AssistantConversationsFeed? savedFirstPage;

  /// The `forceRefresh` of every first-page read, in order.
  final List<bool> firstPageForced = [];

  FakeTurnStream get lastSend => sends.last;

  @override
  Future<Either<Failure, AssistantAvailability>> getAvailability() =>
      _gate(availability, null);

  @override
  Future<Either<Failure, AssistantConversationsFeed>> getConversations({
    required int page,
    required int limit,
  }) => _gate(lists, (page: page, limit: limit));

  @override
  Stream<DataSnapshot<AssistantConversationsFeed>> watchFirstPage({
    required int limit,
    bool forceRefresh = false,
  }) {
    firstPageForced.add(forceRefresh);
    return networkRead(
      _gate(lists, (page: 1, limit: limit)),
      saved: forceRefresh ? null : savedFirstPage,
    );
  }

  @override
  Future<Either<Failure, AssistantThread>> getConversation(String id) =>
      _gate(threads, id);

  @override
  Stream<AssistantStreamEvent> sendMessage({
    required String message,
    String? conversationId,
  }) {
    final turn = FakeTurnStream(message, conversationId);
    sends.add(turn);
    return turn.controller.stream;
  }

  @override
  Future<Either<Failure, AssistantActionResult>> confirmAction(
    String actionId,
  ) => _gate(confirms, actionId);

  @override
  Future<Either<Failure, AssistantHandoffTicket>> requestHandoff(
    String conversationId,
  ) => _gate(handoffs, conversationId);

  @override
  Future<Either<Failure, Unit>> rateMessage({
    required String messageId,
    required AssistantFeedback feedback,
  }) => _gate(ratings, (messageId: messageId, feedback: feedback));

  static Future<T> _gate<T>(List<Gate<T>> calls, Object? args) {
    final gate = Gate<T>(args);
    calls.add(gate);
    return gate.future;
  }
}

/// The server side of one `POST /v1/assistant/messages`.
class FakeTurnStream {
  FakeTurnStream(this.message, this.conversationId) {
    controller = StreamController<AssistantStreamEvent>(
      onCancel: () => cancelled = true,
    );
  }

  final String message;
  final String? conversationId;
  late final StreamController<AssistantStreamEvent> controller;
  bool cancelled = false;

  void add(AssistantStreamEvent event) => controller.add(event);
  void addAll(Iterable<AssistantStreamEvent> events) => events.forEach(add);
  void fail(Failure failure) => controller.addError(failure);
  Future<void> close() => controller.close();

  /// The frames every accepted turn starts with.
  void accept({String conversationId = 'c1', String userId = 'u1'}) => addAll([
    AssistantStreamStarted(conversationId: conversationId),
    AssistantStreamUserMessage(
      conversationId: conversationId,
      message: userMessage(userId, message, conversationId: conversationId),
    ),
  ]);

  void complete(AssistantMessageEntity reply, {String conversationId = 'c1'}) =>
      add(
        AssistantStreamCompleted(
          conversationId: conversationId,
          message: reply,
        ),
      );
}

AssistantMessageEntity userMessage(
  String id,
  String text, {
  String conversationId = 'c1',
}) => AssistantMessageEntity(
  id: id,
  role: AssistantRole.user,
  conversationId: conversationId,
  content: text,
);

AssistantMessageEntity assistantReply(
  String id,
  String text, {
  List<AssistantBlock> blocks = const [],
  String conversationId = 'c1',
  AssistantFeedback feedback = AssistantFeedback.none,
}) => AssistantMessageEntity(
  id: id,
  role: AssistantRole.assistant,
  conversationId: conversationId,
  content: text,
  richText: AssistantRichText.parse(text),
  blocks: [AssistantTextBlock.parse(text), ...blocks],
  feedback: feedback,
);

AssistantThread threadOf(
  List<AssistantMessageEntity> messages, {
  String id = 'c1',
  AssistantConversationStatus status = AssistantConversationStatus.active,
}) => AssistantThread.loaded(
  conversation: AssistantConversationEntity(id: id, status: status),
  messages: messages,
);

AssistantConversationsFeed feedOf(
  List<AssistantConversationEntity> items, {
  int page = 1,
  bool hasMore = false,
}) => AssistantConversationsFeed(
  items: items,
  page: page,
  hasMore: hasMore,
  total: items.length,
);

const AssistantCartActionBlock pendingProposal = AssistantCartActionBlock(
  actionId: 'act-1',
  items: [AssistantCartActionItem(productId: 'p1', quantity: 2)],
  estimatedTotalFils: 1798,
);

AssistantChatCubit chatCubit(FakeAssistantRepository repository) =>
    AssistantChatCubit(
      getConversations: GetAssistantConversationsUseCase(repository),
      getConversation: GetAssistantConversationUseCase(repository),
      send: SendAssistantMessageUseCase(repository),
      confirm: ConfirmAssistantActionUseCase(repository),
      rate: RateAssistantMessageUseCase(repository),
      handOff: RequestAssistantHandoffUseCase(repository),
    );

AssistantHistoryCubit historyCubit(FakeAssistantRepository repository) =>
    AssistantHistoryCubit(
      watchFirstPage: WatchAssistantConversationsUseCase(repository),
      getConversations: GetAssistantConversationsUseCase(repository),
    );

AssistantAvailabilityCubit availabilityCubit(
  FakeAssistantRepository repository, {
  List<Duration> retryDelays = AssistantAvailabilityCubit.defaultRetryDelays,
}) => AssistantAvailabilityCubit(
  getAvailability: GetAssistantAvailabilityUseCase(repository),
  retryDelays: retryDelays,
);

/// Lets pending microtasks (stream frames, completed futures) run.
Future<void> settle() => Future<void>.delayed(Duration.zero);
