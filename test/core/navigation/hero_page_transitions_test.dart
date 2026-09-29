// The Hero page family (core/navigation): the forward push is the shared X
// axis (in from the end edge, the covered page back toward the start,
// mirrored in RTL), reduced motion drops the slide, a modal holds the page
// below still, and the back gestures drive the route: Android predictive
// back shrinks the page with the finger and pops on commit (never through a
// PopScope), the iOS edge swipe pops past half the width.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hero_mart/src/core/navigation/navigation.dart';

/// Translations along X of every [Transform] above the text [label].
Iterable<double> _shiftsOf(WidgetTester tester, String label) => tester
    .widgetList<Transform>(
      find.ancestor(of: find.text(label), matching: find.byType(Transform)),
    )
    .map((t) => t.transform.getTranslation().x);

/// X scales of every [Transform] above the text [label].
Iterable<double> _scalesOf(WidgetTester tester, String label) => tester
    .widgetList<Transform>(
      find.ancestor(of: find.text(label), matching: find.byType(Transform)),
    )
    .map((t) => t.transform.storage[0]);

Future<GoRouter> _pumpApp(
  WidgetTester tester, {
  TextDirection direction = TextDirection.ltr,
  TargetPlatform platform = TargetPlatform.android,
  bool modal = false,
  bool blockBack = false,
}) async {
  Widget next = const Scaffold(body: Center(child: Text('next')));
  if (blockBack) next = PopScope<Object?>(canPop: false, child: next);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (_, state) => HeroTransitionPage<Object?>(
          key: state.pageKey,
          child: const Scaffold(body: Center(child: Text('home'))),
        ),
      ),
      GoRoute(
        path: '/next',
        pageBuilder: (_, state) => modal
            ? HeroSlideUpTransitionPage<Object?>(
                key: state.pageKey,
                child: next,
              )
            : HeroTransitionPage<Object?>(key: state.pageKey, child: next),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    MaterialApp.router(
      theme: ThemeData(platform: platform),
      routerConfig: router,
      builder: (context, child) =>
          Directionality(textDirection: direction, child: child!),
    ),
  );
  return router;
}

Future<void> _backGesture(String method, [Map<String, Object?>? args]) async {
  final message = SystemChannels.backGesture.codec.encodeMethodCall(
    MethodCall(method, args),
  );
  await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .handlePlatformMessage(SystemChannels.backGesture.name, message, (_) {});
}

Map<String, Object?> _backEvent(double progress) => <String, Object?>{
  'touchOffset': <double>[5, 300],
  'progress': progress,
  'swipeEdge': 0, // left
};

