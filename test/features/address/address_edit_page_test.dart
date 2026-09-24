// Edit-address page (edit mode opens straight on the full-height form) over a
// GoRouter, with the form cubit built on fake use cases through the real `sl`
// factory shape and the app-global AddressBookCubit on fakes.
import 'dart:async';
import 'dart:convert';

import 'package:dartz/dartz.dart' show Left, Right;
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
import 'package:jameia_mart/src/config/di/service_locator.dart';
import 'package:jameia_mart/src/config/routes/routes.dart';
import 'package:jameia_mart/src/config/theme/app_theme.dart';
import 'package:jameia_mart/src/core/domain/entities/jameia_address_entity.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/features/address/domain/entities/address_book.dart';
import 'package:jameia_mart/src/features/address/presentation/cubit/address_book_cubit.dart';
import 'package:jameia_mart/src/features/address/presentation/cubit/address_edit_cubit.dart';
import 'package:jameia_mart/src/features/address/presentation/pages/address_edit_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'address_test_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAddAddressUseCase addAddress;
  late FakeUpdateAddressUseCase updateAddress;
  late FakeGetAddressesUseCase getAddresses;
  late AddressBookCubit book;

  final original = address(n: 2, street: '11', floor: '2');

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    final enRaw = await rootBundle.loadString('assets/i18n/en.json');
    Localization.load(
      const Locale('en'),
      translations: Translations(json.decode(enRaw) as Map<String, dynamic>),
    );
  });

  setUp(() async {
    addAddress = FakeAddAddressUseCase(Right(address(n: 9)));
    updateAddress = FakeUpdateAddressUseCase(
      Right(address(n: 2, street: '15', floor: '2')),
    );
    getAddresses = FakeGetAddressesUseCase(
      Right(AddressBook.of([address(n: 1, isDefault: true), original])),
    );
    book = AddressBookCubit(
      getCached: FakeGetCachedAddressesUseCase(),
      getAddresses: getAddresses,
      updateAddress: updateAddress,
      deleteAddress: FakeDeleteAddressUseCase(),
      saveCache: FakeSaveCachedAddressesUseCase(),
      clearCache: FakeClearCachedAddressesUseCase(),
    );
    await book.start(customerId: 'aaaaaaaaaaaaaaaaaaaaaaaa');
    if (sl.isRegistered<AddressEditCubit>()) sl.unregister<AddressEditCubit>();
    sl.registerFactoryParam<AddressEditCubit, JameiaAddressEntity?, bool?>(
      (edited, isFirstAddress) => AddressEditCubit(
        addAddress: addAddress,
        updateAddress: updateAddress,
        original: edited,
        isFirstAddress: isFirstAddress ?? false,
      ),
    );
  });

  tearDown(() async {
    await book.close();
    sl.unregister<AddressEditCubit>();
  });

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// A launcher pushes the edit page (so it can pop back with the result).
  Future<GoRouter> pumpEdit(
    WidgetTester tester, {
    List<Object?>? popped,
  }) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () async {
                final result = await context.push<Object?>(
                  Routes.addressEdit,
                  extra: original,
                );
                popped?.add(result);
              },
              child: const Text('open'),
            ),
          ),
        ),
        GoRoute(
          path: Routes.addressEdit,
          builder: (_, state) => AddressEditPage(
            address: state.extra is JameiaAddressEntity
                ? state.extra! as JameiaAddressEntity
                : null,
          ),
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
    expect(find.byType(AddressEditPage), findsOneWidget);
    return router;
  }

  /// The form list builds lazily: scroll the CTA into existence, then tap it.
  Future<void> tapSave(WidgetTester tester) async {
    final save = find.text('Save address');
    await tester.dragUntilVisible(
      save,
      find.byType(ListView).last,
      const Offset(0, -300),
    );
    await tester.pump();
    await tester.tap(save);
    await settle(tester);
  }

  Future<void> teardownApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  }

  testWidgets(
    'edit mode opens on the full-height form, seeded from the entity',
    (tester) async {
      await pumpEdit(tester);

      expect(find.text('Edit address'), findsOneWidget);
      expect(find.widgetWithText(TextField, '11'), findsOneWidget);
      expect(find.widgetWithText(TextField, '50001122'), findsOneWidget);

      await teardownApp(tester);
    },
  );

  testWidgets('saving PATCHes the change, updates the book and pops with it', (
    tester,
  ) async {
    final popped = <Object?>[];
    await pumpEdit(tester, popped: popped);

    await tester.enterText(find.widgetWithText(TextField, '11'), '15');
    await tester.pump();
    await tapSave(tester);

    expect(updateAddress.calls.single.id, original.id);
    expect(updateAddress.calls.single.update.street, '15');
    expect(updateAddress.calls.single.update.floor, isNull);
    expect(book.state.book.byId(original.id)?.street, '15');
    expect((popped.single! as JameiaAddressEntity).street, '15');
    expect(find.text('Address saved'), findsOneWidget);

    await teardownApp(tester);
  });

  testWidgets('an invalid form shows inline errors and sends nothing', (
    tester,
  ) async {
    await pumpEdit(tester);

    await tester.enterText(find.widgetWithText(TextField, '11'), '');
    await tester.pump();
    await tapSave(tester);

    expect(updateAddress.calls, isEmpty);
    expect(find.text('Please fix the highlighted fields'), findsOneWidget);
    // The emptied street field scrolled away while reaching the CTA.
    await tester.dragUntilVisible(
      find.text('This field is required'),
      find.byType(ListView).last,
      const Offset(0, 300),
    );
    expect(find.text('This field is required'), findsOneWidget);
    expect(find.byType(AddressEditPage), findsOneWidget);

    await teardownApp(tester);
  });

  testWidgets('an address deleted elsewhere (404): message, book refreshed, '
      'form closed', (tester) async {
    updateAddress.result = const Left(
      ServerFailure(
        'Address not found',
        statusCode: 404,
        code: 'RESOURCE_NOT_FOUND',
      ),
    );
    await pumpEdit(tester);
    final syncsBefore = getAddresses.calls;

    await tester.enterText(find.widgetWithText(TextField, '11'), '15');
    await tester.pump();
    await tapSave(tester);

    expect(find.text('Address not found'), findsOneWidget);
    expect(getAddresses.calls, syncsBefore + 1);
    expect(find.byType(AddressEditPage), findsNothing);

    await teardownApp(tester);
  });

  testWidgets('back is blocked while the save is in flight', (tester) async {
    final gate = Completer<void>();
    updateAddress.gate = gate;
    await pumpEdit(tester);

    await tester.enterText(find.widgetWithText(TextField, '11'), '15');
    await tester.pump();
    await tapSave(tester);

    final router = GoRouter.of(tester.element(find.byType(AddressEditPage)));
    await router.routerDelegate.popRoute();
    await settle(tester);
    expect(find.byType(AddressEditPage), findsOneWidget);

    gate.complete();
    await settle(tester);
    expect(find.byType(AddressEditPage), findsNothing);

    await teardownApp(tester);
  });
}
