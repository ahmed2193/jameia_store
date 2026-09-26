import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/features/assistant/domain/entities/assistant_availability.dart';
import 'package:jameia_mart/src/features/assistant/domain/entities/assistant_conversation_entity.dart';
import 'package:jameia_mart/src/features/assistant/presentation/cubit/assistant_availability_state.dart';
import 'package:jameia_mart/src/features/assistant/presentation/cubit/assistant_history_state.dart';

import 'assistant_test_fakes.dart';

void main() {
  late FakeAssistantRepository repository;
  setUp(() => repository = FakeAssistantRepository());

  AssistantConversationEntity conversation(String id) =>
      AssistantConversationEntity(id: id, title: id);

  group('AssistantHistoryCubit', () {
    test('pages of 20: load → loaded, loadMore appends', () async {
      final cubit = historyCubit(repository);
      addTearDown(cubit.close);
      final loading = cubit.load();
      expect(cubit.state.status, AssistantHistoryStatus.loading);
      expect(repository.lists.single.args, (page: 1, limit: 20));
      repository.lists.single.open(
        Right(feedOf([conversation('a')], hasMore: true)),
      );
      await loading;
      final more = cubit.loadMore();
      cubit.loadMore(); // re-entry guard
      expect(repository.lists, hasLength(2));
      expect(repository.lists.last.args, (page: 2, limit: 20));
      repository.lists.last.open(Right(feedOf([conversation('b')], page: 2)));
      await more;
      expect(cubit.state.feed.items.map((c) => c.id), ['a', 'b']);
      expect(cubit.state.feed.hasMore, isFalse);
    });

    test('a page that a refresh overtook is dropped', () async {
      final cubit = historyCubit(repository);
      addTearDown(cubit.close);
      final loading = cubit.load();
      repository.lists.single.open(
        Right(feedOf([conversation('a')], hasMore: true)),
      );
      await loading;
      final stale = cubit.loadMore();
      final refresh = cubit.refresh();
      repository.lists[2].open(Right(feedOf([conversation('fresh')])));
      await refresh;
      repository.lists[1].open(Right(feedOf([conversation('stale')], page: 2)));
      await stale;
      expect(cubit.state.feed.items.map((c) => c.id), ['fresh']);
      expect(cubit.state.isLoadingMore, isFalse);
    });

    test(
      'signed out → the sign-in prompt; a failed page → retry footer',
      () async {
        final cubit = historyCubit(repository);
        addTearDown(cubit.close);
        final loading = cubit.load();
        repository.lists.single.open(const Left(UnauthorizedFailure()));
        await loading;
        expect(cubit.state.isSignedOut, isTrue);

        final again = cubit.load();
        repository.lists.last.open(
          Right(feedOf([conversation('a')], hasMore: true)),
        );
        await again;
        final more = cubit.loadMore();
        repository.lists.last.open(const Left(NetworkFailure()));
        await more;
        expect(cubit.state.loadMoreFailed, isTrue);
        expect(cubit.state.failedAction, AssistantHistoryAction.loadMore);
        expect(cubit.state.isLoaded, isTrue);
      },
    );
  });

  group('AssistantAvailabilityCubit', () {
    test(
      'reads /v1/init once; concurrent entry points share the read',
      () async {
        final cubit = availabilityCubit(repository);
        addTearDown(cubit.close);
        final first = cubit.ensureLoaded();
        final second = cubit.ensureLoaded();
        expect(repository.availability, hasLength(1));
        repository.availability.single.open(
          const Right(AssistantAvailability(enabled: true, allowGuests: false)),
        );
        await Future.wait([first, second]);
        expect(cubit.state.isAvailable, isTrue);
        expect(cubit.state.allowGuests, isFalse);
        await cubit.ensureLoaded();
        expect(repository.availability, hasLength(1));
      },
    );

    test('disabled or flagged off → unavailable', () async {
      final cubit = availabilityCubit(repository);
      addTearDown(cubit.close);
      final loading = cubit.ensureLoaded();
      repository.availability.single.open(
        const Right(AssistantAvailability(enabled: true, featureFlag: false)),
      );
      await loading;
      expect(cubit.state.status, AssistantAvailabilityStatus.unavailable);
    });

    test(
      'a failed read stays unknown (entries hidden) and may retry',
      () async {
        final cubit = availabilityCubit(repository);
        addTearDown(cubit.close);
        final loading = cubit.ensureLoaded();
        repository.availability.single.open(const Left(NetworkFailure()));
        await loading;
        expect(cubit.state.status, AssistantAvailabilityStatus.unknown);
        final retry = cubit.ensureLoaded();
        expect(repository.availability, hasLength(2));
        repository.availability.last.open(
          const Right(AssistantAvailability(enabled: true, allowGuests: true)),
        );
        await retry;
        expect(cubit.state.isAvailable, isTrue);
      },
    );

    test('a failed read is tried again on its own, then gives up', () async {
      final cubit = availabilityCubit(
        repository,
        retryDelays: const [Duration(milliseconds: 1)],
      );
      addTearDown(cubit.close);
      final loading = cubit.ensureLoaded();
      repository.availability.single.open(const Left(NetworkFailure()));
      await loading;
      await Future<void>.delayed(const Duration(milliseconds: 20));
      // The retry went out without anyone asking.
      expect(repository.availability, hasLength(2));
      repository.availability.last.open(const Left(NetworkFailure()));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      // Out of automatic retries: no third read.
      expect(repository.availability, hasLength(2));
      expect(cubit.state.status, AssistantAvailabilityStatus.unknown);
    });
  });
}
