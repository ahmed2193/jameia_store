// The checkout sheet shell: a sheet is a new route, so it reaches the
// page-scoped CheckoutCubit only when the opener passes it on
// (`CheckoutSheetFrame.show(checkout:)`); the strip around the floating
// close disc closes the sheet like the disc does.
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hero_mart/src/config/theme/app_colors.dart';
import 'package:hero_mart/src/config/theme/app_spacing.dart';
import 'package:hero_mart/src/core/widgets/hero_close_button.dart';
import 'package:hero_mart/src/core/widgets/sticker_text.dart';
import 'package:hero_mart/src/features/cart/domain/entities/cart_snapshot.dart';
import 'package:hero_mart/src/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:hero_mart/src/features/checkout/presentation/cubit/checkout_cubit.dart';
import 'package:hero_mart/src/features/checkout/presentation/widgets/checkout/checkout_info_sheet.dart';
import 'package:hero_mart/src/features/checkout/presentation/widgets/checkout/checkout_ink_theme.dart';
import 'package:hero_mart/src/features/checkout/presentation/widgets/checkout/checkout_sheet_frame.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../cart/fake_cart_repository.dart';
import 'checkout_test_harness.dart';
import 'fake_checkout_repository.dart';

/// Opens [_NoteSheet], passing the page's cubit on when [passCheckout].
class _Opener extends StatelessWidget {
  const _Opener({required this.passCheckout});

  final bool passCheckout;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: () => CheckoutSheetFrame.show<void>(
      context,
      checkout: passCheckout ? context.read<CheckoutCubit>() : null,
      builder: (_) => const _NoteSheet(),
    ),
    child: const Text('open'),
  );
}

/// A sheet that reads the page's cubit while it builds.
class _NoteSheet extends StatelessWidget {
  const _NoteSheet();

  @override
  Widget build(BuildContext context) {
    final notes = context.select<CheckoutCubit, String>(
      (cubit) => cubit.state.draft.notes,
    );
    return CheckoutSheetFrame(
      title: 'Note',
      footer: TextButton(
        onPressed: () {
          context.read<CheckoutCubit>().setNotes('ring the bell');
          context.pop();
        },
        child: const Text('save'),
      ),
      child: Text('note: $notes'),
    );
  }
}

/// Opens an info sheet.
class _InfoOpener extends StatelessWidget {
  const _InfoOpener();

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: () => CheckoutInfoSheet.show(
      context,
      title: 'How we estimate delivery',
      body: List<String>.filled(
        12,
        'Times can vary by area and branch.',
      ).join(' '),
    ),
    child: const Text('info'),
  );
}

void main() {
  late FakeCartRepository cartRepository;
  late CartCubit cart;
  late CheckoutCubit checkout;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  setUp(() {
    cartRepository = FakeCartRepository()
      ..snapshot = const CartSnapshot(isRestored: true);
    cart = buildCartCubit(cartRepository);
    checkout = buildCheckoutCubit(FakeCheckoutRepository());
  });

  tearDown(() async {
    await checkout.close();
    await cart.close();
    await cartRepository.dispose();
  });

  testWidgets('a sheet opened with checkout: reaches the page cubit', (
    tester,
  ) async {
    await pumpCheckoutSection(
      tester,
      const _Opener(passCheckout: true),
      cart: cart,
      checkout: checkout,
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Note'), findsOneWidget);
    expect(find.text('note: '), findsOneWidget);

    await tester.tap(find.text('save'));
    await tester.pumpAndSettle();

    expect(checkout.state.draft.notes, 'ring the bell');
    expect(find.byType(CheckoutSheetFrame), findsNothing);
  });

  testWidgets('without checkout: the sheet cannot find the page cubit', (
    tester,
  ) async {
    await pumpCheckoutSection(
      tester,
      const _Opener(passCheckout: false),
      cart: cart,
      checkout: checkout,
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // The rule this documents: the page's providers live inside its route,
    // and a sheet is another route.
    expect(tester.takeException(), isA<ProviderNotFoundException>());
  });

  testWidgets('the strip beside the close disc closes the sheet', (
    tester,
  ) async {
    await pumpCheckoutSection(
      tester,
      const _Opener(passCheckout: true),
      cart: cart,
      checkout: checkout,
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final frame = tester.getTopLeft(find.byType(CheckoutSheetFrame));
    // The ✕ sits in the 30 dp disc at the start of the strip.
    final cross = tester.getCenter(find.byType(HeroCloseButton));
    expect(
      cross.dx - frame.dx,
      closeTo(AppSpacing.s16 + CheckoutSheetFrame.discSize / 2, 0.5),
    );
    // Far from the disc, inside the strip above the card.
    await tester.tapAt(frame + const Offset(240, 10));
    await tester.pumpAndSettle();

    expect(find.byType(CheckoutSheetFrame), findsNothing);
    expect(checkout.state.draft.notes, isEmpty);
  });

  testWidgets('the ✕ in the disc closes the sheet', (tester) async {
    await pumpCheckoutSection(
      tester,
      const _Opener(passCheckout: true),
      cart: cart,
      checkout: checkout,
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(HeroCloseButton));
    await tester.pumpAndSettle();

    expect(find.byType(CheckoutSheetFrame), findsNothing);
  });

  testWidgets('an info sheet fits a 360 × 800 phone at 1.3× and "Got it" '
      'closes it', (tester) async {
    await pumpCheckoutSection(
      tester,
      const _InfoOpener(),
      cart: cart,
      checkout: checkout,
      size: const Size(360, 800),
      textScale: 1.3,
    );
    await tester.tap(find.text('info'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('How we estimate delivery'), findsOneWidget);
    // The footer label is a sticker.
    expect(
      find.descendant(
        of: find.byType(StickerText),
        matching: find.text('Got it'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(find.byType(CheckoutInfoSheet), findsNothing);
  });

  testWidgets('every checkout sheet answers a touch with the flat brand '
      'press tint, not the Material splash', (tester) async {
    await pumpCheckoutSection(
      tester,
      const Column(children: [_Opener(passCheckout: true), _InfoOpener()]),
      cart: cart,
      checkout: checkout,
    );

    void expectInkTheme(Finder sheet) {
      final theme = Theme.of(tester.element(sheet));
      expect(theme.splashFactory, same(NoSplash.splashFactory));
      expect(theme.highlightColor, AppColors.pressTint);
      expect(theme.splashColor, AppColors.scrimTransparent);
    }

    // A sheet that reads the page's cubit…
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expectInkTheme(find.byType(CheckoutSheetFrame));
    await tester.tap(find.byType(HeroCloseButton));
    await tester.pumpAndSettle();

    // …and one that does not.
    await tester.tap(find.text('info'));
    await tester.pumpAndSettle();
    expectInkTheme(find.byType(CheckoutSheetFrame));
    expect(
      find.ancestor(
        of: find.byType(CheckoutSheetFrame),
        matching: find.byType(CheckoutInkTheme),
      ),
      findsOneWidget,
    );

    // The page itself keeps the app theme.
    expect(
      Theme.of(tester.element(find.text('open'))).splashFactory,
      isNot(same(NoSplash.splashFactory)),
    );
  });
}
