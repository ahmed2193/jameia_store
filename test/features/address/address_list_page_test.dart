// "My addresses" over a GoRouter with the app-global AddressBookCubit built on
// fake use cases: the screen faces (loaded, empty, signed-out, error), delete
// with confirmation, and the picker pop.
import 'dart:async';
import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hero_mart/src/config/routes/routes.dart';
import 'package:hero_mart/src/config/theme/app_theme.dart';
import 'package:hero_mart/src/core/domain/entities/hero_address_entity.dart';
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/features/address/domain/entities/address_book.dart';
import 'package:hero_mart/src/features/address/presentation/cubit/address_book_cubit.dart';
import 'package:hero_mart/src/features/address/presentation/pages/address_list_page.dart';
import 'package:hero_mart/src/features/address/presentation/widgets/address_list/address_row_tile.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'address_test_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeGetCachedAddressesUseCase getCached;
  late FakeGetAddressesUseCase getAddresses;
  late FakeDeleteAddressUseCase deleteAddress;
  late FakeSaveCachedAddressesUseCase saveCache;
  late AddressBookCubit book;

  final home = address(n: 1, isDefault: true);
  final work = address(
    n: 2,
    label: 'Work',
    city: 'Hawally',
    block: '4',
    street: '10',
    building: '120',
    floor: '3',
    phone: '+96566001122',
  );

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    final enRaw = await rootBundle.loadString('assets/i18n/en.json');
    Localization.load(
      const Locale('en'),
      translations: Translations(json.decode(enRaw) as Map<String, dynamic>),
    );
  });

  setUp(() {
    getCached = FakeGetCachedAddressesUseCase();
    getAddresses = FakeGetAddressesUseCase(Right(AddressBook.of([home, work])));
    deleteAddress = FakeDeleteAddressUseCase();
    saveCache = FakeSaveCachedAddressesUseCase();
    book = AddressBookCubit(
      getCached: getCached,
      getAddresses: getAddresses,
      updateAddress: FakeUpdateAddressUseCase(Right(home)),
      deleteAddress: deleteAddress,
      saveCache: saveCache,
      clearCache: FakeClearCachedAddressesUseCase(),
    );
  });

  tearDown(() => book.close());

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// A launcher page pushes the list (so it can pop a picked address back).
  Future<GoRouter> pumpList(
    WidgetTester tester, {
    List<Object?>? picked,
  }) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () async {
                final result = await context.push<Object?>(Routes.addressList);
                picked?.add(result);
              },
              child: const Text('open'),
            ),
          ),
        ),
        GoRoute(
          path: Routes.addressList,
          builder: (_, _) => const AddressListPage(),
        ),
        GoRoute(
          path: Routes.login,
          builder: (_, _) => const Scaffold(body: Text('login')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('ar')],
        path: 'assets/i18n',
        fallbackLocale: const Locale('en'),
        startLocale: const Locale('en'),
        saveLocale: false,
        child: BlocProvider<AddressBookCubit>.value(
          value: book,
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      ),
    );
    await settle(tester);
    await tester.tap(find.text('open'));
    await settle(tester);
    expect(find.byType(AddressListPage), findsOneWidget);
    return router;
  }

  Future<void> teardownApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  }

  testWidgets('a started session shows the book without another request', (
    tester,
  ) async {
    await book.start();
    await pumpList(tester);

    expect(find.byType(AddressRowTile), findsNWidgets(2));
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Work'), findsOneWidget);
    expect(
      find.text('Salmiya, Block 7, Street 22, Building 5'),
      findsOneWidget,
    );
    expect(
      find.text('Hawally, Block 4, Street 10, Building 120, Floor 3'),
      findsOneWidget,
    );
    expect(find.text('+96566001122'), findsOneWidget);
    expect(find.text('New address'), findsOneWidget);
    expect(getAddresses.calls, 1); // the sign-in sync only

    await teardownApp(tester);
  });

  testWidgets('an empty book shows the empty state', (tester) async {
    getAddresses.result = const Right(AddressBook.empty);
    await book.start();
    await pumpList(tester);

    expect(find.text("You haven't saved any addresses yet."), findsOneWidget);
    expect(find.byType(AddressRowTile), findsNothing);

    await teardownApp(tester);
  });

  testWidgets('a guest gets the sign-in prompt, no CTA, and login via go', (
    tester,
  ) async {
    getAddresses.result = const Left(UnauthorizedFailure('Sign in'));
    final router = await pumpList(tester);

    expect(
      find.text('Sign in to see and manage your saved addresses'),
      findsOneWidget,
    );
    expect(find.text('New address'), findsNothing);

    await tester.tap(find.text('Sign in'));
    await settle(tester);
    expect(router.state.uri.path, Routes.login);

    await teardownApp(tester);
  });

  testWidgets('offline with nothing cached: "No connection" with retry', (
    tester,
  ) async {
    getAddresses.result = const Left(NetworkFailure());
    await pumpList(tester);

    // The offline contract (FailureView), not a raw error.
    expect(find.text('No connection'), findsOneWidget);
    getAddresses.result = Right(AddressBook.of([home]));
    await tester.tap(find.text('Retry'));
    await settle(tester);
    expect(find.byType(AddressRowTile), findsOneWidget);

    await teardownApp(tester);
  });

  /// The Undo window: the snack rises in, then dwells.
  const undoWindow = Duration(milliseconds: 4250);

  testWidgets('delete asks first, removes the row at once (no busy scrim), '
      'then deletes on the server (B1-17)', (tester) async {
    await book.start();
    await pumpList(tester);

    await tester.tap(find.byTooltip('Delete').last);
    await settle(tester);
    expect(
      find.text('Addresses cannot be restored once deleted. Confirm deletion?'),
      findsOneWidget,
    );
    await tester.tap(find.text('Confirm'));
    await settle(tester);

    expect(find.byType(AddressRowTile), findsOneWidget, reason: 'at once');
    expect(find.text('Address deleted'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);
    expect(deleteAddress.calls, isEmpty, reason: 'the Undo window is open');

    await tester.pump(undoWindow);
    await settle(tester);
    expect(deleteAddress.calls.single.id, work.id);
    expect(find.byType(AddressRowTile), findsOneWidget);

    await teardownApp(tester);
  });

  testWidgets('Undo puts the row back and sends nothing', (tester) async {
    await book.start();
    await pumpList(tester);

    await tester.tap(find.byTooltip('Delete').last);
    await settle(tester);
    await tester.tap(find.text('Confirm'));
    await settle(tester);
    expect(find.byType(AddressRowTile), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await settle(tester);
    expect(find.byType(AddressRowTile), findsNWidgets(2));

    await tester.pump(undoWindow);
    await settle(tester);
    expect(deleteAddress.calls, isEmpty);

    await teardownApp(tester);
  });

  testWidgets('a refused delete brings the row back with the reason', (
    tester,
  ) async {
    deleteAddress.result = const Left(
      ServerFailure('Try later', statusCode: 500),
    );
    await book.start();
    await pumpList(tester);

    await tester.tap(find.byTooltip('Delete').last);
    await settle(tester);
    await tester.tap(find.text('Confirm'));
    await settle(tester);
    expect(find.byType(AddressRowTile), findsOneWidget);

    await tester.pump(undoWindow);
    await settle(tester);
    expect(deleteAddress.calls, hasLength(1));
    expect(find.byType(AddressRowTile), findsNWidgets(2));
    expect(find.text('Try later'), findsOneWidget);

    await teardownApp(tester);
  });

  testWidgets('a delete refused after the customer left the list is still '
      'told (the row is back in the book)', (tester) async {
    deleteAddress.result = const Left(
      ServerFailure('Try later', statusCode: 500),
    );
    await book.start();
    final router = await pumpList(tester);

    await tester.tap(find.byTooltip('Delete').last);
    await settle(tester);
    await tester.tap(find.text('Confirm'));
    await settle(tester);
    // Leaves while the Undo window is still open.
    router.pop();
    await settle(tester);
    expect(find.byType(AddressListPage), findsNothing);

    await tester.pump(undoWindow);
    await settle(tester);
    expect(deleteAddress.calls, hasLength(1));
    expect(book.state.book.addresses, hasLength(2));
    expect(find.text('Try later'), findsOneWidget);

    await teardownApp(tester);
  });

  group('the Undo window is the snack (review fixes I2 / I3)', () {
    Future<void> deleteWork(WidgetTester tester) async {
      await book.start();
      await pumpList(tester);
      await tester.tap(find.byTooltip('Delete').last);
      await settle(tester);
      await tester.tap(find.text('Confirm'));
      await tester.pump();
    }

    Animation<double>? snackAnimation(WidgetTester tester) =>
        tester.widget<SnackBar>(find.byType(SnackBar)).animation;

    testWidgets('nothing is sent while the Undo can be seen; the DELETE goes '
        'once the snack is gone', (tester) async {
      await deleteWork(tester);

      var frames = 0;
      while (find.text('Undo').evaluate().isNotEmpty) {
        expect(deleteAddress.calls, isEmpty, reason: 'Undo still on screen');
        await tester.pump(const Duration(milliseconds: 50));
        expect(++frames, lessThan(200), reason: 'the snack must go');
      }
      await settle(tester);
      expect(deleteAddress.calls.single.id, work.id);

      await teardownApp(tester);
    });

    testWidgets('an Undo tapped while the snack leaves still brings the row '
        'back, and nothing is sent', (tester) async {
      await deleteWork(tester);

      var frames = 0;
      while (snackAnimation(tester)?.status != AnimationStatus.reverse) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(++frames, lessThan(400), reason: 'the snack must start to go');
      }
      await tester.pump(const Duration(milliseconds: 16));
      await tester.tap(find.text('Undo'), warnIfMissed: false);
      await settle(tester);
      await tester.pump(const Duration(seconds: 10));
      await settle(tester);

      expect(find.byType(AddressRowTile), findsNWidgets(2));
      expect(deleteAddress.calls, isEmpty);

      await teardownApp(tester);
    });

    testWidgets('an Undo with nothing left to undo says so', (tester) async {
      await deleteWork(tester);
      await settle(tester);
      // The session ends under the snack: the delete is dropped, not sent.
      unawaited(book.stop());
      await tester.pump();

      await tester.tap(find.text('Undo'));
      await settle(tester);

      expect(
        find.text('Too late to undo: the address is already deleted'),
        findsOneWidget,
      );
      expect(deleteAddress.calls, isEmpty);

      await teardownApp(tester);
    });

    testWidgets('with a screen reader the Undo stays until used, and the '
        'DELETE waits for it', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(accessibleNavigation: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await deleteWork(tester);
      await settle(tester);

      await tester.pump(const Duration(seconds: 20));
      await settle(tester);
      expect(find.text('Undo'), findsOneWidget);
      expect(deleteAddress.calls, isEmpty);

      await tester.tap(find.text('Undo'));
      await settle(tester);
      expect(find.byType(AddressRowTile), findsNWidgets(2));
      expect(deleteAddress.calls, isEmpty);

      await teardownApp(tester);
    });
  });

  testWidgets('cancelling the delete dialog sends nothing', (tester) async {
    await book.start();
    await pumpList(tester);

    await tester.tap(find.byTooltip('Delete').first);
    await settle(tester);
    await tester.tap(find.text('Cancel'));
    await settle(tester);

    expect(deleteAddress.calls, isEmpty);
    expect(find.byType(AddressRowTile), findsNWidgets(2));

    await teardownApp(tester);
  });

  testWidgets('tapping a row pops the list with that address', (tester) async {
    await book.start();
    final picked = <Object?>[];
    await pumpList(tester, picked: picked);

    await tester.tap(
      find.text('Hawally, Block 4, Street 10, Building 120, Floor 3'),
    );
    await settle(tester);

    expect(picked.single, isA<HeroAddressEntity>());
    expect((picked.single! as HeroAddressEntity).id, work.id);
    expect(find.byType(AddressListPage), findsNothing);

    await teardownApp(tester);
  });
}
