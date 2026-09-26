import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/core/usecase/usecase.dart';
import 'package:jameia_mart/src/features/assistant/domain/entities/assistant_action_result.dart';
import 'package:jameia_mart/src/features/assistant/domain/entities/assistant_availability.dart';
import 'package:jameia_mart/src/features/assistant/domain/entities/assistant_conversations_feed.dart';
import 'package:jameia_mart/src/features/assistant/domain/entities/assistant_handoff_ticket.dart';
import 'package:jameia_mart/src/features/assistant/domain/entities/assistant_message_entity.dart';
import 'package:jameia_mart/src/features/assistant/domain/entities/assistant_prompt.dart';
import 'package:jameia_mart/src/features/assistant/domain/entities/assistant_stream_event.dart';
import 'package:jameia_mart/src/features/assistant/domain/entities/assistant_thread.dart';
import 'package:jameia_mart/src/features/assistant/domain/repositories/assistant_repository.dart';
import 'package:jameia_mart/src/features/assistant/domain/usecases/confirm_assistant_action_usecase.dart';
import 'package:jameia_mart/src/features/assistant/domain/usecases/get_assistant_availability_usecase.dart';
import 'package:jameia_mart/src/features/assistant/domain/usecases/get_assistant_conversation_usecase.dart';
import 'package:jameia_mart/src/features/assistant/domain/usecases/get_assistant_conversations_usecase.dart';
import 'package:jameia_mart/src/features/assistant/domain/usecases/rate_assistant_message_usecase.dart';
import 'package:jameia_mart/src/features/assistant/domain/usecases/request_assistant_handoff_usecase.dart';
import 'package:jameia_mart/src/features/assistant/domain/usecases/send_assistant_message_usecase.dart';

/// Records every call; answers with the scripted value.
class _RecordingRepository implements AssistantRepository {
  final List<String> calls = [];
  Failure? failure;

  Either<Failure, T> _answer<T>(T value) =>
      failure == null ? Right(value) : Left(failure!);

  @override
  Future<Either<Failure, AssistantAvailability>> getAvailability() async {
    calls.add('availability');
    return _answer(const AssistantAvailability(enabled: true));
  }

  @override
  Future<Either<Failure, AssistantConversationsFeed>> getConversations({
    required int page,
    required int limit,
  }) async {
    calls.add('list:$page:$limit');
    return _answer(AssistantConversationsFeed.empty);
  }

  @override
  Future<Either<Failure, AssistantThread>> getConversation(String id) async {
    calls.add('get:$id');
    return _answer(AssistantThread.empty);
  }

  @override
  Stream<AssistantStreamEvent> sendMessage({
    required String message,
    String? conversationId,
  }) {
    calls.add('send:$message:$conversationId');
    return Stream.value(const AssistantStreamStarted(conversationId: 'c1'));
  }

  @override
  Future<Either<Failure, AssistantActionResult>> confirmAction(
    String actionId,
  ) async {
    calls.add('confirm:$actionId');
    return _answer(const AssistantActionResult(message: 'Added'));
  }

  @override
  Future<Either<Failure, AssistantHandoffTicket>> requestHandoff(
    String conversationId,
  ) async {
    calls.add('handoff:$conversationId');
    return _answer(const AssistantHandoffTicket(ticketId: 't1'));
  }

  @override
  Future<Either<Failure, Unit>> rateMessage({
    required String messageId,
    required AssistantFeedback feedback,
  }) async {
    calls.add('rate:$messageId:${feedback.name}');
    return _answer(unit);
  }
}

void main() {
  late _RecordingRepository repository;

  setUp(() => repository = _RecordingRepository());

  test('availability passes through', () async {
    final result = await GetAssistantAvailabilityUseCase(repository)
        .call(const NoParams());
    expect(
      result,
      const Right<Failure, AssistantAvailability>(
        AssistantAvailability(enabled: true),
      ),
    );
    repository.failure = const NetworkFailure();
    expect(
      await GetAssistantAvailabilityUseCase(repository).call(const NoParams()),
      const Left<Failure, AssistantAvailability>(NetworkFailure()),
    );
  });

  test('conversations: page 20 by default, paging clamped to the API '
      'bounds', () async {
    final useCase = GetAssistantConversationsUseCase(repository);
    await useCase(const GetAssistantConversationsParams());
    await useCase(const GetAssistantConversationsParams(page: 0, limit: 500));
    await useCase(const GetAssistantConversationsParams(page: 3, limit: 0));
    expect(repository.calls, ['list:1:20', 'list:1:100', 'list:3:1']);
  });

  test('one conversation by id', () async {
    await GetAssistantConversationUseCase(repository)(
      const GetAssistantConversationParams('c7'),
    );
    expect(repository.calls, ['get:c7']);
  });

  test(
    'send hands the TRIMMED prompt and the thread id to the repository',
    () async {
      final events = await SendAssistantMessageUseCase(repository)(
        SendAssistantMessageParams(
          prompt: AssistantPrompt.validate('  milk  ')!,
          conversationId: 'c1',
        ),
      ).toList();
      expect(repository.calls, ['send:milk:c1']);
      expect(events.single, const AssistantStreamStarted(conversationId: 'c1'));
    },
  );

  test(
    'confirm / handoff / rate pass their ids through, Left untouched',
    () async {
      await ConfirmAssistantActionUseCase(repository)(
        const ConfirmAssistantActionParams('act-1'),
      );
      await RequestAssistantHandoffUseCase(repository)(
        const RequestAssistantHandoffParams('c1'),
      );
      await RateAssistantMessageUseCase(repository)(
        const RateAssistantMessageParams(
          messageId: 'm1',
          feedback: AssistantFeedback.none,
        ),
      );
      expect(repository.calls, ['confirm:act-1', 'handoff:c1', 'rate:m1:none']);

      repository.failure = const NotFoundFailure('Action not found');
      expect(
        await ConfirmAssistantActionUseCase(repository)(
          const ConfirmAssistantActionParams('act-1'),
        ),
        const Left<Failure, AssistantActionResult>(
          NotFoundFailure('Action not found'),
        ),
      );
    },
  );
}
