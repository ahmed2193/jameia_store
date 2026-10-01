// App-global address book: device copy + sync on start, wipe on stop, the
// owner of the device copy, the stale-reply guards, and the delete flow.
import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/features/address/domain/entities/address_book.dart';
import 'package:hero_mart/src/features/address/domain/entities/cached_address_book.dart';
import 'package:hero_mart/src/features/address/presentation/cubit/address_book_cubit.dart';
import 'package:hero_mart/src/features/address/presentation/cubit/address_book_state.dart';

import 'address_test_fakes.dart';

void main() {
  late FakeGetCachedAddressesUseCase getCached;
  late FakeGetAddressesUseCase getAddresses;
  late FakeDeleteAddressUseCase deleteAddress;
  late FakeSaveCachedAddressesUseCase saveCache;
  late FakeClearCachedAddressesUseCase clearCache;

  const customerA = 'aaaaaaaaaaaaaaaaaaaaaaaa';
  const customerB = 'bbbbbbbbbbbbbbbbbbbbbbbb';

  final cachedBook = AddressBook.of([address(n: 1, isDefault: true)]);
  final serverBook = AddressBook.of([
    address(n: 1, isDefault: true),
    address(n: 2),
  ]);

  CachedAddressBook copyOf(AddressBook book, {String? ownerId}) =>
      CachedAddressBook(ownerId: ownerId, addresses: book.addresses);

  AddressBookCubit build() => AddressBookCubit(
    getCached: getCached,
    getAddresses: getAddresses,
    updateAddress: FakeUpdateAddressUseCase(Right(address(n: 1))),
    deleteAddress: deleteAddress,
    saveCache: saveCache,
    clearCache: clearCache,
  );

  /// Lets queued microtasks / futures run.
  Future<void> flush() => Future<void>.delayed(Duration.zero);

  setUp(() {
    getCached = FakeGetCachedAddressesUseCase();
    getAddresses = FakeGetAddressesUseCase(Right(serverBook));
    deleteAddress = FakeDeleteAddressUseCase();
    saveCache = FakeSaveCachedAddressesUseCase();
    clearCache = FakeClearCachedAddressesUseCase();
  });

  group('onReconnected', () {
    test('a book the server has not answered for syncs now', () async {
      getCached.result = Right(copyOf(cachedBook, ownerId: customerA));
      getAddresses.result = const Left(NetworkFailure());
      final cubit = build();
      addTearDown(cubit.close);
      await cubit.start(customerId: customerA);
      expect(cubit.state.book, cachedBook);
      expect(cubit.state.isSynced, isFalse);

      getAddresses.result = Right(serverBook);
      await cubit.onReconnected();

      expect(cubit.state.isSynced, isTrue);
      expect(cubit.state.book, serverBook);
    });

    test(
      'a synced book, or one never started (a guest), asks nothing',
      () async {
        final cubit = build();
        addTearDown(cubit.close);

        await cubit.onReconnected();
        await cubit.start(customerId: customerA);
        await cubit.onReconnected();

        expect(getAddresses.calls, 1);
      },
    );
  });

  group('start', () {
    blocTest<AddressBookCubit, AddressBookState>(
      'nothing cached: loading → server book (synced), saved for the customer',
      build: build,
      act: (cubit) => cubit.start(customerId: customerA),
      expect: () => [
        const AddressBookState(status: AddressBookStatus.loading),
        const AddressBookState(
          status: AddressBookStatus.loading,
          isSyncing: true,
        ),
        AddressBookState(
          status: AddressBookStatus.loaded,
          book: serverBook,
          isSynced: true,
        ),
      ],
      verify: (_) {
        expect(getAddresses.calls, 1);
        expect(saveCache.saved, [serverBook]);
        expect(saveCache.writes.single.ownerId, customerA);
      },
    );

    blocTest<AddressBookCubit, AddressBookState>(
      'a device copy shows at once, then the server book replaces it',
      build: build,
      setUp: () =>
          getCached.result = Right(copyOf(cachedBook, ownerId: customerA)),
      act: (cubit) => cubit.start(customerId: customerA),
      expect: () => [
        const AddressBookState(status: AddressBookStatus.loading),
        AddressBookState(status: AddressBookStatus.loaded, book: cachedBook),
        AddressBookState(
          status: AddressBookStatus.loaded,
          book: cachedBook,
          isSyncing: true,
        ),
        AddressBookState(
          status: AddressBookStatus.loaded,
          book: serverBook,
          isSynced: true,
        ),
      ],
    );

    blocTest<AddressBookCubit, AddressBookState>(
      'offline with a device copy: the copy stays, the failure is transient, '
      'nothing is re-saved',
      build: build,
      setUp: () {
        getCached.result = Right(copyOf(cachedBook, ownerId: customerA));
        getAddresses.result = const Left(NetworkFailure());
      },
      act: (cubit) => cubit.start(),
      skip: 3,
      expect: () => [
        AddressBookState(
          status: AddressBookStatus.loaded,
          book: cachedBook,
          failure: const NetworkFailure(),
          failedAction: AddressBookAction.sync,
        ),
      ],
      verify: (cubit) {
        expect(cubit.state.isSynced, isFalse);
        expect(saveCache.saved, isEmpty);
      },
    );

    blocTest<AddressBookCubit, AddressBookState>(
      'nothing cached + offline → error with the failure kept for the screen',
      build: build,
      setUp: () => getAddresses.result = const Left(NetworkFailure()),
      act: (cubit) => cubit.start(),
      skip: 2,
      expect: () => [
        const AddressBookState(
          status: AddressBookStatus.error,
          loadFailure: NetworkFailure(),
          failure: NetworkFailure(),
          failedAction: AddressBookAction.sync,
        ),
      ],
    );

    blocTest<AddressBookCubit, AddressBookState>(
      '401 with nothing cached → signedOut',
      build: build,
      setUp: () => getAddresses.result = const Left(UnauthorizedFailure()),
      act: (cubit) => cubit.start(),
      skip: 2,
      expect: () => [
        const AddressBookState(
          status: AddressBookStatus.signedOut,
          loadFailure: UnauthorizedFailure(),
          failure: UnauthorizedFailure(),
          failedAction: AddressBookAction.sync,
        ),
      ],
    );

    test('an unreadable device copy is ignored; the sync still runs', () async {
      getCached.result = const Left(CacheFailure());
      final cubit = build();
      addTearDown(cubit.close);
      await cubit.start(customerId: customerA);
      expect(cubit.state.book, serverBook);
      expect(cubit.state.isSynced, isTrue);
    });

    test('a second start for the same customer does nothing', () async {
      final cubit = build();
      addTearDown(cubit.close);
      await cubit.start(customerId: customerA);
      await cubit.start(customerId: customerA);
      await cubit.start();
      expect(getCached.calls, 1);
      expect(getAddresses.calls, 1);
      expect(clearCache.calls, 0);
    });

    test('an identical sync result is not written again', () async {
      final cubit = build();
      addTearDown(cubit.close);
      await cubit.start(customerId: customerA);
      await cubit.refresh();
      expect(getAddresses.calls, 2);
      expect(saveCache.writes, hasLength(1));
    });
  });

  group('owner of the device copy', () {
    test("another customer's copy is never shown and is removed", () async {
      getCached.result = Right(copyOf(cachedBook, ownerId: customerA));
      final shown = <AddressBook>[];
      final cubit = build();
      addTearDown(cubit.close);
      final subscription = cubit.stream.listen((s) => shown.add(s.book));
      addTearDown(subscription.cancel);

      await cubit.start(customerId: customerB);
      await flush();

      expect(shown, isNot(contains(cachedBook)));
      expect(clearCache.calls, 1);
      expect(cubit.state.book, serverBook);
      expect(saveCache.writes.single.ownerId, customerB);
    });

    test('a launch offline (customer unknown) adopts the owner of the copy; '
        'the same customer showing up later changes nothing', () async {
      getCached.result = Right(copyOf(cachedBook, ownerId: customerA));
      getAddresses.result = const Left(NetworkFailure());
      final cubit = build();
      addTearDown(cubit.close);

      await cubit.start();
      expect(cubit.state.book, cachedBook);

      await cubit.start(customerId: customerA);
      expect(getAddresses.calls, 1);
      expect(clearCache.calls, 0);
      expect(cubit.state.book, cachedBook);
    });

    test(
      'signing in as another customer without a sign-out starts over',
      () async {
        final cubit = build();
        addTearDown(cubit.close);
        await cubit.start(customerId: customerA);

        final bookB = AddressBook.of([address(n: 7)]);
        getAddresses.result = Right(bookB);
        await cubit.start(customerId: customerB);

        expect(clearCache.calls, 1);
        expect(getAddresses.calls, 2);
        expect(cubit.state.book, bookB);
        expect(saveCache.writes.last.ownerId, customerB);
        expect(saveCache.writes.last.book, bookB);
      },
    );

    test('a book synced while the customer was unknown is started over once '
        'the customer is known', () async {
      final cubit = build();
      addTearDown(cubit.close);
      await cubit.start();
      expect(saveCache.writes.single.ownerId, isNull);

      await cubit.start(customerId: customerA);
      expect(clearCache.calls, 1);
      expect(getAddresses.calls, 2);
      expect(saveCache.writes.last.ownerId, customerA);
    });

    test('a sign-out while a restart clears the old copy wins', () async {
      final cubit = build();
      addTearDown(cubit.close);
      await cubit.start(customerId: customerA);

      final restarting = cubit.start(customerId: customerB);
      final stopping = cubit.stop();
      await Future.wait([restarting, stopping]);

      expect(cubit.state, const AddressBookState());
      expect(getAddresses.calls, 1);
    });
  });

  group('stop', () {
    blocTest<AddressBookCubit, AddressBookState>(
      'resets the state and wipes the device copy',
      build: build,
      act: (cubit) async {
        await cubit.start(customerId: customerA);
        await cubit.stop();
      },
      skip: 3,
      expect: () => [const AddressBookState()],
      verify: (_) => expect(clearCache.calls, 1),
    );

    test('a launch without a session still wipes a leftover copy', () async {
      final cubit = build();
      addTearDown(cubit.close);
      await cubit.stop();
      expect(clearCache.calls, 1);
      expect(cubit.state, const AddressBookState());
    });

    test(
      'a sync reply that lands after sign-out is dropped, never cached',
      () async {
        final cubit = build();
        addTearDown(cubit.close);
        getAddresses.gate = Completer<void>();
        final started = cubit.start(customerId: customerA);
        await flush();
        await cubit.stop();

        getAddresses.gate!.complete();
        await started;
        expect(cubit.state, const AddressBookState());
        expect(saveCache.saved, isEmpty);
      },
    );

    test('sign-out then sign-in while the old sync hangs: the new session '
        'syncs on its own', () async {
      final cubit = build();
      addTearDown(cubit.close);
      final oldGate = Completer<void>();
      getAddresses.gate = oldGate;
      unawaited(cubit.start(customerId: customerA));
      await flush();
      await cubit.stop();

      getAddresses.gate = null;
      await cubit.start(customerId: customerA);
      expect(getAddresses.calls, 2);
      expect(cubit.state.book, serverBook);
      expect(cubit.state.isSynced, isTrue);

      oldGate.complete();
      await flush();
      expect(cubit.state.book, serverBook);
      expect(saveCache.saved, [serverBook]);
    });
  });

  group('sync entry points', () {
    test('ensureSynced does nothing once synced', () async {
      final cubit = build();
      addTearDown(cubit.close);
      await cubit.start(customerId: customerA);
      await cubit.ensureSynced();
      expect(getAddresses.calls, 1);
    });

    test('concurrent refresh + ensureSynced share one request', () async {
      final cubit = build();
      addTearDown(cubit.close);
      getAddresses.gate = Completer<void>();
      final first = cubit.refresh();
      final second = cubit.ensureSynced();
      getAddresses.gate!.complete();
      await Future.wait([first, second]);
      expect(getAddresses.calls, 1);
    });

    test(
      'a guest opening the list gets signedOut and nothing is cached',
      () async {
        getAddresses.result = const Left(UnauthorizedFailure());
        final cubit = build();
        addTearDown(cubit.close);
        await cubit.ensureSynced();
        expect(cubit.state.status, AddressBookStatus.signedOut);
        expect(saveCache.saved, isEmpty);
      },
    );

    test('a book fetched before the session was known is kept by start and '
        'saved, without a second request', () async {
      final cubit = build();
      addTearDown(cubit.close);
      await cubit.ensureSynced();
      expect(saveCache.saved, isEmpty);

      await cubit.start(customerId: customerA);
      expect(getAddresses.calls, 1);
      expect(getCached.calls, 0);
      expect(cubit.state.book, serverBook);
      expect(saveCache.writes.single.ownerId, customerA);
    });

    test(
      'a sync that keeps failing after a local change still reports it',
      () async {
        final cubit = build();
        addTearDown(cubit.close);
        await cubit.start(customerId: customerA);

        final gate = Completer<void>();
        getAddresses
          ..gate = gate
          ..result = const Left(NetworkFailure());
        final refreshing = cubit.refresh();
        await flush();
        cubit.applySaved(address(n: 3));
        gate.complete();
        await refreshing;

        expect(getAddresses.calls, 3);
        expect(cubit.state.book.byId(addressId(3)), isNotNull);
        expect(cubit.state.failure, isA<NetworkFailure>());
      },
    );
  });

  group('applySaved', () {
    test(
      'adds the saved address, keeps one default, saves the device copy',
      () async {
        final cubit = build();
        addTearDown(cubit.close);
        await cubit.start(customerId: customerA);
        final saved = address(n: 3, isDefault: true);
        cubit.applySaved(saved);
        expect(cubit.state.book.addresses.first, saved);
        expect(cubit.state.book.addresses.where((a) => a.isDefault), [saved]);
        expect(saveCache.saved.last, cubit.state.book);
        expect(saveCache.writes.last.ownerId, customerA);
      },
    );

    test('a save during an in-flight sync makes the sync fetch again, so the '
        'older reply never hides the new address', () async {
      final cubit = build();
      addTearDown(cubit.close);
      await cubit.start(customerId: customerA);

      final saved = address(n: 3);
      final withSaved = serverBook.upsert(saved);
      final gate = Completer<void>();
      getAddresses
        ..gate = gate
        ..queue.add(Right(serverBook)) // predates the save
        ..result = Right(withSaved);
      final refreshing = cubit.refresh();
      await flush();
      cubit.applySaved(saved);
      gate.complete();
      await refreshing;

      expect(getAddresses.calls, 3); // start + stale reply + re-fetch
      expect(cubit.state.book.byId(saved.id), saved);
      expect(saveCache.saved.last, withSaved);
    });
  });

  group('delete', () {
    test('B1-17: the row leaves at once, the copy is saved once the server '
        'confirmed', () async {
      final cubit = build();
      addTearDown(cubit.close);
      await cubit.start(customerId: customerA);
      final gate = Completer<void>();
      deleteAddress.gate = gate;
      final states = <AddressBookState>[];
      final sub = cubit.stream.listen(states.add);
      addTearDown(sub.cancel);

      final deleting = cubit.delete(addressId(2));
      await flush();
      expect(cubit.state.book.byId(addressId(2)), isNull, reason: 'at once');
      expect(cubit.state.isDeleting(addressId(2)), isTrue);
      expect(states.first.deletedId, addressId(2), reason: 'Undo offered');
      expect(saveCache.saved, [serverBook], reason: 'not confirmed yet');

      gate.complete();
      await deleting;
      expect(cubit.state.isDeleting(addressId(2)), isFalse);
      expect(cubit.state.book.byId(addressId(2)), isNull);
      expect(saveCache.saved.last, cubit.state.book);
      expect(cubit.state.failure, isNull);
    });

    test('B1-17: Undo inside the window puts the row back in place and '
        'sends nothing', () async {
      final three = AddressBook.of([
        address(n: 1, isDefault: true),
        address(n: 2),
        address(n: 3),
      ]);
      getAddresses.result = Right(three);
      final cubit = build();
      addTearDown(cubit.close);
      await cubit.start(customerId: customerA);

      final deleting = cubit.delete(
        addressId(2),
        undoWindow: const Duration(hours: 1),
      );
      await flush();
      expect(cubit.state.book.addresses.map((a) => a.id), [
        addressId(1),
        addressId(3),
      ]);

      expect(cubit.undoDelete(addressId(2)), isTrue);
      await deleting;

      expect(cubit.state.book, three, reason: 'back in its place');
      expect(cubit.state.isDeleting(addressId(2)), isFalse);
      expect(deleteAddress.calls, isEmpty);
      expect(cubit.undoDelete(addressId(2)), isFalse, reason: 'nothing left');
      expect(saveCache.saved, [three]);
    });

    test('B1-17: the DELETE goes out when the window ends; Undo is too late '
        'then', () async {
      final cubit = build();
      addTearDown(cubit.close);
      await cubit.start(customerId: customerA);
      deleteAddress.gate = Completer<void>();

      final deleting = cubit.delete(
        addressId(2),
        undoWindow: const Duration(milliseconds: 10),
      );
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(deleteAddress.calls, hasLength(1));
      expect(cubit.undoDelete(addressId(2)), isFalse);

      deleteAddress.gate!.complete();
      await deleting;
      expect(cubit.state.book.byId(addressId(2)), isNull);
    });

    test('B1-17: a sync while the delete waits never brings the row back '
        '(race with a concurrent load)', () async {
      final cubit = build();
      addTearDown(cubit.close);
      await cubit.start(customerId: customerA);

      final deleting = cubit.delete(
        addressId(2),
        undoWindow: const Duration(hours: 1),
      );
      await cubit.refresh(); // the server still lists it
      expect(getAddresses.calls, 2);
      expect(cubit.state.book.byId(addressId(2)), isNull);

      expect(cubit.undoDelete(addressId(2)), isTrue);
      await deleting;
      expect(cubit.state.book, serverBook);
    });

    test('B1-17: a refused delete after its window puts the row back in '
        'place', () async {
      final three = AddressBook.of([
        address(n: 1, isDefault: true),
        address(n: 2),
        address(n: 3),
      ]);
      getAddresses.result = Right(three);
      final cubit = build();
      addTearDown(cubit.close);
      await cubit.start(customerId: customerA);
      deleteAddress.result = const Left(NetworkFailure());

      await cubit.delete(
        addressId(2),
        undoWindow: const Duration(milliseconds: 1),
      );

      expect(cubit.state.book, three);
      expect(cubit.state.failure, isA<NetworkFailure>());
      expect(cubit.state.failedAction, AddressBookAction.delete);
      expect(cubit.state.isDeleting(addressId(2)), isFalse);
    });

    test(
      'B1-17: signed out inside the window: the delete is never sent',
      () async {
        final cubit = build();
        addTearDown(cubit.close);
        await cubit.start(customerId: customerA);

        final deleting = cubit.delete(
          addressId(2),
          undoWindow: const Duration(hours: 1),
        );
        await flush();
        await cubit.stop();
        await deleting;

        expect(deleteAddress.calls, isEmpty);
        expect(cubit.state, const AddressBookState());
      },
    );

    test(
      'a delete during an in-flight sync makes the sync fetch again',
      () async {
        final cubit = build();
        addTearDown(cubit.close);
        await cubit.start(customerId: customerA);

        final withoutTwo = serverBook.remove(addressId(2));
        final gate = Completer<void>();
        getAddresses
          ..gate = gate
          ..queue.add(Right(serverBook)) // still lists the deleted row
          ..result = Right(withoutTwo);
        final refreshing = cubit.refresh();
        await flush();
        await cubit.delete(addressId(2));
        gate.complete();
        await refreshing;

        expect(getAddresses.calls, 3);
        expect(cubit.state.book.byId(addressId(2)), isNull);
      },
    );

    test('a double tap sends one DELETE', () async {
      final cubit = build();
      addTearDown(cubit.close);
      await cubit.start(customerId: customerA);
      deleteAddress.gate = Completer<void>();
      final first = cubit.delete(addressId(2));
      final second = cubit.delete(addressId(2));
      deleteAddress.gate!.complete();
      await Future.wait([first, second]);
      expect(deleteAddress.calls, hasLength(1));
    });

    test('B1-17: a double tap inside the Undo window queues one delete and '
        'one Undo snack', () async {
      final cubit = build();
      addTearDown(cubit.close);
      await cubit.start(customerId: customerA);
      final offered = <String>[];
      final sub = cubit.stream.listen((state) {
        final id = state.deletedId;
        if (id != null) offered.add(id);
      });
      addTearDown(sub.cancel);

      final first = cubit.delete(
        addressId(2),
        undoWindow: const Duration(milliseconds: 5),
      );
      final second = cubit.delete(
        addressId(2),
        undoWindow: const Duration(milliseconds: 5),
      );
      await Future.wait([first, second]);

      expect(offered, [addressId(2)]);
      expect(deleteAddress.calls, hasLength(1));
      expect(cubit.state.book.byId(addressId(2)), isNull);
    });

    test(
      'a refused delete puts the row back and reports the failure',
      () async {
        final cubit = build();
        addTearDown(cubit.close);
        await cubit.start(customerId: customerA);
        deleteAddress.result = const Left(
          ServerFailure('Try later', statusCode: 500),
        );

        await cubit.delete(addressId(2));
        expect(cubit.state.book, serverBook);
        expect(cubit.state.isDeleting(addressId(2)), isFalse);
        expect(cubit.state.failure, isA<ServerFailure>());
        expect(cubit.state.failedAction, AddressBookAction.delete);
        expect(saveCache.saved, [serverBook]); // only the sync saved
      },
    );

    test('unknown ids are ignored', () async {
      final cubit = build();
      addTearDown(cubit.close);
      await cubit.start(customerId: customerA);
      await cubit.delete(addressId(9));
      expect(deleteAddress.calls, isEmpty);
    });

    test('a delete that lands after sign-out changes nothing', () async {
      final cubit = build();
      addTearDown(cubit.close);
      await cubit.start(customerId: customerA);
      deleteAddress.gate = Completer<void>();
      final deleting = cubit.delete(addressId(2));
      await flush();
      await cubit.stop();
      deleteAddress.gate!.complete();
      await deleting;
      expect(cubit.state, const AddressBookState());
      expect(saveCache.saved, [serverBook]);
    });

    // Review fix I2: the page holds the DELETE for its Undo snack's life.
    test('held for Undo: nothing is sent until the page releases it', () async {
      final cubit = build();
      addTearDown(cubit.close);
      await cubit.start(customerId: customerA);

      final deleting = cubit.delete(addressId(2), holdForUndo: true);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(deleteAddress.calls, isEmpty, reason: 'no timer of its own');

      cubit.releaseDelete(addressId(2));
      await deleting;
      expect(deleteAddress.calls.single.id, addressId(2));
      expect(cubit.undoDelete(addressId(2)), isFalse);
    });

    test('held for Undo: an Undo before the release sends nothing, and a '
        'late release does nothing', () async {
      final cubit = build();
      addTearDown(cubit.close);
      await cubit.start(customerId: customerA);

      final deleting = cubit.delete(addressId(2), holdForUndo: true);
      await flush();
      expect(cubit.undoDelete(addressId(2)), isTrue);
      cubit.releaseDelete(addressId(2));
      await deleting;

      expect(deleteAddress.calls, isEmpty);
      expect(cubit.state.book, serverBook);
    });

    // Review fix O3: the device copy changes only once the server confirmed.
    test('a save while a delete waits keeps the waiting row in the device '
        'copy; the confirmed delete then drops it', () async {
      final cubit = build();
      addTearDown(cubit.close);
      await cubit.start(customerId: customerA);
      expect(saveCache.saved, [serverBook]);

      final deleting = cubit.delete(addressId(2), holdForUndo: true);
      await flush();
      final edited = address(
        n: 1,
        label: 'Home 2',
        isDefault: serverBook.byId(addressId(1))!.isDefault,
      );
      cubit.applySaved(edited);
      await flush();

      final written = saveCache.saved.last;
      expect(written.byId(addressId(2)), isNotNull, reason: 'not confirmed');
      expect(written.byId(addressId(1))!.label, 'Home 2');
      expect(cubit.state.book.byId(addressId(2)), isNull, reason: 'on screen');

      cubit.releaseDelete(addressId(2));
      await deleting;
      await flush();
      expect(saveCache.saved.last.byId(addressId(2)), isNull);
      expect(saveCache.saved.last.byId(addressId(1))!.label, 'Home 2');
    });
  });
}
