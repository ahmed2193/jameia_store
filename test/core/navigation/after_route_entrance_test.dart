import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/navigation/after_route_entrance.dart';

void main() {
  const entrance = AfterRouteEntrance(
    placeholder: Text('placeholder'),
    child: Text('map'),
  );

  testWidgets('a route that is already in builds the child at once', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: entrance));

    expect(find.text('map'), findsOneWidget);
    expect(find.text('placeholder'), findsNothing);
  });

  testWidgets('no route builds the child at once', (tester) async {
    await tester.pumpWidget(
      const Directionality(textDirection: TextDirection.ltr, child: entrance),
    );

    expect(find.text('map'), findsOneWidget);
  });

  testWidgets('the placeholder while the route slides in, the child once in', (
    tester,
  ) async {
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(navigatorKey: navigator, home: const SizedBox.shrink()),
    );

    unawaited(
      navigator.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => entrance),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('placeholder'), findsOneWidget);
    expect(find.text('map'), findsNothing);

    await tester.pumpAndSettle();

    expect(find.text('map'), findsOneWidget);
    expect(find.text('placeholder'), findsNothing);
  });
}
