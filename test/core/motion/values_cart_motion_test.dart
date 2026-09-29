// I5 — values, steppers, badges, add-to-cart (docs/motion §9.4 #2-#4;
// Appendix D B1-01, B2-01, B1-11, BX-09, B2-07):
// - numbers roll with the direction of the change and never on first build;
// - a count badge is static on mount, bumps once per change, fades at zero
//   instead of cutting, and a rise waits for the add-to-cart flight to LAND;
// - reduced motion: no flight, no bump — the badge tints and changes at once;
// - one add gesture: a click, a flight (at most 3, only to a cart on
//   screen), then the cart change; the "Add" → stepper swap is one
//   PopSwitcher everywhere.
import 'dart:async';
import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/config/theme/app_colors.dart';
import 'package:hero_mart/src/core/domain/entities/catalog_product_entity.dart';
import 'package:hero_mart/src/core/motion/change_bump.dart';
import 'package:hero_mart/src/core/motion/fly_to_cart.dart';
import 'package:hero_mart/src/core/motion/haptics.dart';
import 'package:hero_mart/src/core/motion/motion.dart';
import 'package:hero_mart/src/core/motion/pop_switcher.dart';
import 'package:hero_mart/src/core/motion/rolling_number.dart';
import 'package:hero_mart/src/core/motion/rolling_number_text.dart';
import 'package:hero_mart/src/core/widgets/catalog_cart_gestures.dart';
import 'package:hero_mart/src/core/widgets/catalog_pill_stepper.dart';
import 'package:hero_mart/src/core/widgets/catalog_step_button.dart';
import 'package:hero_mart/src/core/widgets/count_badge.dart';
import 'package:hero_mart/src/core/widgets/shelf_add_control.dart';
import 'package:hero_mart/src/features/product_details/presentation/widgets/pdp_cart_cta.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'rolling_test_finders.dart';

const String _click = 'HapticFeedbackType.selectionClick';
const String _light = 'HapticFeedbackType.lightImpact';
const String _medium = 'HapticFeedbackType.mediumImpact';

const Key _tintLayer = ValueKey<String>('tint-flash-layer');
const Key _thumb = ValueKey<String>('flying-thumb');

/// The reduced-motion tint while it washes over the badge.
final Finder _tint = find.descendant(
  of: find.byKey(_tintLayer),
  matching: find.byType(FadeTransition),
);

/// Past a flight's landing (a controller completes on the frame after).
const Duration _landed = Duration(milliseconds: 420);

const CatalogProductEntity _lemon = CatalogProductEntity(
  id: 'p2',
  slug: 'lemon',
  name: 'Lemon, 500g',
  priceFils: 500,
  stock: 5,
);

List<String?> _recordHaptics(WidgetTester tester) {
  final calls = <String?>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        calls.add(call.arguments as String?);
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
  return calls;
}

Widget _host(Widget child, {bool animationsOff = false}) => MaterialApp(
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: animationsOff),
      child: Scaffold(body: Center(child: child)),
    ),
  ),
);

