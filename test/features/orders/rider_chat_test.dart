// The chat with the rider: the message rules (trimmed, never empty, never
// a letter), the simulated rider (hello on opening, typing, then an answer
// in both languages; a fresh conversation for a new ride), the wire shape,
// the read marker kept with the conversation, and the cubit's unread count,
// reading and one-at-a-time sending.
import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/error/exceptions.dart';
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/features/orders/data/datasources/demo_rider_chat_data_source.dart';
import 'package:hero_mart/src/features/orders/data/mappers/rider_chat_mapper.dart';
import 'package:hero_mart/src/features/orders/data/models/courier_fix_model.dart';
import 'package:hero_mart/src/features/orders/data/models/courier_point_model.dart';
import 'package:hero_mart/src/features/orders/data/models/rider_chat_message_model.dart';
import 'package:hero_mart/src/features/orders/data/models/rider_chat_model.dart';
import 'package:hero_mart/src/features/orders/data/repositories/rider_chat_repository_impl.dart';
import 'package:hero_mart/src/features/orders/domain/entities/rider_chat.dart';
import 'package:hero_mart/src/features/orders/domain/entities/rider_quick_reply.dart';
import 'package:hero_mart/src/features/orders/domain/repositories/rider_chat_repository.dart';
import 'package:hero_mart/src/features/orders/domain/usecases/mark_rider_chat_read_usecase.dart';
import 'package:hero_mart/src/features/orders/domain/usecases/send_rider_message_usecase.dart';
import 'package:hero_mart/src/features/orders/domain/usecases/watch_rider_chat_usecase.dart';
import 'package:hero_mart/src/features/orders/presentation/cubit/rider_chat_cubit.dart';
import 'package:hero_mart/src/features/orders/presentation/cubit/rider_chat_state.dart';

import 'live_map_test_fakes.dart';

final DateTime _t0 = DateTime.utc(2026, 9, 30, 12);

/// Records every read marker the cubit sets.
class _RecordingMarkRead implements MarkRiderChatReadUseCase {
  final List<MarkRiderChatReadParams> calls = <MarkRiderChatReadParams>[];

  @override
  Future<Either<Failure, Unit>> call(MarkRiderChatReadParams params) async {
    calls.add(params);
    return const Right(unit);
  }
}

RiderChatCubit _cubitWith(
  RiderChatRepository repository,
  MarkRiderChatReadUseCase markRead,
) => RiderChatCubit(
  watch: WatchRiderChatUseCase(repository),
  send: SendRiderMessageUseCase(repository),
  markRead: markRead,
);

