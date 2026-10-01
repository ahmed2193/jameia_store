// I9 — one interaction feel (docs/motion §9.4 #1 press, #21 ticker, #27
// segmented switch; backlog B1-16, B2-09, BX-08, B2-03):
// * every press dips to the one depth (0.97, icons 0.92), in fast, out
//   faster, silent by default, and only the innermost press under a finger
//   dips; list rows add the flat brand tint;
// * one segmented thumb: the calm spring, mirrored in RTL, instant under
//   reduced motion, one selection click per real change;
// * one vertical swap: new content rises from below, old leaves above, by
//   the entrance rise; the ticker spends at most the ambient budget per
//   appearance and rests under a covered route;
// * a state change lands in beats: the touched control first, the rest in
//   order.
import 'dart:convert';

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
// ignore: implementation_imports
import 'package:easy_localization/src/localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/gestures.dart' show kPressTimeout;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/config/theme/app_colors.dart';
import 'package:hero_mart/src/core/design/hero_icons.dart';
import 'package:hero_mart/src/core/motion/after_arrival.dart';
import 'package:hero_mart/src/core/motion/blocked_tap_shake.dart';
import 'package:hero_mart/src/core/motion/deferred_value.dart';
import 'package:hero_mart/src/core/motion/entrance_arrival.dart';
import 'package:hero_mart/src/core/motion/haptics.dart';
import 'package:hero_mart/src/core/motion/motion.dart';
import 'package:hero_mart/src/core/motion/motion_beat.dart';
import 'package:hero_mart/src/core/motion/press_scale.dart';
import 'package:hero_mart/src/core/motion/rotating_line.dart';
import 'package:hero_mart/src/core/motion/vertical_swap_transition.dart';
import 'package:hero_mart/src/core/widgets/hero_segmented_control.dart';
import 'package:hero_mart/src/core/widgets/press_row.dart';
import 'package:hero_mart/src/core/widgets/segmented_thumb_track.dart';
import 'package:hero_mart/src/features/assistant/presentation/widgets/composer/assistant_composer_hint.dart';
import 'package:hero_mart/src/features/coupons/presentation/widgets/my_coupons/coupons_tab_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _click = 'HapticFeedbackType.selectionClick';
const String _heavy = 'HapticFeedbackType.heavyImpact';
const Duration _frame = Duration(milliseconds: 16);

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

/// [child] in an app whose MediaQuery (the screen's size) the on-screen
/// gates measure against.
Widget _host(
  Widget child, {
  bool reduced = false,
  bool screenReader = false,
  TextDirection direction = TextDirection.ltr,
}) => MaterialApp(
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        disableAnimations: reduced,
        accessibleNavigation: screenReader,
      ),
      child: Directionality(
        textDirection: direction,
        child: Scaffold(body: Center(child: child)),
      ),
    ),
  ),
);