/// iOS "Reduce Motion": reduced, but animations are not off.
void _reduceMotion(WidgetTester tester) {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(reduceMotion: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

/// The vertical offset (share of its height) of the slot showing [glyph].
double _slideOf(WidgetTester tester, String glyph) => tester
    .widget<SlideTransition>(
      find
          .ancestor(
            of: find.text(glyph),
            matching: find.byType(SlideTransition),
          )
          .first,
    )
    .position
    .value
    .dy;

/// The badge's "changed" bump.
double _bumpOf(WidgetTester tester) => tester
    .widget<ScaleTransition>(
      find
          .descendant(
            of: find.byType(ChangeBump),
            matching: find.byType(ScaleTransition),
          )
          .first,
    )
    .scale
    .value;

/// A cart icon (the flight target) and a product (the source) on one screen,
/// with a flight-synced badge showing [count].
class _CartScene extends StatefulWidget {
  const _CartScene({required this.count, this.coveredTarget = false});

  final ValueNotifier<int> count;
  final bool coveredTarget;

  static final GlobalKey target = GlobalKey();
  static final GlobalKey source = GlobalKey();

  @override
  State<_CartScene> createState() => _CartSceneState();
}

class _CartSceneState extends State<_CartScene> {
  @override
  void initState() {
    super.initState();
    FlyToCart.pushTarget(_CartScene.target);
  }

  @override
  void dispose() {
    FlyToCart.popTarget(_CartScene.target);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TickerMode(
          enabled: !widget.coveredTarget,
          child: SizedBox.square(key: _CartScene.target, dimension: 40),
        ),
        ValueListenableBuilder<int>(
          valueListenable: widget.count,
          builder: (context, count, _) => CountBadge(
            count: count,
            color: AppColors.primary,
            landsWithFlight: true,
          ),
        ),
        const SizedBox(height: 200),
        SizedBox.square(key: _CartScene.source, dimension: 40),
      ],
    );
  }
}

