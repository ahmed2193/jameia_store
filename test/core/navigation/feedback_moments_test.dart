// I8 feedback moments (docs/motion §9.4 #13-#15, #23; B3-03, B3-04): snack
// tones + action + dwell + the in-place cross-fade of a replacement, the
// failure-snack contract keeping its tones, the dialog's fade-only exit, one
// bottom sheet at a time, and the language veil covering what sits above
// the routes (the connection banner).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/config/theme/app_colors.dart';
import 'package:hero_mart/src/core/design/hero_icons.dart';
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/core/motion/locale_swap_veil.dart';
import 'package:hero_mart/src/core/motion/locale_swap_veil_host.dart';
import 'package:hero_mart/src/core/motion/locale_swap_veil_view.dart';
import 'package:hero_mart/src/core/motion/motion.dart';
import 'package:hero_mart/src/core/navigation/hero_snack_content.dart';
import 'package:hero_mart/src/core/navigation/hero_snack_glyph.dart';
import 'package:hero_mart/src/core/navigation/navigation.dart';
import 'package:hero_mart/src/core/widgets/connectivity_scope.dart';

/// One frame: a controller that ran its whole duration completes (and its
/// route or snack goes) on the frame after.
const Duration tick = Duration(milliseconds: 16);

void main() {
  late BuildContext host;

  Widget app({bool offline = false, VoidCallback? onNudge}) => MaterialApp(
    home: ConnectivityScope(
      isOffline: offline,
      reconnectEpoch: 0,
      onNudge: onNudge ?? () {},
      child: Scaffold(
        body: Builder(
          builder: (context) {
            host = context;
            return const SizedBox.expand();
          },
        ),
      ),
    ),
  );

  /// Shows [message] and lets it rise in.
  Future<void> show(
    WidgetTester tester,
    String message, {
    HeroSnackTone tone = HeroSnackTone.info,
    String? actionLabel,
    VoidCallback? onAction,
  }) async {
    showHeroSnackBar(
      host,
      message,
      tone: tone,
      actionLabel: actionLabel,
      onAction: onAction,
    );
    await tester.pump();
    await tester.pump(AppMotion.medium);
    await tester.pump(tick);
  }

  group('snack bar tone', () {
    testWidgets('success / offline wear the Hero glyphs, tinted', (
      tester,
    ) async {
      await tester.pumpWidget(app());
      await show(tester, 'Saved', tone: HeroSnackTone.success);

      final glyph = tester.widget<HeroSnackGlyph>(find.byType(HeroSnackGlyph));
      expect(glyph.tone, HeroSnackTone.success);
      final check = tester.widget<Icon>(find.byIcon(HeroIcons.checkCircleFill));
      expect(check.color, AppColors.primary);
      expect(check.size, HeroSnackGlyph.size);

      await show(tester, 'Needs the internet', tone: HeroSnackTone.offline);
      await tester.pump(AppMotion.fast);
      final offline = tester.widget<Icon>(find.byIcon(HeroIcons.offline));
      expect(offline.color, AppColors.white);
      expect(find.byIcon(HeroIcons.checkCircleFill), findsNothing);
    });

    testWidgets('warning / error wear the info / alert icons; info none', (
      tester,
    ) async {
      await tester.pumpWidget(app());
      await show(tester, 'Pick a slot', tone: HeroSnackTone.warning);
      expect(find.byIcon(HeroIcons.warning), findsOneWidget);

      await show(tester, 'Refused', tone: HeroSnackTone.error);
      await tester.pump(AppMotion.fast);
      expect(find.byIcon(HeroIcons.bell), findsOneWidget);
      expect(find.byIcon(HeroIcons.warning), findsNothing);

      await show(tester, 'Just so you know');
      await tester.pump(AppMotion.fast);
      expect(find.byIcon(HeroIcons.bell), findsNothing);
      expect(find.byIcon(HeroIcons.checkCircleFill), findsNothing);
      expect(find.byIcon(HeroIcons.offline), findsNothing);
      expect(find.text('Just so you know'), findsOneWidget);
    });
  });

  group('snack bar motion', () {
    testWidgets('floats, stays snackDwell (with an action too), then goes', (
      tester,
    ) async {
      await tester.pumpWidget(app());
      var undone = 0;
      await show(
        tester,
        'Cart cleared',
        tone: HeroSnackTone.success,
        actionLabel: 'Undo',
        onAction: () => undone++,
      );
      final bar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(bar.duration, AppMotion.snackDwell);
      expect(bar.persist, isFalse);
      expect(find.text('Undo'), findsOneWidget);

      await tester.pump(AppMotion.snackDwell - AppMotion.fast);
      expect(find.text('Cart cleared'), findsOneWidget);
      await tester.pump(AppMotion.fast);
      await tester.pump(AppMotion.fast);
      await tester.pump(tick);
      await tester.pump(tick);
      expect(find.byType(SnackBar), findsNothing);
      expect(undone, 0);
    });

    testWidgets('the action runs once and closes the snack', (tester) async {
      await tester.pumpWidget(app());
      var undone = 0;
      await show(
        tester,
        'Basmati rice removed',
        actionLabel: 'Undo',
        onAction: () => undone++,
      );

      await tester.tap(find.text('Undo'));
      await tester.pump();
      await tester.pump(AppMotion.fast);
      await tester.pump(tick);
      await tester.pump(tick);

      expect(undone, 1);
      expect(find.byType(SnackBar), findsNothing);
    });

    // Review fix I3: a screen-reader user must be able to reach the action.
    testWidgets('with a screen reader a snack with an action stays until '
        'acted on; one without still goes', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(accessibleNavigation: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await tester.pumpWidget(app());
      var undone = 0;
      await show(
        tester,
        'Address deleted',
        actionLabel: 'Undo',
        onAction: () => undone++,
      );
      expect(tester.widget<SnackBar>(find.byType(SnackBar)).persist, isTrue);

      await tester.pump(AppMotion.snackDwell * 3);
      await tester.pump(tick);
      expect(find.text('Undo'), findsOneWidget, reason: 'no time-out');

      await tester.tap(find.text('Undo'));
      await tester.pump();
      await tester.pump(tick);
      expect(undone, 1);
      expect(find.byType(SnackBar), findsNothing);

      await show(tester, 'Saved');
      expect(tester.widget<SnackBar>(find.byType(SnackBar)).persist, isFalse);
    });

    testWidgets('the controller comes back: closed tells how the snack went', (
      tester,
    ) async {
      await tester.pumpWidget(app());
      final reasons = <SnackBarClosedReason>[];
      final snack = showHeroSnackBar(
        host,
        'Address deleted',
        actionLabel: 'Undo',
        onAction: () {},
      );
      unawaited(snack!.closed.then(reasons.add));
      await tester.pump();
      await tester.pump(AppMotion.medium);
      await tester.pump(tick);
      await tester.pump(AppMotion.snackDwell);
      await tester.pump(AppMotion.fast);
      await tester.pump(tick);

      expect(reasons, [SnackBarClosedReason.timeout]);
    });

    testWidgets('a replacement takes the place at once; the words '
        'cross-fade over fast', (tester) async {
      await tester.pumpWidget(app());
      await show(tester, 'First');

      showHeroSnackBar(host, 'Second', tone: HeroSnackTone.success);
      await tester.pump();
      await tester.pump(AppMotion.fast ~/ 2);

      // One snack, both words mid-swap: the old one fading out, the new in.
      expect(find.byType(SnackBar), findsOneWidget);
      final content = tester.widget<HeroSnackContent>(
        find.byType(HeroSnackContent),
      );
      expect(content.previous?.text, 'First');
      double opacityOf(String text) => tester
          .widget<FadeTransition>(
            find
                .ancestor(
                  of: find.text(text),
                  matching: find.byType(FadeTransition),
                )
                .first,
          )
          .opacity
          .value;
      expect(opacityOf('First'), inExclusiveRange(0, 1));
      expect(opacityOf('Second'), inExclusiveRange(0, 1));

      await tester.pump(AppMotion.fast);
      expect(find.text('First'), findsNothing);
      expect(find.text('Second'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('a message after the last one left rises in fresh', (
      tester,
    ) async {
      await tester.pumpWidget(app());
      await show(tester, 'First');
      await tester.pump(AppMotion.snackDwell);
      await tester.pump(AppMotion.fast);
      await tester.pump(tick);
      await tester.pump(tick);
      expect(find.byType(SnackBar), findsNothing);

      showHeroSnackBar(host, 'Again');
      await tester.pump();
      final content = tester.widget<HeroSnackContent>(
        find.byType(HeroSnackContent),
      );
      expect(content.previous, isNull);
    });
  });

  group('failure snack contract', () {
    testWidgets('a failed action offline: nudge + the offline tone', (
      tester,
    ) async {
      var nudges = 0;
      await tester.pumpWidget(app(offline: true, onNudge: () => nudges++));
      showFailureSnackBar(host, const NetworkFailure(), action: true);
      await tester.pump();
      await tester.pump(AppMotion.medium);

      expect(nudges, 1);
      final glyph = tester.widget<HeroSnackGlyph>(find.byType(HeroSnackGlyph));
      expect(glyph.tone, HeroSnackTone.offline);
    });

    testWidgets('a read lost in transport shows nothing of its own', (
      tester,
    ) async {
      var nudges = 0;
      await tester.pumpWidget(app(offline: true, onNudge: () => nudges++));
      showFailureSnackBar(host, const NetworkFailure());
      await tester.pump();

      expect(nudges, 1);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('a refused call: its own words in the error tone', (
      tester,
    ) async {
      await tester.pumpWidget(app());
      showFailureSnackBar(host, const ServerFailure('Out of slots'));
      await tester.pump();
      await tester.pump(AppMotion.medium);

      expect(find.text('Out of slots'), findsOneWidget);
      final glyph = tester.widget<HeroSnackGlyph>(find.byType(HeroSnackGlyph));
      expect(glyph.tone, HeroSnackTone.error);
    });
  });

  group('dialog', () {
    testWidgets('in: fade + settle from 1.1 over medium; out: a fade over '
        'fast, no scale', (tester) async {
      await tester.pumpWidget(app());
      unawaited(
        showHeroDialog<void>(
          host,
          barrierLabel: 'dialog',
          pageBuilder: (_) => const Center(child: Text('Sure?')),
        ),
      );
      await tester.pump();
      await tester.pump(AppMotion.medium ~/ 2);
      ScaleTransition scale() => tester.widget<ScaleTransition>(
        find
            .ancestor(
              of: find.text('Sure?'),
              matching: find.byType(ScaleTransition),
            )
            .first,
      );
      expect(scale().scale.value, greaterThan(1));
      await tester.pump(AppMotion.medium);
      expect(scale().scale.value, 1);

      Navigator.of(host).pop();
      await tester.pump();
      await tester.pump(AppMotion.fast ~/ 2);
      expect(find.text('Sure?'), findsOneWidget);
      expect(scale().scale.value, 1);
      final fade = tester.widget<FadeTransition>(
        find
            .ancestor(
              of: find.text('Sure?'),
              matching: find.byType(FadeTransition),
            )
            .first,
      );
      expect(fade.opacity.value, inExclusiveRange(0, 1));

      await tester.pump(AppMotion.fast ~/ 2);
      await tester.pump(tick);
      await tester.pump(tick);
      expect(find.text('Sure?'), findsNothing);
    });

    testWidgets('reduced motion: a fast fade, never a scale', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: app(),
        ),
      );
      unawaited(
        showHeroDialog<void>(
          host,
          barrierLabel: 'dialog',
          pageBuilder: (_) => const Center(child: Text('Sure?')),
        ),
      );
      await tester.pump();
      expect(find.text('Sure?'), findsOneWidget);
      expect(
        find.ancestor(
          of: find.text('Sure?'),
          matching: find.byType(ScaleTransition),
        ),
        findsNothing,
      );
    });
  });

  group('bottom sheet', () {
    testWidgets('one at a time: a second call while one is up does nothing', (
      tester,
    ) async {
      await tester.pumpWidget(app());
      final first = showHeroBottomSheet<String>(
        host,
        builder: (_) => const Text('First sheet'),
      );
      await tester.pump();
      await tester.pump(AppMotion.page);

      final second = await showHeroBottomSheet<String>(
        host,
        builder: (_) => const Text('Second sheet'),
      );
      await tester.pump();
      expect(second, isNull);
      expect(find.text('First sheet'), findsOneWidget);
      expect(find.text('Second sheet'), findsNothing);

      Navigator.of(host).pop('done');
      expect(await first, 'done');
      // The first one is still sliding out: the next of a flow may open.
      unawaited(
        showHeroBottomSheet<String>(
          host,
          builder: (_) => const Text('Next sheet'),
        ),
      );
      await tester.pump();
      await tester.pump(AppMotion.page);
      expect(find.text('Next sheet'), findsOneWidget);
    });

    testWidgets('lets go of a sheet once it answered, keeps the next one', (
      tester,
    ) async {
      await tester.pumpWidget(app());
      final first = showHeroBottomSheet<String>(
        host,
        builder: (_) => const Text('First sheet'),
      );
      await tester.pump();
      await tester.pump(AppMotion.page);
      final firstRoute = ModalRoute.of(
        tester.element(find.text('First sheet')),
      );
      expect(debugHeldSheet, same(firstRoute));

      Navigator.of(host).pop('done');
      expect(await first, 'done');
      // Answered: held no more, so its page (captured themes, elements) can
      // be collected once the sheet is gone.
      expect(debugHeldSheet, isNull);

      // The next of a flow is held while it is up, even though the first
      // one is still sliding out.
      unawaited(
        showHeroBottomSheet<String>(
          host,
          builder: (_) => const Text('Next sheet'),
        ),
      );
      await tester.pump();
      await tester.pump(AppMotion.page);
      final nextRoute = ModalRoute.of(tester.element(find.text('Next sheet')));
      expect(debugHeldSheet, same(nextRoute));
      Navigator.of(host).pop();
      await tester.pump();
      expect(debugHeldSheet, isNull);
    });

    testWidgets('in over page (large: slow), out over medium', (tester) async {
      await tester.pumpWidget(app());
      unawaited(
        showHeroBottomSheet<void>(
          host,
          large: true,
          builder: (_) => const SizedBox(height: 200, child: Text('Large')),
        ),
      );
      await tester.pump();
      await tester.pump(AppMotion.page);
      final route = ModalRoute.of(tester.element(find.text('Large')))!;
      expect(route.animation!.isCompleted, isFalse);
      await tester.pump(AppMotion.slow - AppMotion.page);
      await tester.pump(tick);
      expect(route.animation!.isCompleted, isTrue);
      expect(route.reverseTransitionDuration, AppMotion.medium);
      Navigator.of(host).pop();
      await tester.pump();
      await tester.pump(AppMotion.medium);
      await tester.pump(tick);
      await tester.pump(tick);
      expect(find.text('Large'), findsNothing);
    });
  });

  group('language veil (B3-04)', () {
    testWidgets('covers what sits above the routes (the banner); taps wait', (
      tester,
    ) async {
      final commit = Completer<void>();
      var bannerTaps = 0;
      late BuildContext page;
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => LocaleSwapVeilHost(
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => bannerTaps++,
                  child: const SizedBox(
                    height: 48,
                    width: double.infinity,
                    child: Text('Offline banner'),
                  ),
                ),
                Expanded(child: child!),
              ],
            ),
          ),
          home: Builder(
            builder: (context) {
              page = context;
              return const Scaffold();
            },
          ),
        ),
      );

      var done = false;
      unawaited(
        LocaleSwapVeil.run(
          page,
          color: Colors.white,
          commit: () => commit.future,
        ).then((_) => done = true),
      );
      await tester.pump();
      await tester.pump(AppMotion.fast);

      // Over the banner, above the navigator (not in the route's overlay).
      final veil = find.byType(LocaleSwapVeilView);
      expect(veil, findsOneWidget);
      expect(
        find.ancestor(of: veil, matching: find.byType(Navigator)),
        findsNothing,
      );
      expect(
        tester
            .getRect(veil)
            .contains(tester.getCenter(find.text('Offline banner'))),
        isTrue,
      );
      final opacity = tester
          .widget<FadeTransition>(
            find.descendant(of: veil, matching: find.byType(FadeTransition)),
          )
          .opacity
          .value;
      expect(opacity, 1);
      await tester.tapAt(tester.getCenter(find.text('Offline banner')));
      expect(bannerTaps, 0);

      commit.complete();
      // Commit, one frame for the new locale, then the fade out.
      for (var i = 0; i < 30; i++) {
        await tester.pump(tick);
      }
      expect(done, isTrue);
      expect(veil, findsNothing);
      await tester.tapAt(tester.getCenter(find.text('Offline banner')));
      expect(bannerTaps, 1);
    });

    testWidgets('without a host it still veils the routes (root overlay)', (
      tester,
    ) async {
      late BuildContext page;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              page = context;
              return const Scaffold();
            },
          ),
        ),
      );
      final commit = Completer<void>();
      unawaited(
        LocaleSwapVeil.run(
          page,
          color: Colors.white,
          commit: () => commit.future,
        ),
      );
      await tester.pump();
      await tester.pump(AppMotion.fast);
      expect(find.byType(LocaleSwapVeilView), findsOneWidget);
      expect(
        find.ancestor(
          of: find.byType(LocaleSwapVeilView),
          matching: find.byType(Overlay),
        ),
        findsWidgets,
      );
      commit.complete();
      // Commit, one frame for the new locale, then the fade out.
      for (var i = 0; i < 30; i++) {
        await tester.pump(tick);
      }
      expect(find.byType(LocaleSwapVeilView), findsNothing);
    });
  });
}
