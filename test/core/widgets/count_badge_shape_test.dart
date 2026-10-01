// The count pill keeps its shape: it hugs its number (a host row taller
// than it never stretches it into a capsule), one digit sits in a true
// circle at any text size, and more digits make a pill.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/widgets/at_least_square.dart';
import 'package:hero_mart/src/core/widgets/count_badge.dart';

const Color _red = Color(0xFFE53935);

Widget _host(Widget child, {double textScale = 1}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
    child: Scaffold(body: Center(child: child)),
  ),
);

Size _pill(WidgetTester tester) => tester.getSize(find.byType(AtLeastSquare));

void main() {
  group('CountBadge', () {
    testWidgets('a row taller than the pill never stretches it', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const SizedBox(
            height: 52,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [CountBadge(count: 3, color: _red, minSize: 20)],
            ),
          ),
        ),
      );
      final pill = _pill(tester);
      expect(pill.height, lessThan(52));
      expect(pill.width, pill.height);
    });

    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets('one digit is a circle at text scale $scale; two make a '
          'pill', (tester) async {
        await tester.pumpWidget(
          _host(const CountBadge(count: 7, color: _red), textScale: scale),
        );
        final circle = _pill(tester);
        expect(circle.width, circle.height);

        await tester.pumpWidget(
          _host(const CountBadge(count: 42, color: _red), textScale: scale),
        );
        await tester.pump(const Duration(seconds: 1));
        final pill = _pill(tester);
        expect(pill.width, greaterThan(pill.height));
      });
    }

    testWidgets('the pill grows with its number (12 → 99+)', (tester) async {
      await tester.pumpWidget(_host(const CountBadge(count: 12, color: _red)));
      final two = _pill(tester);
      await tester.pumpWidget(_host(const CountBadge(count: 120, color: _red)));
      await tester.pump(const Duration(seconds: 1));
      expect(_pill(tester).width, greaterThan(two.width));
      expect(_pill(tester).height, two.height);
    });

    testWidgets('never smaller than minSize', (tester) async {
      await tester.pumpWidget(
        _host(const CountBadge(count: 1, color: _red, minSize: 24)),
      );
      final pill = _pill(tester);
      expect(pill.width, greaterThanOrEqualTo(24));
      expect(pill.height, greaterThanOrEqualTo(24));
    });
  });

  group('AtLeastSquare', () {
    Future<Size> lay(
      WidgetTester tester,
      Size child, {
      bool square = false,
    }) async {
      await tester.pumpWidget(
        Center(
          child: AtLeastSquare(
            square: square,
            child: SizedBox.fromSize(size: child),
          ),
        ),
      );
      return tester.getSize(find.byType(AtLeastSquare));
    }

    testWidgets('a narrow child is widened to its height', (tester) async {
      expect(await lay(tester, const Size(10, 20)), const Size(20, 20));
    });

    testWidgets('a child that changes after layout still reaches the box', (
      tester,
    ) async {
      expect(await lay(tester, const Size(10, 20)), const Size(20, 20));
      expect(await lay(tester, const Size(40, 20)), const Size(40, 20));
      expect(await lay(tester, const Size(10, 20)), const Size(20, 20));
      expect(await lay(tester, const Size(10, 24)), const Size(24, 24));
    });

    testWidgets('a wide child keeps its width', (tester) async {
      expect(await lay(tester, const Size(30, 20)), const Size(30, 20));
    });

    testWidgets('square: the longer side wins both ways', (tester) async {
      expect(
        await lay(tester, const Size(30, 20), square: true),
        const Size(30, 30),
      );
      expect(
        await lay(tester, const Size(10, 20), square: true),
        const Size(20, 20),
      );
    });
  });
}
