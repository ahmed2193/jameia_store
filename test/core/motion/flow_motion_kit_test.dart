// The motion pieces the cart → checkout → orders flow is animated with:
// nothing plays on mount, blocks close drawing their last content, an
// entrance only runs for the first frame, a bar total keeps its roller
// mounted, a confetti overlay removes itself, and the page transition builds
// its curve once.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/design/hero_icons.dart';
import 'package:hero_mart/src/core/motion/change_bump.dart';
import 'package:hero_mart/src/core/motion/collapse_reveal.dart';
import 'package:hero_mart/src/core/motion/confetti_overlay.dart';
import 'package:hero_mart/src/core/motion/confetti_overlay_view.dart';
import 'package:hero_mart/src/core/motion/entrance_cascade.dart';
import 'package:hero_mart/src/core/motion/entrance_cascade_item.dart';
import 'package:hero_mart/src/core/motion/rolling_number.dart';
import 'package:hero_mart/src/core/navigation/hero_slide_fade_transition.dart';
import 'package:hero_mart/src/core/widgets/hero_bar_total.dart';

Widget _host(Widget child, {bool reduced = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduced),
    child: Scaffold(body: Center(child: child)),
  ),
);

void main() {
  group('CollapseReveal', () {
    testWidgets('closes drawing its last child, then builds nothing', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const CollapseReveal(visible: true, child: Text('offline'))),
      );
      expect(find.text('offline'), findsOneWidget);

      await tester.pumpWidget(
        _host(const CollapseReveal(visible: false, child: SizedBox.shrink())),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('offline'), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.text('offline'), findsNothing);
    });

    testWidgets('does not animate on mount', (tester) async {
      await tester.pumpWidget(
        _host(const CollapseReveal(visible: true, child: Text('reason'))),
      );
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  testWidgets('ChangeBump plays on a change only', (tester) async {
    await tester.pumpWidget(
      _host(const ChangeBump(value: 'a', child: Icon(HeroIcons.starFill))),
    );
    expect(tester.hasRunningAnimations, isFalse);

    await tester.pumpWidget(
      _host(const ChangeBump(value: 'b', child: Icon(HeroIcons.starFill))),
    );
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpAndSettle();
  });

  group('EntranceCascade', () {
    testWidgets('items of the first frame play, later ones are static', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const EntranceCascade(
            child: Column(
              children: [EntranceCascadeItem(index: 0, child: Text('first'))],
            ),
          ),
        ),
      );
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        _host(
          const EntranceCascade(
            child: Column(
              children: [
                EntranceCascadeItem(index: 0, child: Text('first')),
                EntranceCascadeItem(index: 1, child: Text('later')),
              ],
            ),
          ),
        ),
      );
      expect(tester.hasRunningAnimations, isFalse);
      expect(find.text('later'), findsOneWidget);
    });

    testWidgets('reduced motion shows the items as they are', (tester) async {
      await tester.pumpWidget(
        _host(
          const EntranceCascade(
            child: EntranceCascadeItem(index: 0, child: Text('first')),
          ),
          reduced: true,
        ),
      );
      expect(tester.hasRunningAnimations, isFalse);
      expect(
        find.descendant(
          of: find.byType(EntranceCascadeItem),
          matching: find.byType(FadeTransition),
        ),
        findsNothing,
      );
    });
  });

  testWidgets('HeroBarTotal keeps its roller across a pending state', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    Widget bar(double? kd) => _host(
      HeroBarTotal(
        kd: kd,
        placeholder: 'Updating…',
        style: const TextStyle(fontSize: 18),
      ),
    );
    await tester.pumpWidget(bar(3));
    final roller = tester.element(find.byType(RollingNumber));

    await tester.pumpWidget(bar(null));
    await tester.pumpAndSettle();
    expect(find.text('Updating…'), findsOneWidget);

    await tester.pumpWidget(bar(4.5));
    await tester.pumpAndSettle();
    expect(identical(tester.element(find.byType(RollingNumber)), roller), true);
    expect(find.bySemanticsLabel('KD 4.500'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('ConfettiOverlay plays once and removes itself', (tester) async {
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => ConfettiOverlay.play(
              context,
              colors: const [Colors.green, Colors.yellow],
              count: 8,
            ),
            child: const Text('place'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('place'));
    await tester.pump();
    expect(find.byType(ConfettiOverlayView), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byType(ConfettiOverlayView), findsNothing);
  });

  // Review fix O1: the finished burst's overlay entry is disposed, not only
  // removed (leak_tracker would flag it).
  testWidgets('ConfettiOverlay disposes its overlay entry', (tester) async {
    final created = <Object>{};
    final disposed = <Object>{};
    void track(ObjectEvent event) {
      if (event.object is! OverlayEntry) return;
      if (event is ObjectCreated) created.add(event.object);
      if (event is ObjectDisposed) disposed.add(event.object);
    }

    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => ConfettiOverlay.play(
              context,
              colors: const [Colors.green, Colors.yellow],
              count: 8,
            ),
            child: const Text('place'),
          ),
        ),
      ),
    );
    FlutterMemoryAllocations.instance.addListener(track);
    addTearDown(() => FlutterMemoryAllocations.instance.removeListener(track));
    await tester.tap(find.text('place'));
    await tester.pump();
    expect(created, hasLength(1));

    await tester.pumpAndSettle();
    expect(disposed, created);
  });

  testWidgets('the page transition builds its curve once', (tester) async {
    var created = 0;
    var disposed = 0;
    void onEvent(ObjectEvent event) {
      if (event.object is! CurvedAnimation) return;
      if (event is ObjectCreated) created++;
      if (event is ObjectDisposed) disposed++;
    }

    FlutterMemoryAllocations.instance.addListener(onEvent);
    addTearDown(
      () => FlutterMemoryAllocations.instance.removeListener(onEvent),
    );
    final controller = AnimationController(vsync: const TestVSync());
    addTearDown(controller.dispose);

    for (var i = 0; i < 10; i++) {
      controller.value = i / 10;
      // No MaterialApp: its own routes would add curves of their own.
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: HeroSlideFadeTransition(
              animation: controller,
              curve: Curves.easeOut,
              child: Text('page $i'),
            ),
          ),
        ),
      );
    }
    await tester.pumpWidget(const SizedBox());

    expect(created, 1);
    expect(disposed, created);
  });
}