/// The press depth a [PressScale] shows now (its own AnimatedScale).
AnimatedScale _scaleOf(WidgetTester tester, Key key) => tester.widget(
  find
      .descendant(of: find.byKey(key), matching: find.byType(AnimatedScale))
      .first,
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

  group('B1-16 one press', () {
    const card = Key('card');
    const icon = Key('icon');

    testWidgets('a card dips to 0.97 and an icon to 0.92, in over microPop, '
        'out over fast, with no haptic of its own', (tester) async {
      final haptics = _recordHaptics(tester);
      var taps = 0;
      await tester.pumpWidget(
        _host(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PressScale(
                key: card,
                onTap: () => taps++,
                child: const SizedBox(width: 120, height: 80),
              ),
              PressScale(
                key: icon,
                onTap: () => taps++,
                pressedScale: AppMotion.pressedScaleSmall,
                child: const SizedBox.square(dimension: 32),
              ),
            ],
          ),
        ),
      );

      for (final (key, depth) in const [
        (card, AppMotion.pressedScale),
        (icon, AppMotion.pressedScaleSmall),
      ]) {
        final finger = await tester.startGesture(
          tester.getCenter(find.byKey(key)),
        );
        await tester.pump(kPressTimeout);
        expect(_scaleOf(tester, key).scale, depth);
        expect(_scaleOf(tester, key).duration, AppMotion.microPop);
        expect(_scaleOf(tester, key).curve, AppMotion.signature);

        await finger.up();
        await tester.pump();
        expect(_scaleOf(tester, key).scale, 1);
        expect(_scaleOf(tester, key).duration, AppMotion.fast);
        await tester.pumpAndSettle();
      }
      expect(AppMotion.pressedScale, 0.97);
      expect(AppMotion.pressedScaleSmall, 0.92);
      expect(taps, 2);
      expect(haptics, isEmpty, reason: 'a press is not feedback of its own');
    });

    testWidgets('no stacked presses: the "+" dips, the card around it stays '
        'still; the card alone dips when pressed itself', (tester) async {
      final taps = <String>[];
      await tester.pumpWidget(
        _host(
          PressScale(
            key: card,
            onTap: () => taps.add('card'),
            child: SizedBox(
              width: 200,
              height: 200,
              child: Align(
                alignment: AlignmentDirectional.bottomEnd,
                child: PressScale(
                  key: icon,
                  onTap: () => taps.add('plus'),
                  pressedScale: AppMotion.pressedScaleSmall,
                  child: const SizedBox.square(dimension: 40),
                ),
              ),
            ),
          ),
        ),
      );

      final onPlus = await tester.startGesture(
        tester.getCenter(find.byKey(icon)),
      );
      await tester.pump(kPressTimeout);
      expect(_scaleOf(tester, icon).scale, AppMotion.pressedScaleSmall);
      expect(_scaleOf(tester, card).scale, 1);
      await onPlus.up();
      await tester.pumpAndSettle();

      final onCard = await tester.startGesture(
        tester.getTopLeft(find.byKey(card)) + const Offset(20, 20),
      );
      await tester.pump(kPressTimeout);
      expect(_scaleOf(tester, card).scale, AppMotion.pressedScale);
      expect(_scaleOf(tester, icon).scale, 1);
      await onCard.up();
      await tester.pumpAndSettle();

      expect(taps, ['plus', 'card']);
    });

    testWidgets('a row: the dip and the flat brand tint (no splash); its '
        'own icon button presses alone', (tester) async {
      await tester.pumpWidget(
        _host(
          PressRow(
            key: card,
            onTap: () {},
            child: SizedBox(
              width: 300,
              height: 56,
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: PressScale(
                  key: icon,
                  pressedScale: AppMotion.pressedScaleSmall,
                  child: IconButton(
                    onPressed: () {},
                    icon: const Icon(HeroIcons.edit),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      final ink = tester.widget<InkWell>(
        find
            .descendant(of: find.byKey(card), matching: find.byType(InkWell))
            .first,
      );
      expect(ink.highlightColor, AppColors.pressTint);
      expect(ink.splashFactory, NoSplash.splashFactory);

      final onRow = await tester.startGesture(
        tester.getTopLeft(find.byKey(card)) + const Offset(20, 28),
      );
      await tester.pump();
      expect(_scaleOf(tester, card).scale, AppMotion.pressedScale);
      await onRow.up();
      await tester.pumpAndSettle();

      final onIcon = await tester.startGesture(
        tester.getCenter(find.byType(IconButton)),
      );
      await tester.pump();
      expect(_scaleOf(tester, icon).scale, AppMotion.pressedScaleSmall);
      expect(_scaleOf(tester, card).scale, 1);
      await onIcon.up();
      await tester.pumpAndSettle();
    });

    testWidgets('reduced motion: no dip (the row keeps its tint)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          PressRow(
            key: card,
            onTap: () {},
            child: const SizedBox(width: 300, height: 56),
          ),
          reduced: true,
        ),
      );
      final finger = await tester.startGesture(
        tester.getCenter(find.byKey(card)),
      );
      await tester.pump();
      expect(_scaleOf(tester, card).scale, 1);
      expect(
        tester
            .widget<InkWell>(
              find.descendant(
                of: find.byKey(card),
                matching: find.byType(InkWell),
              ),
            )
            .highlightColor,
        AppColors.pressTint,
      );
      await finger.up();
    });

    testWidgets('a disabled press stays out of the way: a blocked tap shakes '
        'and warns', (tester) async {
      final haptics = _recordHaptics(tester);
      var taps = 0;
      await tester.pumpWidget(
        _host(
          BlockedTapShake(
            blocked: true,
            child: PressScale(
              key: icon,
              enabled: false,
              onTap: () => taps++,
              child: const SizedBox.square(dimension: 40),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(icon));
      await tester.pump();
      expect(taps, 0);
      expect(haptics, [_heavy]);
      await tester.pumpAndSettle();
    });
  });

  group('B2-09 one segmented thumb', () {
    const values = ['A', 'B', 'C'];
    const width = 308.0;

    /// The control's inset (4 dp each side) leaves 300 dp for three slots.
    const slot = 100.0;

    Future<void> pumpControl(
      WidgetTester tester, {
      TextDirection direction = TextDirection.ltr,
      bool reduced = false,
      List<String>? picks,
    }) async {
      var selected = 'A';
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) => SizedBox(
              width: width,
              child: HeroSegmentedControl<String>(
                values: values,
                selected: selected,
                labelOf: (value) => value,
                onChanged: (value) {
                  picks?.add(value);
                  setState(() => selected = value);
                },
              ),
            ),
          ),
          direction: direction,
          reduced: reduced,
        ),
      );
    }

    double thumbX(WidgetTester tester) => tester
        .widget<Transform>(
          find
              .descendant(
                of: find.byType(SegmentedThumbTrack),
                matching: find.byType(Transform),
              )
              .first,
        )
        .transform
        .getTranslation()
        .x;

    testWidgets('slides on the calm spring (thumbSlide) and clicks once per '
        'real change; the selected segment is inert', (tester) async {
      final haptics = _recordHaptics(tester);
      final picks = <String>[];
      await pumpControl(tester, picks: picks);
      expect(thumbX(tester), 0);

      await tester.tap(find.text('A'));
      await tester.pumpAndSettle();
      expect(picks, isEmpty);
      expect(haptics, isEmpty);

      await tester.tap(find.text('B'));
      await tester.pump();
      await tester.pump(AppMotion.thumbSlide.duration ~/ 2);
      final mid = thumbX(tester);
      expect(mid, greaterThan(0));
      expect(mid, lessThan(slot));

      await tester.pump(AppMotion.thumbSlide.duration);
      expect(thumbX(tester), closeTo(slot, 1));
      await tester.pumpAndSettle();
      expect(thumbX(tester), closeTo(slot, 0.01));
      expect(picks, ['B']);
      expect(haptics, [_click]);
      expect(AppMotion.thumbSlide, same(AppSprings.calm));
    });

    testWidgets('mirrors under RTL: the thumb travels towards the left', (
      tester,
    ) async {
      await pumpControl(tester, direction: TextDirection.rtl);
      await tester.tap(find.text('C'));
      await tester.pumpAndSettle();
      expect(thumbX(tester), closeTo(-2 * slot, 0.01));
    });

    testWidgets('reduced motion: the thumb jumps', (tester) async {
      final haptics = _recordHaptics(tester);
      await pumpControl(tester, reduced: true);
      await tester.tap(find.text('C'));
      await tester.pump();
      expect(thumbX(tester), 2 * slot);
      expect(tester.hasRunningAnimations, isFalse);
      expect(haptics, [_click], reason: 'haptics stay under reduced motion');
    });

    testWidgets('My coupons: the thumb rides the tab controller; a tap '
        'clicks once and slides on the spring', (tester) async {
      final haptics = _recordHaptics(tester);
      final controller = TabController(length: 3, vsync: tester);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 316,
            child: CouponsTabBar(
              controller: controller,
              labels: const ['Available', 'Used', 'Expired'],
              counts: const [2, 0, 0],
            ),
          ),
        ),
      );
      await tester.tap(find.text('Used'));
      await tester.pump();
      expect(controller.index, 1);
      await tester.pump(AppMotion.thumbSlide.duration ~/ 2);
      final mid = thumbX(tester);
      expect(mid, greaterThan(0));
      await tester.pumpAndSettle();
      // 316 dp, two 8 dp gaps: three 100 dp slots, one slot + gap away.
      expect(thumbX(tester), closeTo(108, 0.01));
      expect(haptics, [_click]);

      await tester.tap(find.text('Used'));
      await tester.pumpAndSettle();
      expect(haptics, [_click], reason: 'the selected tab is inert');
    });
  });

  group('BX-08 one vertical swap', () {
    double riseOf(WidgetTester tester) => tester
        .widget<Transform>(
          find
              .descendant(
                of: find.byType(VerticalSwapTransition),
                matching: find.byType(Transform),
              )
              .first,
        )
        .transform
        .getTranslation()
        .y;

    Future<void> pumpSwap(
      WidgetTester tester, {
      required bool incoming,
      bool rising = true,
    }) => tester.pumpWidget(
      _host(
        VerticalSwapTransition(
          animation: const AlwaysStoppedAnimation<double>(0.5),
          incoming: incoming,
          rising: rising,
          child: const Text('line'),
        ),
      ),
    );

    testWidgets('new content rises from below, old leaves above, by the '
        'entrance rise', (tester) async {
      await pumpSwap(tester, incoming: true);
      expect(riseOf(tester), AppMotion.entranceRise / 2);
      await pumpSwap(tester, incoming: false);
      expect(riseOf(tester), -AppMotion.entranceRise / 2);
      await pumpSwap(tester, incoming: true, rising: false);
      expect(riseOf(tester), -AppMotion.entranceRise / 2);
      expect(AppMotion.entranceRise, 8);
    });

    Widget ticker({
      List<String> ids = const ['a', 'b', 'c'],
      bool tickers = true,
    }) => TickerMode(
      enabled: tickers,
      child: RotatingLine(
        items: [
          for (final id in ids)
            RotatingLineItem(id: id, child: Text('fact $id')),
        ],
      ),
    );

    RotatingLineState line(WidgetTester tester) =>
        tester.state(find.byType(RotatingLine));

    testWidgets('a ticker swap: mid-way the new line sits below the old', (
      tester,
    ) async {
      await tester.pumpWidget(_host(ticker()));
      final rest = tester.getTopLeft(find.text('fact a')).dy;
      await tester.pump(AppMotion.carousel);
      await tester.pump(AppMotion.medium ~/ 2);
      expect(tester.getTopLeft(find.text('fact b')).dy, greaterThan(rest));
      expect(tester.getTopLeft(find.text('fact a')).dy, lessThan(rest));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.text('fact b')).dy, rest);
    });

    testWidgets('one swap per appearance (the ambient budget); a new '
        'appearance gets a fresh one', (tester) async {
      await tester.pumpWidget(_host(ticker()));
      await tester.pump(AppMotion.carousel);
      await tester.pumpAndSettle();
      expect(find.text('fact b'), findsOneWidget);
      expect(line(tester).debugResting, isFalse, reason: 'budget spent');

      await tester.pump(AppMotion.carousel * 3);
      expect(find.text('fact b'), findsOneWidget);
      expect(tester.binding.hasScheduledFrame, isFalse);

      // The tab hidden and shown again.
      await tester.pumpWidget(_host(ticker(tickers: false)));
      expect(line(tester).debugOnStage, isFalse);
      await tester.pumpWidget(_host(ticker()));
      expect(line(tester).debugResting, isTrue);
      await tester.pump(AppMotion.carousel);
      await tester.pumpAndSettle();
      expect(find.text('fact c'), findsOneWidget);
    });

    testWidgets('a screen reader holds the ticker', (tester) async {
      await tester.pumpWidget(_host(ticker(), screenReader: true));
      expect(line(tester).debugOnStage, isFalse);
      expect(line(tester).debugResting, isFalse);
      await tester.pump(AppMotion.carousel * 2);
      expect(find.text('fact a'), findsOneWidget);
    });

    testWidgets('the composer hint rests under a covered route (TickerMode '
        'off) and rotates on the one carousel dwell', (tester) async {
      final first = AssistantComposerHint.examples.first.tr();
      final second = AssistantComposerHint.examples[1].tr();

      await tester.pumpWidget(
        _host(const TickerMode(enabled: false, child: AssistantComposerHint())),
      );
      expect(line(tester).debugResting, isFalse);
      await tester.pump(AppMotion.carousel * 2);
      expect(find.text(first), findsOneWidget);

      await tester.pumpWidget(_host(const AssistantComposerHint()));
      expect(line(tester).debugResting, isTrue);
      await tester.pump(AppMotion.carousel);
      await tester.pumpAndSettle();
      expect(find.text(second), findsOneWidget);
    });
  });

  group('B2-03 one motion per moment', () {
    test('the beats come in order, one component change apart', () {
      expect(MotionBeat.primary, Duration.zero);
      expect(MotionBeat.second, AppMotion.medium);
      expect(MotionBeat.third, AppMotion.medium * 2);
      expect(MotionBeat.at(3), AppMotion.medium * 3);
      expect(MotionBeat.at(3), greaterThan(MotionBeat.third));
    });

    Widget deferred(
      int value, {
      bool Function(int shown, int next)? deferWhen,
      bool reduced = false,
    }) => _host(
      DeferredValue<int>(
        value: value,
        delay: MotionBeat.second,
        deferWhen: deferWhen,
        builder: (context, shown) => Text('value $shown'),
      ),
      reduced: reduced,
    );

    testWidgets('a change lands on its beat; the first value at once', (
      tester,
    ) async {
      await tester.pumpWidget(deferred(1));
      expect(find.text('value 1'), findsOneWidget);

      await tester.pumpWidget(deferred(2));
      expect(find.text('value 1'), findsOneWidget);
      await tester.pump(MotionBeat.second - _frame);
      expect(find.text('value 1'), findsOneWidget);
      await tester.pump(_frame);
      expect(find.text('value 2'), findsOneWidget);
    });

    testWidgets('deferWhen: only the named changes wait; the others land at '
        'once and drop a pending one', (tester) async {
      // Only a rise waits (a total settling); a drop lands at once.
      bool rises(int shown, int next) => next > shown;
      await tester.pumpWidget(deferred(5, deferWhen: rises));

      await tester.pumpWidget(deferred(3, deferWhen: rises));
      expect(find.text('value 3'), findsOneWidget);

      await tester.pumpWidget(deferred(9, deferWhen: rises));
      expect(find.text('value 3'), findsOneWidget);
      await tester.pumpWidget(deferred(1, deferWhen: rises));
      expect(find.text('value 1'), findsOneWidget);
      await tester.pump(MotionBeat.second);
      expect(find.text('value 1'), findsOneWidget, reason: 'nothing pending');
    });

    testWidgets('reduced motion: every change lands at once', (tester) async {
      await tester.pumpWidget(deferred(1, reduced: true));
      await tester.pumpWidget(deferred(2, reduced: true));
      expect(find.text('value 2'), findsOneWidget);
    });

    testWidgets('a touch inside an entering card waits for the card to land', (
      tester,
    ) async {
      final arrival = AnimationController(
        vsync: tester,
        duration: AppMotion.medium,
      );
      addTearDown(arrival.dispose);
      final seen = <bool>[];
      await tester.pumpWidget(
        _host(
          EntranceArrival(
            arrival: arrival,
            child: AfterArrival(
              builder: (context, landed) {
                seen.add(landed);
                return Text(landed ? 'landed' : 'rising');
              },
            ),
          ),
        ),
      );
      expect(find.text('rising'), findsOneWidget);

      arrival.forward();
      await tester.pump(AppMotion.medium ~/ 2);
      expect(find.text('rising'), findsOneWidget);
      await tester.pump(AppMotion.medium);
      await tester.pump(_frame);
      expect(find.text('landed'), findsOneWidget);
      expect(seen.where((landed) => landed), hasLength(1));

      // Outside an entrance: there already.
      await tester.pumpWidget(
        _host(
          AfterArrival(
            builder: (context, landed) => Text(landed ? 'landed' : 'rising'),
          ),
        ),
      );
      expect(find.text('landed'), findsOneWidget);
    });
  });
}