bool _launch(WidgetTester tester) => FlyToCart.fly(
  tester.element(find.byKey(_CartScene.source)),
  sourceKey: _CartScene.source,
  thumbnail: const SizedBox(key: _thumb),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    final enRaw = await rootBundle.loadString('assets/i18n/en.json');
    Localization.load(
      const Locale('en'),
      translations: Translations(json.decode(enRaw) as Map<String, dynamic>),
    );
  });

  setUp(Haptics.debugReset);

  group('RollingNumber family (B1-01)', () {
    testWidgets('static on the first build: no count-up from zero', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const RollingNumber(value: 340)));
      expect(tester.hasRunningAnimations, isFalse);
      expect(findRolled('340'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('rolls up for a rise and down for a drop', (tester) async {
      await tester.pumpWidget(_host(const RollingNumber(value: 1)));
      await tester.pumpWidget(_host(const RollingNumber(value: 2)));
      await tester.pump(AppMotion.medium ~/ 3);
      // The new digit comes up from below, the old one leaves above.
      expect(_slideOf(tester, '2'), greaterThan(0));
      expect(_slideOf(tester, '1'), lessThan(0));
      await tester.pumpAndSettle();

      await tester.pumpWidget(_host(const RollingNumber(value: 1)));
      await tester.pump(AppMotion.medium ~/ 3);
      // A drop: the new digit comes down from above.
      expect(_slideOf(tester, '1'), lessThan(0));
      expect(_slideOf(tester, '2'), greaterThan(0));
      await tester.pumpAndSettle();
      expect(find.text('2'), findsNothing);
    });

    testWidgets('reduced motion cross-fades in place; off swaps at once', (
      tester,
    ) async {
      _reduceMotion(tester);
      await tester.pumpWidget(_host(const RollingNumber(value: 1)));
      await tester.pumpWidget(_host(const RollingNumber(value: 2)));
      await tester.pump(AppMotion.fast ~/ 2);
      expect(find.text('1'), findsOneWidget, reason: 'fading out');
      expect(
        find.descendant(
          of: find.byType(RollingNumber),
          matching: find.byType(SlideTransition),
        ),
        findsNothing,
      );
      await tester.pump(AppMotion.fast);
      expect(find.text('1'), findsNothing);
    });

    testWidgets('a number inside a phrase: only the number rolls', (
      tester,
    ) async {
      String phrase(String n) => '$n pts';
      await tester.pumpWidget(
        _host(RollingNumberText(value: 320, text: phrase)),
      );
      expect(tester.hasRunningAnimations, isFalse);
      expect(find.bySemanticsLabel('320 pts'), findsOneWidget);

      await tester.pumpWidget(
        _host(RollingNumberText(value: 340, text: phrase)),
      );
      await tester.pump(AppMotion.medium ~/ 3);
      expect(_slideOf(tester, '4'), greaterThan(0));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('340 pts'), findsOneWidget);
      expect(findRolled('340 pts'), findsOneWidget);
    });
  });

  group('CountBadge (B1-11)', () {
    Widget badge(int count) =>
        _host(CountBadge(count: count, color: AppColors.primary));

    testWidgets('static on mount; one bump and a roll per change', (
      tester,
    ) async {
      await tester.pumpWidget(badge(3));
      expect(tester.hasRunningAnimations, isFalse);
      expect(_bumpOf(tester), 1);

      await tester.pumpWidget(badge(4));
      await tester.pump(const Duration(milliseconds: 40));
      expect(_bumpOf(tester), greaterThan(1));
      await tester.pumpAndSettle();
      expect(_bumpOf(tester), 1);
      expect(findRolled('4'), findsOneWidget);
    });

    testWidgets('pops in from zero, fades out at zero (never a cut)', (
      tester,
    ) async {
      await tester.pumpWidget(badge(0));
      expect(find.byType(ChangeBump), findsNothing);

      await tester.pumpWidget(badge(1));
      await tester.pump(const Duration(milliseconds: 16));
      final pop = tester.widget<PopSwitcher>(find.byType(PopSwitcher));
      expect(pop.stateKey, isTrue);
      await tester.pumpAndSettle();
      expect(findRolled('1'), findsOneWidget);

      await tester.pumpWidget(badge(0));
      await tester.pump(const Duration(milliseconds: 16));
      expect(findRolled('1'), findsOneWidget, reason: 'still fading out');
      await tester.pumpAndSettle();
      expect(findRolled('1'), findsNothing);
    });

    testWidgets('99+ above the cap', (tester) async {
      await tester.pumpWidget(badge(120));
      expect(findRolled('99+'), findsOneWidget);
    });

    testWidgets('a rise waits for the flight to land, then bumps', (
      tester,
    ) async {
      final count = ValueNotifier<int>(1);
      addTearDown(count.dispose);
      await tester.pumpWidget(_host(_CartScene(count: count)));

      expect(_launch(tester), isTrue);
      await tester.pump();
      expect(find.byKey(_thumb), findsOneWidget);
      count.value = 2;
      await tester.pump(const Duration(milliseconds: 100));
      expect(findRolled('1'), findsOneWidget, reason: 'still in the air');
      expect(_bumpOf(tester), 1);

      await tester.pump(AppMotion.slow);
      expect(find.byKey(_thumb), findsNothing);
      expect(FlyToCart.airborne, 0);
      await tester.pump(const Duration(milliseconds: 40));
      expect(findRolled('2'), findsOneWidget);
      expect(_bumpOf(tester), greaterThan(1), reason: 'bumps on the landing');
      await tester.pumpAndSettle();

      // A drop never waits.
      count.value = 1;
      await tester.pump();
      expect(findRolled('1'), findsOneWidget);
    });

    testWidgets('reduced motion: no flight, the badge tints and changes at '
        'once', (tester) async {
      _reduceMotion(tester);
      final count = ValueNotifier<int>(1);
      addTearDown(count.dispose);
      await tester.pumpWidget(_host(_CartScene(count: count)));

      expect(_launch(tester), isFalse);
      count.value = 2;
      await tester.pump();
      expect(findRolled('2'), findsOneWidget);
      expect(_tint, findsOneWidget, reason: 'the tint');
      expect(_bumpOf(tester), 1, reason: 'no bump');
      await tester.pumpAndSettle();
      expect(_tint, findsNothing);
    });

    testWidgets('with animations off nothing moves or tints', (tester) async {
      final count = ValueNotifier<int>(1);
      addTearDown(count.dispose);
      await tester.pumpWidget(
        _host(_CartScene(count: count), animationsOff: true),
      );
      expect(_launch(tester), isFalse);
      count.value = 2;
      await tester.pump();
      expect(findRolled('2'), findsOneWidget);
      expect(_tint, findsNothing);
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('FlyToCart (B2-07)', () {
    testWidgets('at most three thumbnails in the air', (tester) async {
      final count = ValueNotifier<int>(0);
      addTearDown(count.dispose);
      await tester.pumpWidget(_host(_CartScene(count: count)));

      expect(
        [for (var i = 0; i < 4; i++) _launch(tester)],
        [true, true, true, false],
      );
      expect(FlyToCart.airborne, FlyToCart.maxFlights);
      await tester.pump();
      await tester.pump(_landed);
      await tester.pump();
      expect(FlyToCart.airborne, 0);
    });

    testWidgets('a cart under a covering route takes no flight', (
      tester,
    ) async {
      final count = ValueNotifier<int>(0);
      addTearDown(count.dispose);
      await tester.pumpWidget(
        _host(_CartScene(count: count, coveredTarget: true)),
      );
      expect(_launch(tester), isFalse);
      expect(FlyToCart.airborne, 0);
    });

    testWidgets('a flight torn down mid-air still lets waiting badges go', (
      tester,
    ) async {
      final count = ValueNotifier<int>(0);
      addTearDown(count.dispose);
      await tester.pumpWidget(_host(_CartScene(count: count)));
      expect(_launch(tester), isTrue);
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(FlyToCart.airborne, 0);
    });
  });

  group('CatalogCartGestures (B2-07)', () {
    testWidgets('add: one click, a flight, then the cart change', (
      tester,
    ) async {
      final calls = _recordHaptics(tester);
      final count = ValueNotifier<int>(0);
      addTearDown(count.dispose);
      await tester.pumpWidget(_host(_CartScene(count: count)));
      var commits = 0;

      final flew = CatalogCartGestures.add(
        tester.element(find.byKey(_CartScene.source)),
        image: '',
        thumbnail: const SizedBox(key: _thumb),
        commit: () => commits++,
      );
      await tester.pump();

      expect(flew, isTrue);
      expect(commits, 1);
      expect(calls, [_click]);
      expect(find.byKey(_thumb), findsOneWidget);
      await tester.pump(_landed);
      await tester.pump();

      // The first add of a session on Home is a success.
      CatalogCartGestures.add(
        tester.element(find.byKey(_CartScene.source)),
        image: '',
        first: true,
        thumbnail: const SizedBox(key: _thumb),
        commit: () => commits++,
      );
      expect(calls.last, _medium);
      await tester.pump();
      await tester.pump(_landed);
      await tester.pump();
    });

    testWidgets('reduced motion: the add still happens, with no flight', (
      tester,
    ) async {
      final calls = _recordHaptics(tester);
      final count = ValueNotifier<int>(0);
      addTearDown(count.dispose);
      await tester.pumpWidget(
        _host(_CartScene(count: count), animationsOff: true),
      );
      var commits = 0;
      final flew = CatalogCartGestures.add(
        tester.element(find.byKey(_CartScene.source)),
        image: '',
        thumbnail: const SizedBox(key: _thumb),
        commit: () => commits++,
      );
      await tester.pump();
      expect(flew, isFalse);
      expect(commits, 1);
      expect(calls, [_click]);
      expect(find.byKey(_thumb), findsNothing);
    });

    testWidgets(
      'added (reorder): one click and a flight; done on the landing',
      (tester) async {
        final calls = _recordHaptics(tester);
        final count = ValueNotifier<int>(0);
        addTearDown(count.dispose);
        await tester.pumpWidget(_host(_CartScene(count: count)));
        var done = false;

        unawaited(
          CatalogCartGestures.added(
            tester.element(find.byKey(_CartScene.source)),
            image: '',
            thumbnail: const SizedBox(key: _thumb),
          ).then((_) => done = true),
        );
        await tester.pump();
        expect(calls, [_click]);
        expect(find.byKey(_thumb), findsOneWidget);
        expect(done, isFalse, reason: 'the cart opens only after the landing');

        await tester.pump(_landed);
        await tester.pump();
        expect(done, isTrue);
      },
    );

    testWidgets('added (reorder) under reduced motion: done at once', (
      tester,
    ) async {
      final calls = _recordHaptics(tester);
      final count = ValueNotifier<int>(0);
      addTearDown(count.dispose);
      await tester.pumpWidget(
        _host(_CartScene(count: count), animationsOff: true),
      );
      var done = false;
      unawaited(
        CatalogCartGestures.added(
          tester.element(find.byKey(_CartScene.source)),
          image: '',
        ).then((_) => done = true),
      );
      await tester.pump();
      expect(done, isTrue);
      expect(calls, [_click]);
      expect(find.byKey(_thumb), findsNothing);
    });

    test('remove: one light tap, then the cart change', () {
      var commits = 0;
      final calls = <String?>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'HapticFeedback.vibrate') {
              calls.add(call.arguments as String?);
            }
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null),
      );
      CatalogCartGestures.remove(commit: () => commits++);
      expect(commits, 1);
      expect(calls, [_light]);
    });
  });

  group('the shared stepper (B2-01)', () {
    testWidgets('the count rolls; − / + sink under the finger', (tester) async {
      Widget stepper(int qty) =>
          _host(CatalogPillStepper(qty: qty, onAdd: () {}, onRemove: () {}));
      await tester.pumpWidget(stepper(1));
      expect(tester.hasRunningAnimations, isFalse);

      await tester.pumpWidget(stepper(2));
      await tester.pump(AppMotion.medium ~/ 3);
      expect(_slideOf(tester, '2'), greaterThan(0), reason: 'rolls up');
      await tester.pumpAndSettle();

      final plus = find.byType(CatalogStepButton).last;
      final gesture = await tester.startGesture(tester.getCenter(plus));
      await tester.pump(AppMotion.microPop);
      final scale = tester.widget<AnimatedScale>(
        find.descendant(of: plus, matching: find.byType(AnimatedScale)),
      );
      expect(scale.scale, AppMotion.pressedScaleSmall);
      await gesture.up();
      await tester.pumpAndSettle();
    });
  });

  group('one add → stepper swap (BX-09)', () {
    testWidgets('the shelf card pops the stepper out of its "+"', (
      tester,
    ) async {
      Widget control(int qty) => _host(
        ShelfAddControl(
          product: _lemon,
          qty: qty,
          onAdd: () {},
          onRemove: () {},
          onChooseOptions: () {},
        ),
      );
      await tester.pumpWidget(control(0));
      final pop = tester.widget<PopSwitcher>(find.byType(PopSwitcher));
      expect(pop.from, PopSwitcher.cartFrom);
      expect(tester.hasRunningAnimations, isFalse);

      await tester.pumpWidget(control(1));
      await tester.pump(const Duration(milliseconds: 40));
      expect(find.byType(CatalogPillStepper), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('the product page buy bar uses the same swap', (tester) async {
      Widget cta(int quantity) => _host(
        SizedBox(
          width: 200,
          child: PdpCartCta(
            enabled: true,
            disabledLabel: '',
            quantity: quantity,
            onAdd: () {},
            onIncrement: () {},
            onDecrement: () {},
          ),
        ),
      );
      await tester.pumpWidget(cta(0));
      final pop = tester.widget<PopSwitcher>(
        find
            .descendant(
              of: find.byType(PdpCartCta),
              matching: find.byType(PopSwitcher),
            )
            .first,
      );
      expect(pop.from, PopSwitcher.cartFrom);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('reduced motion: the swap is instant', (tester) async {
      Widget control(int qty) => _host(
        ShelfAddControl(
          product: _lemon,
          qty: qty,
          onAdd: () {},
          onRemove: () {},
          onChooseOptions: () {},
        ),
        animationsOff: true,
      );
      await tester.pumpWidget(control(0));
      await tester.pumpWidget(control(1));
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse);
      expect(find.byType(CatalogPillStepper), findsOneWidget);
    });
  });
}
