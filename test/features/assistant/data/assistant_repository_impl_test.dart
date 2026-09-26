import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/error/exceptions.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/features/assistant/data/datasources/assistant_remote_data_source.dart';
import 'package:jameia_mart/src/features/assistant/data/models/assistant_conversation_model.dart';
import 'package:jameia_mart/src/features/assistant/data/models/assistant_reply_models.dart';
import 'package:jameia_mart/src/features/assistant/data/models/assistant_stream_event_model.dart';
import 'package:jameia_mart/src/features/assistant/data/repositories/assistant_repository_impl.dart';
import 'package:jameia_mart/src/features/assistant/domain/entities/assistant_message_entity.dart';
import 'package:jameia_mart/src/features/assistant/domain/entities/assistant_stream_event.dart';

import '../assistant_fixtures.dart';

class _FakeRemote implements AssistantRemoteDataSource {
  Object? error;
  Stream<AssistantStreamEventModel> stream = const Stream.empty();
  final List<String> calls = [];

  Future<T> _answer<T>(T value) async {
    if (error != null) throw error!;
    return value;
  }

  @override
  Future<AssistantAvailabilityModel> getAvailability() =>
      _answer(const AssistantAvailabilityModel(enabled: true));

  @override
  Future<AssistantConversationsPageModel> getConversations({
    required int page,
    required int limit,
  }) => _answer(
    AssistantConversationsPageModel.fromJson(
      AssistantFixtures.liveResults('conversations_list_en.json'),
    ),
  );

  @override
  Future<AssistantConversationDetailModel> getConversation(String id) =>
      _answer(
        AssistantConversationDetailModel.fromJson(
          AssistantFixtures.liveResults('conversation_detail_en.json'),
        ),
      );

  @override
  Stream<AssistantStreamEventModel> sendMessage({
    required String message,
    String? conversationId,
  }) => stream;

  @override
  Future<AssistantActionResultModel> confirmAction(String actionId) =>
      _answer(const AssistantActionResultModel(message: 'ok'));

  @override
  Future<AssistantHandoffTicketModel> requestHandoff(String conversationId) =>
      _answer(const AssistantHandoffTicketModel(ticketId: 't1'));

  @override
  Future<void> rateMessage({required String messageId, String? feedback}) {
    calls.add('rate:$messageId:$feedback');
    return _answer(null);
  }
}

void main() {
  late _FakeRemote remote;
  late AssistantRepositoryImpl repository;

  setUp(() {
    remote = _FakeRemote();
    repository = AssistantRepositoryImpl(remote);
  });

  test('DTO → entity on success', () async {
    expect(
      (await repository.getAvailability())
          .getOrElse(() => throw 'x')
          .isAvailable,
      isTrue,
    );
    final feed = (await repository.getConversations(
      page: 1,
      limit: 20,
    )).getOrElse(() => throw 'x');
    expect(feed.items, hasLength(3));
    final thread = (await repository.getConversation('c'))
        .getOrElse(() => throw 'x');
    expect(thread.entries, hasLength(4));
  });

  test('feedback none goes out as null', () async {
    expect(
      await repository.rateMessage(
        messageId: 'm1',
        feedback: AssistantFeedback.none,
      ),
      const Right<Failure, Unit>(unit),
    );
    expect(remote.calls, ['rate:m1:null']);
  });

  group('exception → Failure', () {
    final cases = <Object, Failure>{
      const UnauthorizedException('Sign in', code: 'AUTHENTICATION_REQUIRED'):
          const UnauthorizedFailure('Sign in'),
      const NotFoundException('Action not found', code: 'RESOURCE_NOT_FOUND'):
          const NotFoundFailure('Action not found', code: 'RESOURCE_NOT_FOUND'),
      const RateLimitedException('Slow down'): const RateLimitedFailure(
        'Slow down',
      ),
      const NoInternetConnectionException(): const NetworkFailure(
        'No internet connection',
      ),
      const RequestTimeoutException(): const TimeoutFailure(
        'Request timed out',
      ),
      const ParsingException('bad'): const ParsingFailure('bad'),
      const BadRequestException(
        'Validation failed',
        code: 'VALIDATION_ERROR',
      ): const ServerFailure(
        'Validation failed',
        statusCode: 400,
        code: 'VALIDATION_ERROR',
      ),
    };

    for (final entry in cases.entries) {
      test('${entry.key.runtimeType}', () async {
        remote.error = entry.key;
        expect(
          await repository.confirmAction('a'),
          Left<Failure, Object>(entry.value),
        );
      });
    }
  });

  test('stream errors reach the listener as Failures', () async {
    remote.stream = Stream.error(const NoInternetConnectionException());
    await expectLater(
      repository.sendMessage(message: 'hi'),
      emitsError(isA<NetworkFailure>()),
    );
  });

  test('stream frames map to domain events', () async {
    remote.stream = Stream.fromIterable(const [
      AssistantStreamStartedModel('c1'),
      AssistantStreamTextDeltaModel('Hi'),
      AssistantStreamFailedModel(code: 'INTERNAL_ERROR', message: 'x'),
    ]);
    expect(await repository.sendMessage(message: 'hi').toList(), const [
      AssistantStreamStarted(conversationId: 'c1'),
      AssistantStreamTextDelta(delta: 'Hi'),
      AssistantStreamFailed(code: 'INTERNAL_ERROR', message: 'x'),
    ]);
  });
}
