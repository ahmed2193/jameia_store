// The address page over a GoRouter — a new address starts on the map picker,
// an edited one on the form — with the form and picker cubits built on fake
// use cases through the real `sl` factory shapes and the app-global
// AddressBookCubit on fakes.
import 'dart:async';
import 'dart:convert';

import 'package:bloc_test/bloc_test.dart';
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
import 'package:hero_mart/src/config/di/service_locator.dart';
import 'package:hero_mart/src/config/routes/routes.dart';
import 'package:hero_mart/src/config/theme/app_theme.dart';
import 'package:hero_mart/src/core/design/hero_icons.dart';
import 'package:hero_mart/src/core/domain/entities/auth_customer_entity.dart';
import 'package:hero_mart/src/core/domain/entities/hero_address_entity.dart';
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/core/motion/motion.dart';
import 'package:hero_mart/src/core/responsive/breakpoints.dart';
import 'package:hero_mart/src/core/widgets/app_button.dart';
import 'package:hero_mart/src/core/widgets/hero_close_button.dart';
import 'package:hero_mart/src/core/widgets/hero_map_button.dart';
import 'package:hero_mart/src/core/widgets/loader_done_mark.dart';
import 'package:hero_mart/src/features/address/domain/entities/address_book.dart';
import 'package:hero_mart/src/features/address/domain/entities/device_location.dart';
import 'package:hero_mart/src/features/address/domain/entities/new_address_seed.dart';
import 'package:hero_mart/src/features/address/domain/entities/pinned_place.dart';
import 'package:hero_mart/src/features/address/presentation/cubit/address_book_cubit.dart';
import 'package:hero_mart/src/features/address/presentation/cubit/address_edit_cubit.dart';
import 'package:hero_mart/src/features/address/presentation/cubit/address_picker_cubit.dart';
import 'package:hero_mart/src/features/address/presentation/cubit/address_picker_state.dart';
import 'package:hero_mart/src/features/address/presentation/pages/address_edit_page.dart';
import 'package:hero_mart/src/features/auth/presentation/cubit/auth_session_cubit.dart';
import 'package:hero_mart/src/features/auth/presentation/cubit/auth_session_state.dart';
import 'package:hero_mart/src/features/address/presentation/widgets/address_edit/address_details_stage.dart';
import 'package:hero_mart/src/features/address/presentation/widgets/address_edit/address_map_stage.dart';
import 'package:hero_mart/src/features/address/presentation/widgets/address_edit/address_pin_preview.dart';
import 'package:hero_mart/src/features/address/presentation/widgets/address_edit/address_search_pill.dart';
import 'package:hero_mart/src/features/address/presentation/widgets/address_edit/building_type_sheet.dart';
import 'package:hero_mart/src/features/address/presentation/widgets/address_edit/label_chip.dart';
import 'package:hero_mart/src/features/address/presentation/widgets/address_edit/picker_pin_mark.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'address_picker_test_fakes.dart';
import 'address_test_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAddAddressUseCase addAddress;
  late FakeUpdateAddressUseCase updateAddress;
  late FakeGetAddressesUseCase getAddresses;
  late AddressBookCubit book;
  late PickerFakes picker;
  late AuthSessionCubit session;

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
    picker = PickerFakes()
      ..resolvePin.answer = (point) => PinnedPlace(
        location: point,
        area: 'Salmiya',
        block: '10',
        street: 'Salem Al Mubarak St',
      );
    if (sl.isRegistered<AddressPickerCubit>()) {
      sl.unregister<AddressPickerCubit>();
    }
    sl.registerFactoryParam<AddressPickerCubit, PinnedPlace?, void>(
      (pinned, _) => picker.cubit(pinned: pinned),
    );
    if (sl.isRegistered<AddressEditCubit>()) sl.unregister<AddressEditCubit>();
    sl.registerFactoryParam<
      AddressEditCubit,
      HeroAddressEntity?,
      NewAddressSeed?
    >(
      (edited, seed) => AddressEditCubit(
        addAddress: addAddress,
        updateAddress: updateAddress,
        original: edited,
        seed: seed ?? const NewAddressSeed(),
      ),
    );
    session = _MockAuthSessionCubit();
    whenListen(
      session,
      const Stream<AuthSessionState>.empty(),
      initialState: const AuthSessionState(
        status: AuthSessionStatus.signedIn,
        customer: AuthCustomerEntity(id: 'c1', phone: '+96599887766'),
      ),
    );
  });

  tearDown(() async {
    await book.close();
    sl
      ..unregister<AddressEditCubit>()
      ..unregister<AddressPickerCubit>();
  });

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// A launcher pushes the address page (so it can pop back with the
  /// result): on [original], or on a new address when [edit] is false.
  Future<GoRouter> pumpEdit(
    WidgetTester tester, {
    List<Object?>? popped,
    bool edit = true,
    HeroAddressEntity? editing,
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
                  extra: edit ? editing ?? original : null,
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
            address: state.extra is HeroAddressEntity
                ? state.extra! as HeroAddressEntity
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
        child: MultiBlocProvider(
          providers: [
            BlocProvider<AddressBookCubit>.value(value: book),
            BlocProvider<AuthSessionCubit>.value(value: session),
          ],
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

  /// The back button floating over the map.
  Finder mapBack() => find.byWidgetPredicate(
    (widget) => widget is HeroMapButton && widget.icon == HeroIcons.back,
  );

  /// The scrolling list of the form.
  Finder formList() => find
      .descendant(
        of: find.byType(AddressDetailsStage),
        matching: find.byType(Scrollable),
      )
      .first;

  /// Save sits in the bar pinned under the form.
  Future<void> tapSave(WidgetTester tester) async {
    await tester.tap(find.text('Save address'));
    await settle(tester);
  }

  Future<void> teardownApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  }

  testWidgets('edit mode opens on the form, seeded from the entity; its '
      'building type is read from what it stores', (tester) async {
    await pumpEdit(tester);

    expect(find.text('Edit address'), findsOneWidget);
    expect(find.byType(AddressDetailsStage), findsOneWidget);
    expect(find.widgetWithText(TextField, '11'), findsOneWidget);
    // A floor and no flat: an apartment, so the flat number is asked.
    expect(find.text('Apt. number (Optional)'), findsOneWidget);
    // The map waits under the form, at the saved pin, reading nothing.
    expect(picker.resolvePin.calls, isEmpty);
    final phone = find.widgetWithText(TextField, '50001122');
    await tester.scrollUntilVisible(phone, 200, scrollable: formList());
    expect(phone, findsOneWidget);

    await teardownApp(tester);
  });

  testWidgets('a new address starts on the map; Confirm asks the kind of '
      'place once, then the form comes up', (tester) async {
    await pumpEdit(tester, edit: false);

    expect(find.byType(AddressMapStage), findsOneWidget);
    expect(find.byType(AddressDetailsStage), findsNothing);
    expect(find.text('Search address'), findsOneWidget);

    await tester.tap(find.text('Confirm address'));
    await settle(tester);
    expect(find.byType(BuildingTypeSheet), findsOneWidget);
    await tester.tap(find.text('House'));
    await settle(tester);

    expect(find.byType(AddressDetailsStage), findsOneWidget);
    expect(find.text('New address'), findsOneWidget);
    // A house: no floor or flat to ask for.
    expect(find.text('Floor (Optional)'), findsNothing);

    // The courier calls the number the customer signed in with.
    final phone = find.widgetWithText(TextField, '99887766');
    await tester.scrollUntilVisible(phone, 200, scrollable: formList());
    expect(phone, findsOneWidget);

    // Back from the form returns to the map; Confirm skips the question.
    await tester.tap(find.byTooltip('Back').last);
    await settle(tester);
    expect(find.byType(AddressDetailsStage), findsNothing);
    await tester.tap(find.text('Confirm address'));
    await settle(tester);
    expect(find.byType(BuildingTypeSheet), findsNothing);
    expect(find.byType(AddressDetailsStage), findsOneWidget);

    await teardownApp(tester);
  });

  testWidgets('a saved address with no pin opens on the map, on the '
      'customer, close up; Confirm brings its form back', (tester) async {
    picker.locateDevice.result = const Right(DeviceLocation.found(jahra));
    await pumpEdit(
      tester,
      editing: address(n: 2, street: '11', location: null),
    );

    expect(find.byType(AddressMapStage), findsOneWidget);
    expect(find.byType(AddressDetailsStage), findsNothing);
    final state = tester
        .element(find.byType(AddressMapStage))
        .read<AddressPickerCubit>()
        .state;
    expect(picker.locateDevice.calls, isNotEmpty);
    expect(state.opened, isTrue);
    expect(state.target, jahra);
    expect(state.openingZoom, AddressPickerState.doorZoom);

    // Its kind of place is known: Confirm goes straight to its form.
    await tester.tap(find.text('Confirm address'));
    await settle(tester);
    expect(find.byType(BuildingTypeSheet), findsNothing);
    expect(find.byType(AddressDetailsStage), findsOneWidget);
    expect(find.text('Edit address'), findsOneWidget);
    expect(find.widgetWithText(TextField, '11'), findsOneWidget);

    await teardownApp(tester);
  });

  testWidgets('the kind-of-place panel rises over the map, Glovo style: no '
      'close button, the search steps aside; the map card shows the kind', (
    tester,
  ) async {
    await pumpEdit(tester, edit: false);
    await tester.tap(find.text('Confirm address'));
    await settle(tester);

    expect(find.text('Choose your building type'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(BuildingTypeSheet),
        matching: find.byType(HeroCloseButton),
      ),
      findsNothing,
    );
    final pill = find
        .ancestor(
          of: find.byType(AddressSearchPill),
          matching: find.byType(AnimatedOpacity),
        )
        .first;
    expect(tester.widget<AnimatedOpacity>(pill).opacity, 0);

    await tester.tap(find.text('Office'));
    await settle(tester);

    final pin = find.descendant(
      of: find.byType(AddressPinPreview),
      matching: find.byType(PickerPinMark),
    );
    await tester.scrollUntilVisible(pin, 200, scrollable: formList());
    expect(tester.widget<PickerPinMark>(pin).glyph, HeroIcons.office);

    await teardownApp(tester);
  });

  testWidgets('back from the map of a new address leaves the page', (
    tester,
  ) async {
    final popped = <Object?>[];
    await pumpEdit(tester, edit: false, popped: popped);

    await tester.tap(mapBack());
    await settle(tester);

    expect(find.byType(AddressEditPage), findsNothing);
    expect(popped, [null]);

    await teardownApp(tester);
  });

  testWidgets('a dismissed kind-of-place question stays on the map', (
    tester,
  ) async {
    await pumpEdit(tester, edit: false);
    await tester.tap(find.text('Confirm address'));
    await settle(tester);
    expect(find.byType(BuildingTypeSheet), findsOneWidget);

    await tester.tapAt(const Offset(20, 20)); // the scrim
    await settle(tester);

    expect(find.byType(BuildingTypeSheet), findsNothing);
    expect(find.byType(AddressDetailsStage), findsNothing);
    expect(find.byType(AddressMapStage), findsOneWidget);

    await teardownApp(tester);
  });

  testWidgets('Adjust pin brings the map up; back returns to the form with '
      'what was typed', (tester) async {
    await pumpEdit(tester);
    await tester.enterText(find.widgetWithText(TextField, '11'), '15');
    await tester.pump();

    final adjust = find.text('Adjust pin');
    await tester.scrollUntilVisible(adjust, 200, scrollable: formList());
    await tester.pump();
    await tester.tap(adjust);
    await settle(tester);
    expect(find.byType(AddressDetailsStage), findsNothing);
    expect(find.text('Confirm address'), findsOneWidget);

    await tester.tap(mapBack());
    await settle(tester);

    expect(find.byType(AddressEditPage), findsOneWidget);
    expect(find.byType(AddressDetailsStage), findsOneWidget);
    expect(find.widgetWithText(TextField, '15'), findsOneWidget);

    await teardownApp(tester);
  });

  testWidgets('Adjust pin, then Confirm without moving, keeps what was typed '
      'since', (tester) async {
    await pumpEdit(tester);
    await tester.enterText(find.widgetWithText(TextField, '11'), '15');
    await tester.pump();
    final adjust = find.text('Adjust pin');
    await tester.scrollUntilVisible(adjust, 200, scrollable: formList());
    await tester.pump();
    await tester.tap(adjust);
    await settle(tester);

    await tester.tap(find.text('Confirm address'));
    await settle(tester);

    expect(find.byType(AddressDetailsStage), findsOneWidget);
    expect(find.widgetWithText(TextField, '15'), findsOneWidget);
    expect(find.widgetWithText(TextField, '11'), findsNothing);

    await teardownApp(tester);
  });

  /// A new address whose pin the map has read at Salmiya.
  Future<AddressPickerCubit> pumpNewAtSalmiya(WidgetTester tester) async {
    await pumpEdit(tester, edit: false);
    final cubit = tester
        .element(find.byType(AddressMapStage))
        .read<AddressPickerCubit>();
    cubit.cameraIdle(salmiya);
    await settle(tester);
    return cubit;
  }

  testWidgets('back to the map of a new address, then Confirm on the same '
      'spot, keeps what was typed since', (tester) async {
    await pumpNewAtSalmiya(tester);
    expect(picker.resolvePin.calls, hasLength(1));
    await tester.tap(find.text('Confirm address'));
    await settle(tester);
    await tester.tap(find.text('House'));
    await settle(tester);
    final street = find.widgetWithText(TextField, 'Salem Al Mubarak St');
    expect(street, findsOneWidget);
    await tester.enterText(street, 'My street');
    await tester.pump();

    await tester.tap(find.byTooltip('Back').last);
    await settle(tester);
    expect(find.byType(AddressDetailsStage), findsNothing);
    await tester.tap(find.text('Confirm address'));
    await settle(tester);

    expect(find.widgetWithText(TextField, 'My street'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Salem Al Mubarak St'), findsNothing);

    await teardownApp(tester);
  });

  testWidgets('a double tap on Confirm asks the kind of place once; the '
      'search stays aside', (tester) async {
    await pumpNewAtSalmiya(tester);
    // Two taps reach the button before the first one is answered.
    final confirm = tester.widget<AppButton>(
      find.widgetWithText(AppButton, 'Confirm address'),
    );
    confirm.onPressed!();
    confirm.onPressed!();
    await settle(tester);

    expect(find.byType(BuildingTypeSheet), findsOneWidget);
    final pill = find
        .ancestor(
          of: find.byType(AddressSearchPill),
          matching: find.byType(AnimatedOpacity),
        )
        .first;
    expect(tester.widget<AnimatedOpacity>(pill).opacity, 0);

    await teardownApp(tester);
  });

  testWidgets('an address read after Confirm stopped waiting still fills '
      'the form', (tester) async {
    final gate = Completer<void>();
    picker.resolvePin.gate = gate;
    await pumpNewAtSalmiya(tester); // the read is on its way, held

    await tester.tap(find.text('Confirm address'));
    await tester.pump(AddressPickerCubit.confirmWait);
    await settle(tester);
    await tester.tap(find.text('House'));
    await settle(tester);
    expect(find.byType(AddressDetailsStage), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Salem Al Mubarak St'), findsNothing);

    gate.complete();
    await settle(tester);

    expect(
      find.widgetWithText(TextField, 'Salem Al Mubarak St'),
      findsOneWidget,
    );
    expect(find.widgetWithText(TextField, 'Salmiya'), findsOneWidget);

    await teardownApp(tester);
  });

  testWidgets('saving PATCHes the change, updates the book and pops with it', (
    tester,
  ) async {
    final popped = <Object?>[];
    await pumpEdit(tester, popped: popped);

    await tester.enterText(find.widgetWithText(TextField, '11'), '15');
    await tester.pump();
    await tapSave(tester);
    // The check draws and holds (SuccessBeat) before the page pops.
    await settle(tester);

    expect(updateAddress.calls.single.id, original.id);
    expect(updateAddress.calls.single.update.street, '15');
    expect(updateAddress.calls.single.update.floor, isNull);
    expect(book.state.book.byId(original.id)?.street, '15');
    expect((popped.single! as HeroAddressEntity).street, '15');
    expect(find.text('Address saved'), findsOneWidget);

    await teardownApp(tester);
  });

  testWidgets('B2-04: the saved check draws and holds, with a success '
      'haptic, before the page pops', (tester) async {
    final haptics = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          haptics.add(call.arguments as String);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final popped = <Object?>[];
    await pumpEdit(tester, popped: popped);
    await tester.enterText(find.widgetWithText(TextField, '11'), '15');
    await tester.pump();
    haptics.clear();
    await tester.tap(find.text('Save address'));
    await tester.pump();
    await tester.pump(AppMotion.page);
    await tester.pump(AppMotion.page);

    // Saved: the check is on screen and the page is still here.
    expect(find.byType(LoaderDoneMark), findsOneWidget);
    expect(popped, isEmpty);
    expect(haptics, contains('HapticFeedbackType.mediumImpact'));

    await settle(tester);
    expect(popped, hasLength(1));
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
      NotFoundFailure('Address not found', code: 'RESOURCE_NOT_FOUND'),
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

  testWidgets('Next walks the form field by field, never jumping to Save '
      '(a phone with the keyboard up)', (tester) async {
    // The emulator's phone: the Save bar rides the keyboard, level with
    // the half-hidden Building field.
    tester.view
      ..physicalSize = const Size(720, 1520)
      ..devicePixelRatio = 1.75;
    addTearDown(tester.view.reset);
    await pumpEdit(tester);
    await tester.tap(find.widgetWithText(TextField, '11'));
    await tester.pump();
    tester.view.viewInsets = const FakeViewPadding(bottom: 600);
    await settle(tester);

    await tester.testTextInput.receiveAction(TextInputAction.next);
    await settle(tester);

    final building = tester.widget<TextField>(
      find.widgetWithText(TextField, '5'),
    );
    expect(building.focusNode?.hasFocus, isTrue);

    await teardownApp(tester);
  });

  testWidgets('on a tablet the form reads in one column', (tester) async {
    tester.view
      ..physicalSize = const Size(1280, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpEdit(tester);

    expect(
      tester.getSize(formList()).width,
      lessThanOrEqualTo(Breakpoints.contentMaxWidth),
    );

    await teardownApp(tester);
  });

  testWidgets('a label chip says it is a button, and which one is picked', (
    tester,
  ) async {
    await pumpEdit(tester);
    final work = find.text('Work');
    await tester.scrollUntilVisible(work, 200, scrollable: formList());
    await tester.tap(work);
    await tester.pump();

    final chip = find.ancestor(of: work, matching: find.byType(LabelChip));
    expect(
      tester.getSemantics(chip),
      isSemantics(isButton: true, isSelected: true, label: 'Work'),
    );

    await teardownApp(tester);
  });

  testWidgets('the label chips hug their words', (tester) async {
    await pumpEdit(tester);
    final home = find.widgetWithText(LabelChip, 'Home');
    await tester.scrollUntilVisible(home, 200, scrollable: formList());

    final form = tester.getSize(find.byType(AddressDetailsStage)).width;
    expect(tester.getSize(home).width, lessThan(form / 2));

    await teardownApp(tester);
  });

  testWidgets('Save drops the keyboard, so a refused form shows all of its '
      'errors', (tester) async {
    await pumpEdit(tester);
    await tester.enterText(find.widgetWithText(TextField, '7'), '');
    await tester.pump();
    expect(tester.testTextInput.isVisible, isTrue);

    await tapSave(tester);

    expect(tester.testTextInput.isVisible, isFalse);
    expect(find.text('Please fix the highlighted fields'), findsOneWidget);

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

class _MockAuthSessionCubit extends MockCubit<AuthSessionState>
    implements AuthSessionCubit {}
