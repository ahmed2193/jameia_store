// PopScale and StaggerEntrance used to build a CurvedAnimation inside
// build(): each rebuild hung one more listener on the controller and none was
// ever disposed. StaggerEntrance also waited with an uncancellable
// Future.delayed, so an item disposed early left a timer running.
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/motion/pop_scale.dart';
import 'package:jameia_mart/src/core/motion/stagger_entrance.dart';

Widget _host(Widget child) => MediaQuery(
  data: const MediaQueryData(),
  child: Directionality(textDirection: TextDirection.ltr, child: child),
);

void main() {
  testWidgets('PopScale disposes every CurvedAnimation it creates', (
    tester,
  ) async {
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

    for (var i = 0; i < 20; i++) {
      await tester.pumpWidget(_host(PopScale(popKey: 1, child: Text('$i'))));
    }
    await tester.pumpWidget(const SizedBox());

    expect(created, lessThanOrEqualTo(1));
    expect(disposed, created);
  });

  testWidgets('StaggerEntrance leaves no timer when disposed early', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const StaggerEntrance(index: 5, child: Text('late item'))),
    );
    await tester.pumpWidget(const SizedBox());
    // Ending here fails the test if the stagger delay is still pending.
  });

  testWidgets('StaggerEntrance still plays after its delay', (tester) async {
    await tester.pumpWidget(
      _host(const StaggerEntrance(index: 2, child: Text('item'))),
    );
    final fade = tester.widget<FadeTransition>(find.byType(FadeTransition));
    expect(fade.opacity.value, 0);
    await tester.pumpAndSettle();
    expect(fade.opacity.value, 1);
  });
}
