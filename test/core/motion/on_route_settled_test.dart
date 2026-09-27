// OnRouteSettled: `settled` is false while the route is still arriving, true
// once its entrance completes (or right after the first frame when there is
// nothing to wait for), and the one status listener it holds on the route's
// animation is released on completion and on dispose.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/motion/on_route_settled.dart';

/// The route's entrance, counting the status listeners hung on it.
class _CountingAnimation extends Animation<double>
    with AnimationWithParentMixin<double> {
  _CountingAnimation(this.parent);

  @override
  final Animation<double> parent;

  int statusListeners = 0;

  @override
  double get value => parent.value;

  @override
  void addStatusListener(AnimationStatusListener listener) {
    statusListeners++;
    super.addStatusListener(listener);
  }

  @override
  void removeStatusListener(AnimationStatusListener listener) {
    statusListeners--;
    super.removeStatusListener(listener);
  }
}

/// A page route whose public entrance counts its status listeners.
class _CountingRoute extends MaterialPageRoute<void> {
  _CountingRoute({required super.builder});

  _CountingAnimation? _counting;

  _CountingAnimation get counting => _counting!;

  @override
  Animation<double>? get animation {
    final entrance = super.animation;
    if (entrance == null) return null;
    return _counting ??= _CountingAnimation(entrance);
  }
}

Widget _label() => OnRouteSettled(
  builder: (context, settled) => Text(settled ? 'settled' : 'arriving'),
);

void main() {
  testWidgets('false while the route arrives, true once it has', (
    tester,
  ) async {
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(navigatorKey: navigator, home: const SizedBox()),
    );

    navigator.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => _label()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('arriving'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('settled'), findsOneWidget);
  });

  testWidgets('an arrived route (or none) settles on the next frame', (
    tester,
  ) async {
    await tester.pumpWidget(MaterialApp(home: _label()));
    expect(find.text('arriving'), findsOneWidget);
    await tester.pump();
    expect(find.text('settled'), findsOneWidget);

    await tester.pumpWidget(
      Directionality(textDirection: TextDirection.ltr, child: _label()),
    );
    // A new tree: a new widget with its own first frame.
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: KeyedSubtree(key: UniqueKey(), child: _label()),
      ),
    );
    expect(find.text('arriving'), findsOneWidget);
    await tester.pump();
    expect(find.text('settled'), findsOneWidget);
  });

  testWidgets('the listener is released when the entrance completes', (
    tester,
  ) async {
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(navigatorKey: navigator, home: const SizedBox()),
    );
    final route = _CountingRoute(builder: (_) => _label());
    navigator.currentState!.push(route);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    final whileArriving = route.counting.statusListeners;

    await tester.pumpAndSettle();
    expect(find.text('settled'), findsOneWidget);
    expect(route.counting.statusListeners, whileArriving - 1);
  });

  testWidgets('the listener is released on dispose', (tester) async {
    final navigator = GlobalKey<NavigatorState>();
    final shown = ValueNotifier<bool>(true);
    addTearDown(shown.dispose);
    await tester.pumpWidget(
      MaterialApp(navigatorKey: navigator, home: const SizedBox()),
    );
    final route = _CountingRoute(
      builder: (_) => ValueListenableBuilder<bool>(
        valueListenable: shown,
        builder: (_, show, _) => show ? _label() : const SizedBox.shrink(),
      ),
    );
    navigator.currentState!.push(route);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    final whileArriving = route.counting.statusListeners;

    shown.value = false;
    await tester.pump();
    expect(route.counting.statusListeners, whileArriving - 1);

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
