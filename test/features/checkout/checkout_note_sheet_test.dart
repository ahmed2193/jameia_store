// "Additional options" and "Good to know": the note for the store lives in a
// sheet (the page has no text field). Typing changes nothing on the page;
// "Save" — or any other way out of the sheet — writes the note to the draft
// once. The sheet is its own route and still reaches the page's cubit. The
// "Good to know" rows open the store's FAQ and terms pages.
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:jameia_mart/src/config/routes/routes.dart';
import 'package:jameia_mart/src/features/cart/domain/entities/cart_snapshot.dart';
import 'package:jameia_mart/src/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:jameia_mart/src/features/checkout/presentation/cubit/checkout_cubit.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_info_section.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_note_row.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_note_sheet.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_options_section.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_sheet_frame.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../cart/fake_cart_repository.dart';
import 'checkout_test_harness.dart';
import 'fake_checkout_repository.dart';

void main() {
  late FakeCartRepository cartRepository;
  late CartCubit cartCubit;
  late CheckoutCubit checkoutCubit;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  setUp(() {
    cartRepository = FakeCartRepository()
      ..snapshot = const CartSnapshot(isRestored: true);
    cartCubit = buildCartCubit(cartRepository);
    checkoutCubit = buildCheckoutCubit(FakeCheckoutRepository());
  });

  tearDown(() async {
    await checkoutCubit.close();
    await cartCubit.close();
    await cartRepository.dispose();
  });

  Future<void> pump(WidgetTester tester) async {
    await checkoutCubit.start(defaultAddressId: 'a1');
    await pumpCheckoutSection(
      tester,
      const CheckoutOptionsSection(),
      cart: cartCubit,
      checkout: checkoutCubit,
    );
  }

  Future<void> openSheet(WidgetTester tester) async {
    await tester.tap(find.byType(CheckoutNoteRow));
    await tester.pumpAndSettle();
    expect(find.byType(CheckoutNoteSheet), findsOneWidget);
  }

  Finder inSheet(Finder matching) =>
      find.descendant(of: find.byType(CheckoutSheetFrame), matching: matching);

  group('the note', () {
    testWidgets('the row prompts for a note; the page has no text field', (
      tester,
    ) async {
      await pump(tester);

      expect(find.text('Additional options'), findsOneWidget);
      expect(find.text('Notes for the store'), findsOneWidget);
      expect(find.text('Add instructions for your order'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('typing changes nothing; Save writes the note and closes', (
      tester,
    ) async {
      await pump(tester);
      await openSheet(tester);

      await tester.enterText(inSheet(find.byType(TextField)), 'ring the bell');
      await tester.pump();
      expect(checkoutCubit.state.draft.notes, isEmpty);

      await tester.tap(inSheet(find.text('Save')));
      await tester.pumpAndSettle();

      expect(find.byType(CheckoutNoteSheet), findsNothing);
      expect(checkoutCubit.state.draft.notes, 'ring the bell');
      // The row now shows the note instead of the prompt.
      expect(find.text('ring the bell'), findsOneWidget);
      expect(find.text('Add instructions for your order'), findsNothing);
    });

    testWidgets('a swipe down keeps what was typed', (tester) async {
      await pump(tester);
      await openSheet(tester);

      await tester.enterText(
        inSheet(find.byType(TextField)),
        'leave it at the door',
      );
      await tester.pump();
      await tester.fling(
        inSheet(find.text('Notes for the store')),
        const Offset(0, 600),
        2000,
      );
      await tester.pumpAndSettle();

      expect(find.byType(CheckoutNoteSheet), findsNothing);
      expect(checkoutCubit.state.draft.notes, 'leave it at the door');
    });

    testWidgets('a tap on the scrim keeps it too', (tester) async {
      await pump(tester);
      await openSheet(tester);

      await tester.enterText(inSheet(find.byType(TextField)), 'call me');
      await tester.pump();
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      expect(find.byType(CheckoutNoteSheet), findsNothing);
      expect(checkoutCubit.state.draft.notes, 'call me');
    });

    testWidgets('the sheet opens on the saved note — it reaches the page '
        'cubit from its own route', (tester) async {
      checkoutCubit.setNotes('no onions');
      await pump(tester);
      await openSheet(tester);

      final field = tester.widget<TextField>(inSheet(find.byType(TextField)));
      expect(field.controller!.text, 'no onions');
      expect(field.maxLength, 256);

      // Closing without a change writes nothing new.
      final before = checkoutCubit.state;
      await tester.tap(inSheet(find.text('Save')));
      await tester.pumpAndSettle();
      expect(identical(checkoutCubit.state, before), isTrue);
    });
  });

  testWidgets('Good to know opens the FAQ and the terms pages', (tester) async {
    await checkoutCubit.start(defaultAddressId: 'a1');
    await pumpCheckoutSection(
      tester,
      const CheckoutInfoSection(),
      cart: cartCubit,
      checkout: checkoutCubit,
      extraRoutes: <RouteBase>[
        GoRoute(
          path: Routes.contentPage,
          builder: (_, state) => Scaffold(body: Text('page ${state.extra}')),
        ),
      ],
    );

    expect(find.text('Good to know'), findsOneWidget);
    await tester.tap(find.text('FAQ'));
    await tester.pumpAndSettle();
    expect(find.text('page faq'), findsOneWidget);

    GoRouter.of(tester.element(find.text('page faq'))).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Terms of service'));
    await tester.pumpAndSettle();
    expect(find.text('page terms'), findsOneWidget);
  });
}