void main() {
  group('SendRiderMessageUseCase', () {
    late FakeRiderChatRepository repository;
    late SendRiderMessageUseCase send;

    setUp(() {
      repository = FakeRiderChatRepository();
      send = SendRiderMessageUseCase(repository);
    });

    test('sends the trimmed text with the reply it came from', () async {
      final result = await send(
        const SendRiderMessageParams(
          orderId: 'o1',
          text: '  Leave it at the door  ',
          quick: RiderQuickReply.leaveAtDoor,
        ),
      );

      expect(result.isRight(), isTrue);
      expect(repository.sent.single, (
        'o1',
        'Leave it at the door',
        RiderQuickReply.leaveAtDoor,
      ));
    });

    test('an empty or over-long message is never sent', () async {
      final empty = await send(
        const SendRiderMessageParams(orderId: 'o1', text: '   '),
      );
      final long = await send(
        SendRiderMessageParams(
          orderId: 'o1',
          text: 'a' * (SendRiderMessageUseCase.maxLength + 1),
        ),
      );

      expect(empty.fold((f) => f, (_) => null), isA<ValidationFailure>());
      expect(long.fold((f) => f, (_) => null), isA<ValidationFailure>());
      expect(repository.sent, isEmpty);
    });
  });

  group('wire shape', () {
    test(
      'a rider message reads in each language; the customer\'s as typed',
      () {
        final rider = RiderChatMessageModel.fromJson(<String, dynamic>{
          '_id': 'm1',
          'from': 'rider',
          'sentAt': '2026-09-30T12:00:00.000Z',
          'text': 'Hi',
          'translated': <String, dynamic>{'en': 'Hi', 'ar': 'مرحبًا', 'x': 1},
        }).toEntity();
        final mine = RiderChatMessageModel.fromJson(<String, dynamic>{
          '_id': 'm2',
          'from': 'customer',
          'sentAt': '2026-09-30T12:01:00.000Z',
          'text': 'Thanks',
        }).toEntity();

        expect(rider.fromRider, isTrue);
        expect(rider.textFor('ar'), 'مرحبًا');
        expect(rider.textFor('en'), 'Hi');
        expect(mine.fromRider, isFalse);
        expect(mine.textFor('ar'), 'Thanks');
        expect(mine.sentAt, _t0.add(const Duration(minutes: 1)));
      },
    );

    test('no id, side or time is no message', () {
      expect(
        () => RiderChatMessageModel.fromJson(<String, dynamic>{
          'from': 'rider',
          'sentAt': '2026-09-30T12:00:00.000Z',
        }),
        throwsA(isA<ParsingException>()),
      );
    });

    test('round-trips through toJson', () {
      final model = RiderChatMessageModel(
        id: 'm1',
        from: RiderChatMessageModel.riderSide,
        sentAt: _t0,
        text: 'Hi',
        translated: const <String, String>{'en': 'Hi', 'ar': 'مرحبًا'},
      );
      final back = RiderChatMessageModel.fromJson(model.toJson());

      expect(back.toEntity(), model.toEntity());
      expect(
        RiderChatModel(messages: [model], riderTyping: true).toEntity(),
        RiderChat(messages: [model.toEntity()], riderTyping: true),
      );
    });

    test('the read marker round-trips, and is absent until set', () {
      final read = RiderChatModel(readUpTo: _t0);
      final back = RiderChatModel.fromJson(read.toJson());

      expect(back.readUpTo, _t0);
      expect(back.toEntity().readUpTo, _t0);
      expect(
        const RiderChatModel().toJson(),
        isNot(contains(RiderChatModel.readUpToKey)),
      );
      expect(RiderChatModel.fromJson(const {}).readUpTo, isNull);
    });
  });

  group('DemoRiderChatDataSource', () {
    const quick = Duration(milliseconds: 5);

    test(
      'the rider says hello, types, then answers in both languages',
      () async {
        final source = DemoRiderChatDataSource(
          now: () => _t0,
          readAfter: quick,
          replyAfter: quick,
        );
        final repository = RiderChatRepositoryImpl(source);
        final seen = <RiderChat>[];
        final sub = repository.watch('o1').listen(seen.add);
        await Future<void>.delayed(Duration.zero);

        expect(seen.single.messages.single.fromRider, isTrue);
        expect(
          seen.single.messages.single.textFor('ar'),
          DemoRiderChatDataSource.greeting.$2,
        );

        await repository.send('o1', 'Hi', quick: RiderQuickReply.comingDown);
        await Future<void>.delayed(const Duration(milliseconds: 40));

        expect(seen.any((chat) => chat.riderTyping), isTrue);
        final last = seen.last;
        expect(last.riderTyping, isFalse);
        expect(last.messages, hasLength(3));
        expect(last.messages[1].fromRider, isFalse);
        expect(last.messages[1].textFor('en'), 'Hi');
        final (en, ar) = DemoRiderChatDataSource.answerTo(
          RiderQuickReply.comingDown,
        );
        expect(last.messages[2].textFor('en'), en);
        expect(last.messages[2].textFor('ar'), ar);
        await sub.cancel();
      },
    );

    test(
      'one conversation per order: a second watcher sees it so far',
      () async {
        final source = DemoRiderChatDataSource(
          now: () => _t0,
          readAfter: quick,
          replyAfter: quick,
        );
        await source.send('o1', 'Hello');
        final later = await source.watch('o1').first;
        final other = await source.watch('o2').first;

        expect(later.messages, hasLength(2));
        expect(other.messages, hasLength(1));
        await Future<void>.delayed(const Duration(milliseconds: 20));
      },
    );

    test(
      'follows the ride: almost there, then at the door, once each',
      () async {
        final ride = StreamController<CourierFixModel>();
        final source = DemoRiderChatDataSource(
          now: () => _t0,
          readAfter: quick,
          replyAfter: quick,
          ride: (_) => ride.stream,
        );
        final seen = <RiderChat>[];
        final sub = RiderChatRepositoryImpl(source)
            .watch('o1')
            .listen(seen.add);
        CourierFixModel fix(String state, {int? eta}) => CourierFixModel(
          position: const CourierPointModel(lat: 29.3, lng: 48),
          at: _t0,
          state: state,
          etaSeconds: eta,
        );

        ride
          ..add(fix(CourierFixModel.onTheWayState, eta: 400))
          ..add(fix(CourierFixModel.onTheWayState, eta: 140))
          ..add(fix(CourierFixModel.onTheWayState, eta: 100))
          ..add(fix(CourierFixModel.arrivedState));
        await Future<void>.delayed(const Duration(milliseconds: 60));

        final words = [
          for (final message in seen.last.messages) message.textFor('en'),
        ];
        expect(words, [
          DemoRiderChatDataSource.greeting.$1,
          DemoRiderChatDataSource.almostThere.$1,
          DemoRiderChatDataSource.atTheDoor.$1,
        ]);
        expect(ride.hasListener, isFalse);
        await sub.cancel();
        await ride.close();
      },
    );

    test(
      'a ride that reached the door ends the chat: a new ride starts afresh',
      () async {
        final rides = <StreamController<CourierFixModel>>[];
        final source = DemoRiderChatDataSource(
          now: () => _t0,
          readAfter: quick,
          replyAfter: quick,
          ride: (_) {
            final ride = StreamController<CourierFixModel>();
            rides.add(ride);
            return ride.stream;
          },
        );
        CourierFixModel fix(String state, {int? eta}) => CourierFixModel(
          position: const CourierPointModel(lat: 29.3, lng: 48),
          at: _t0,
          state: state,
          etaSeconds: eta,
        );
        final first = source.watch('o1').listen((_) {});
        rides.single
          ..add(fix(CourierFixModel.onTheWayState, eta: 100))
          ..add(fix(CourierFixModel.arrivedState));
        await Future<void>.delayed(const Duration(milliseconds: 60));
        await first.cancel();

        final seen = <RiderChatModel>[];
        final second = source.watch('o1').listen(seen.add);
        await Future<void>.delayed(Duration.zero);

        expect(rides, hasLength(2));
        expect(seen.first.messages.map((message) => message.text), [
          DemoRiderChatDataSource.greeting.$1,
        ]);
        expect(seen.first.readUpTo, isNull);

        rides.last.add(fix(CourierFixModel.onTheWayState, eta: 100));
        await Future<void>.delayed(const Duration(milliseconds: 40));

        expect(seen.last.messages.map((message) => message.text), [
          DemoRiderChatDataSource.greeting.$1,
          DemoRiderChatDataSource.almostThere.$1,
        ]);
        // Mid-ride, a second watch is the same conversation.
        final again = await source.watch('o1').first;
        expect(again.messages, hasLength(2));
        await second.cancel();
        for (final ride in rides) {
          await ride.close();
        }
      },
    );

    test(
      'keeps how far the customer read, never back, telling no one',
      () async {
        final source = DemoRiderChatDataSource(
          now: () => _t0,
          readAfter: quick,
          replyAfter: quick,
        );
        final repository = RiderChatRepositoryImpl(source);
        final seen = <RiderChat>[];
        final sub = repository.watch('o1').listen(seen.add);
        await Future<void>.delayed(Duration.zero);

        final later = _t0.add(const Duration(seconds: 5));
        expect((await repository.markRead('o1', later)).isRight(), isTrue);
        await repository.markRead('o1', _t0);
        await Future<void>.delayed(Duration.zero);

        expect(seen, hasLength(1));
        expect((await repository.watch('o1').first).readUpTo, later);
        await sub.cancel();
      },
    );

    test('every one-tap reply has its own answer; typing gets thanks', () {
      final answers = {
        for (final reply in [...RiderQuickReply.values, null])
          DemoRiderChatDataSource.answerTo(reply),
      };

      expect(answers, hasLength(RiderQuickReply.values.length + 1));
    });
  });

  group('RiderChatCubit', () {
    late FakeRiderChatRepository repository;

    setUp(() => repository = FakeRiderChatRepository());

    RiderChat chatOf(int riderMessages) => RiderChat(
      messages: [
        for (var i = 0; i < riderMessages; i++)
          riderSays('m$i', _t0.add(Duration(seconds: i))),
      ],
    );

    blocTest<RiderChatCubit, RiderChatState>(
      'counts the rider\'s messages while the sheet is shut',
      build: () => buildRiderChatCubit(repository),
      act: (cubit) async {
        cubit.start('o1');
        repository.push(chatOf(2));
        await Future<void>.delayed(Duration.zero);
      },
      verify: (cubit) {
        expect(cubit.state.unread, 2);
        expect(repository.watched, ['o1']);
      },
    );

    blocTest<RiderChatCubit, RiderChatState>(
      'opening reads everything; after closing only new messages count',
      build: () => buildRiderChatCubit(repository),
      act: (cubit) async {
        cubit
          ..start('o1')
          ..start('o1');
        repository.push(chatOf(1));
        await Future<void>.delayed(Duration.zero);
        cubit.opened();
        expect(cubit.state.unread, 0);
        repository.push(chatOf(2));
        await Future<void>.delayed(Duration.zero);
        expect(cubit.state.unread, 0);
        cubit.closed();
        repository.push(chatOf(3));
        await Future<void>.delayed(Duration.zero);
      },
      verify: (cubit) {
        expect(cubit.state.unread, 1);
        expect(repository.watched, ['o1']);
      },
    );

    test(
      'a map opened again counts only what came after the last read',
      () async {
        final cubit = _cubitWith(repository, _RecordingMarkRead())..start('o1');
        addTearDown(cubit.close);
        final read = _t0.add(const Duration(seconds: 1));

        repository.push(
          RiderChat(messages: chatOf(2).messages, readUpTo: read),
        );
        await Future<void>.delayed(Duration.zero);
        expect(cubit.state.readUpTo, read);
        expect(cubit.state.unread, 0);

        repository.push(
          RiderChat(messages: chatOf(3).messages, readUpTo: read),
        );
        await Future<void>.delayed(Duration.zero);
        expect(cubit.state.unread, 1);
      },
    );

    test('opening and closing keep the read marker with the chat', () async {
      final markRead = _RecordingMarkRead();
      final cubit = _cubitWith(repository, markRead);
      addTearDown(cubit.close);

      // Nothing to mark before the chat starts, nor while it is empty.
      cubit
        ..opened()
        ..start('o1');
      repository.push(const RiderChat());
      await Future<void>.delayed(Duration.zero);
      cubit.closed();
      expect(markRead.calls, isEmpty);

      repository.push(chatOf(2));
      await Future<void>.delayed(Duration.zero);
      cubit.opened();
      repository.push(chatOf(3));
      await Future<void>.delayed(Duration.zero);
      cubit.closed();

      expect(markRead.calls, [
        MarkRiderChatReadParams('o1', _t0.add(const Duration(seconds: 1))),
        MarkRiderChatReadParams('o1', _t0.add(const Duration(seconds: 2))),
      ]);
      expect(cubit.state.unread, 0);
    });

    test('one message at a time; the second tap is refused', () async {
      final cubit = buildRiderChatCubit(repository)..start('o1');
      addTearDown(cubit.close);
      repository.gate = Completer<void>();

      final first = cubit.send('On my way down');
      final second = await cubit.send('Again');
      repository.gate!.complete();

      expect(second, isFalse);
      expect(await first, isTrue);
      expect(repository.sent.map((sent) => sent.$2), ['On my way down']);
      expect(cubit.state.sending, isFalse);
    });

    test('nothing is sent before the chat starts', () async {
      final cubit = buildRiderChatCubit(repository);
      addTearDown(cubit.close);

      expect(await cubit.send('Hi'), isFalse);
      expect(repository.sent, isEmpty);
    });

    test('a failed send is told; an empty one is quietly refused', () async {
      final cubit = buildRiderChatCubit(repository)..start('o1');
      addTearDown(cubit.close);

      expect(await cubit.send('  '), isFalse);
      expect(cubit.state.failure, isNull);

      repository.failWith = const NetworkFailure();
      expect(await cubit.send('Hi'), isFalse);
      expect(cubit.state.failure, isA<NetworkFailure>());
      expect(cubit.state.sending, isFalse);
    });
  });
}