void main() {
  group('HeroTransitionPage (shared X axis)', () {
    testWidgets('LTR: comes in from the right, the covered page moves left', (
      tester,
    ) async {
      final router = await _pumpApp(tester);
      router.push('/next');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      expect(_shiftsOf(tester, 'next').any((x) => x > 0), isTrue);
      expect(_shiftsOf(tester, 'next').any((x) => x < 0), isFalse);
      expect(_shiftsOf(tester, 'home').any((x) => x < 0), isTrue);

      await tester.pumpAndSettle();
      expect(_shiftsOf(tester, 'next').every((x) => x == 0), isTrue);
    });

    testWidgets('RTL: mirrored — in from the left, the covered page right', (
      tester,
    ) async {
      final router = await _pumpApp(tester, direction: TextDirection.rtl);
      router.push('/next');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      expect(_shiftsOf(tester, 'next').any((x) => x < 0), isTrue);
      expect(_shiftsOf(tester, 'next').any((x) => x > 0), isFalse);
      expect(_shiftsOf(tester, 'home').any((x) => x > 0), isTrue);
      await tester.pumpAndSettle();
    });

    testWidgets('reduced motion: a fade, no slide', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(reduceMotion: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final router = await _pumpApp(tester);
      router.push('/next');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(_shiftsOf(tester, 'next').every((x) => x == 0), isTrue);
      expect(_shiftsOf(tester, 'home').every((x) => x == 0), isTrue);
      final fades = tester
          .widgetList<FadeTransition>(
            find.ancestor(
              of: find.text('next'),
              matching: find.byType(FadeTransition),
            ),
          )
          .map((f) => f.opacity.value);
      expect(fades.any((o) => o > 0 && o < 1), isTrue);
      await tester.pumpAndSettle();
    });

    testWidgets('animations off: a cut', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final router = await _pumpApp(tester);
      router.push('/next');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(_shiftsOf(tester, 'next').every((x) => x == 0), isTrue);
      expect(
        find.ancestor(
          of: find.text('next'),
          matching: find.byType(FadeTransition),
        ),
        findsNothing,
      );
      await tester.pumpAndSettle();
    });
  });

  testWidgets('a modal slides up and leaves the page below still', (
    tester,
  ) async {
    final router = await _pumpApp(tester, modal: true);
    router.push('/next');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    expect(_shiftsOf(tester, 'home').every((x) => x == 0), isTrue);
    expect(
      tester.getTopLeft(find.text('next')).dy,
      greaterThan(tester.getTopLeft(find.text('home')).dy),
    );
    await tester.pumpAndSettle();
  });

  group('Android predictive back', () {
    testWidgets('the page shrinks with the finger and pops on commit', (
      tester,
    ) async {
      final router = await _pumpApp(tester);
      router.push('/next');
      await tester.pumpAndSettle();

      await _backGesture('startBackGesture', _backEvent(0));
      await _backGesture('updateBackGestureProgress', _backEvent(0.5));
      await tester.pump();
      expect(_scalesOf(tester, 'next').any((s) => s < 1), isTrue);
      expect(_shiftsOf(tester, 'next').any((x) => x > 0), isTrue);
      // The page below shows at rest behind it.
      expect(find.text('home'), findsOneWidget);
      expect(_shiftsOf(tester, 'home').every((x) => x == 0), isTrue);

      await _backGesture('commitBackGesture');
      await tester.pumpAndSettle();
      expect(find.text('next'), findsNothing);
      expect(router.state.uri.path, '/');
    });

    testWidgets('a cancel settles the page back', (tester) async {
      final router = await _pumpApp(tester);
      router.push('/next');
      await tester.pumpAndSettle();

      await _backGesture('startBackGesture', _backEvent(0));
      await _backGesture('updateBackGestureProgress', _backEvent(0.4));
      await tester.pump();
      await _backGesture('cancelBackGesture');
      await tester.pumpAndSettle();

      expect(find.text('next'), findsOneWidget);
      expect(_scalesOf(tester, 'next').every((s) => s == 1), isTrue);
      expect(router.state.uri.path, '/next');
    });

    testWidgets('a PopScope keeps the page still (it decides on back)', (
      tester,
    ) async {
      final router = await _pumpApp(tester, blockBack: true);
      router.push('/next');
      await tester.pumpAndSettle();

      await _backGesture('startBackGesture', _backEvent(0));
      await _backGesture('updateBackGestureProgress', _backEvent(0.5));
      await tester.pump();
      expect(_scalesOf(tester, 'next').every((s) => s == 1), isTrue);
      await _backGesture('cancelBackGesture');
      await tester.pumpAndSettle();
      expect(find.text('next'), findsOneWidget);
    });
  });

  group('iOS edge swipe', () {
    testWidgets('past half the width pops', (tester) async {
      final router = await _pumpApp(tester, platform: TargetPlatform.iOS);
      router.push('/next');
      await tester.pumpAndSettle();

      await tester.timedDragFrom(
        const Offset(5, 300),
        const Offset(500, 0),
        const Duration(seconds: 1),
      );
      await tester.pumpAndSettle();
      expect(find.text('next'), findsNothing);
      expect(router.state.uri.path, '/');
    });

    testWidgets('a short swipe settles back', (tester) async {
      final router = await _pumpApp(tester, platform: TargetPlatform.iOS);
      router.push('/next');
      await tester.pumpAndSettle();

      await tester.timedDragFrom(
        const Offset(5, 300),
        const Offset(150, 0),
        const Duration(seconds: 1),
      );
      await tester.pumpAndSettle();
      expect(find.text('next'), findsOneWidget);
      expect(router.state.uri.path, '/next');
    });

    testWidgets('RTL: the swipe starts at the right edge', (tester) async {
      final router = await _pumpApp(
        tester,
        platform: TargetPlatform.iOS,
        direction: TextDirection.rtl,
      );
      router.push('/next');
      await tester.pumpAndSettle();

      await tester.timedDragFrom(
        const Offset(795, 300),
        const Offset(-500, 0),
        const Duration(seconds: 1),
      );
      await tester.pumpAndSettle();
      expect(find.text('next'), findsNothing);
    });
  });
}
