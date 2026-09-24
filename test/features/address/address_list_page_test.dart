// "My addresses" over a GoRouter with the app-global AddressBookCubit built on
// fake use cases: the screen faces (loaded, empty, signed-out, error), delete
// with confirmation, and the picker pop.
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
import 'package:jameia_mart/src/config/routes/routes.dart';
import 'package:jameia_mart/src/config/theme/app_theme.dart';
import 'package:jameia_mart/src/core/domain/entities/jameia_address_entity.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/features/address/domain/entities/address_book.dart';
import 'package:jameia_mart/src/features/address/presentation/cubit/address_book_cubit.dart';
import 'package:jameia_mart/src/features/address/presentation/pages/address_list_page.dart';
import 'package:jameia_mart/src/features/address/presentation/widgets/address_list/address_row_tile.dart';
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

    await tester.tap(find.text('Log in or sign up'));
    await settle(tester);
    expect(router.state.uri.path, Routes.login);

    await teardownApp(tester);
  });

  testWidgets('offline with nothing cached: error with retry', (tester) async {
    getAddresses.result = const Left(NetworkFailure());
    await pumpList(tester);

    expect(
      find.text('No internet connection. Check your network and try again.'),
      findsOneWidget,
    );
    getAddresses.result = Right(AddressBook.of([home]));
    await tester.tap(find.text('Retry'));
    await settle(tester);
    expect(find.byType(AddressRowTile), findsOneWidget);

    await teardownApp(tester);
  });

  testWidgets('delete asks first, waits for the server, removes the row', (
    tester,
  ) async {
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

    expect(deleteAddress.calls.single.id, work.id);
    expect(find.byType(AddressRowTile), findsOneWidget);
    expect(find.text('Address deleted'), findsOneWidget);

    await teardownApp(tester);
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

    expect(picked.single, isA<JameiaAddressEntity>());
    expect((picked.single! as JameiaAddressEntity).id, work.id);
    expect(find.byType(AddressListPage), findsNothing);

    await teardownApp(tester);
  });
}
