// The Home tab's brand icon: the app icon's cart mark, resting as a
// one-colour glyph and lighting up as the app icon itself.
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/design/jameia_cart_mark.dart';
import 'package:jameia_mart/src/core/motion/motion.dart';
import 'package:jameia_mart/src/core/widgets/jameia_mark_icon.dart';
import 'package:jameia_mart/src/core/widgets/jameia_mark_icon_painter.dart';

const Color _ink = Color(0xFF123456);
const double _side = 30;

Widget _host({required bool active, bool reduced = false}) => MediaQuery(
  data: MediaQueryData(disableAnimations: reduced),
  child: Center(
    child: IconTheme(
      data: const IconThemeData(color: _ink, size: _side),
      child: JameiaMarkIcon(active: active),
    ),
  ),
);

JameiaMarkIconPainter _painter(WidgetTester tester) {
  final paint = tester.widget<CustomPaint>(
    find.descendant(
      of: find.byType(JameiaMarkIcon),
      matching: find.byType(CustomPaint),
    ),
  );
  return paint.painter! as JameiaMarkIconPainter;
}

void main() {
  testWidgets('takes its size and colour from the IconTheme, like an Icon', (
    tester,
  ) async {
    await tester.pumpWidget(_host(active: false));

    expect(
      tester.getSize(find.byType(JameiaMarkIcon)),
      const Size.square(_side),
    );
    expect(_painter(tester).ink, _ink);
    expect(_painter(tester).progress, 0);
  });

  testWidgets('grows into the app icon, hopping on the way, when active', (
    tester,
  ) async {
    await tester.pumpWidget(_host(active: false));
    await tester.pumpWidget(_host(active: true));
    await tester.pump(AppMotion.popup ~/ 2);

    final midway = _painter(tester);
    expect(midway.progress, inExclusiveRange(0, 1));
    expect(midway.hop, isTrue);

    await tester.pumpAndSettle();
    expect(_painter(tester).progress, 1);

    // Back to rest without a hop.
    await tester.pumpWidget(_host(active: false));
    await tester.pump(AppMotion.popup ~/ 2);
    expect(_painter(tester).hop, isFalse);
    await tester.pumpAndSettle();
    expect(_painter(tester).progress, 0);
  });

  testWidgets('switches at once under reduced motion', (tester) async {
    await tester.pumpWidget(_host(active: false, reduced: true));
    await tester.pumpWidget(_host(active: true, reduced: true));
    await tester.pump();

    expect(_painter(tester).progress, 1);
  });

  test('paints both ends and the blend between them', () {
    for (final progress in [0.0, 0.5, 1.0]) {
      final recorder = ui.PictureRecorder();
      JameiaMarkIconPainter(
        progress: progress,
        ink: _ink,
        hop: true,
      ).paint(Canvas(recorder), const Size.square(_side));
      expect(recorder.endRecording(), isNotNull);
    }
  });

  test('repaints only when what it draws changes', () {
    const rest = JameiaMarkIconPainter(progress: 0, ink: _ink);
    expect(
      rest.shouldRepaint(const JameiaMarkIconPainter(progress: 0, ink: _ink)),
      isFalse,
    );
    expect(
      rest.shouldRepaint(const JameiaMarkIconPainter(progress: 0.5, ink: _ink)),
      isTrue,
    );
    expect(
      rest.shouldRepaint(
        const JameiaMarkIconPainter(progress: 0, ink: Color(0xFF000000)),
      ),
      isTrue,
    );
  });

  test('the one-colour bowl has the slats cut out as holes', () {
    const depth = JameiaCartMark.slatTop + JameiaCartMark.slatWidth;
    final slats = JameiaCartMark.slatCenters;
    final probe = Offset(slats[1], depth); // on the middle slat
    expect(JameiaCartMark.bowl.contains(probe), isTrue);
    expect(JameiaCartMark.slats.contains(probe), isTrue);
    expect(JameiaCartMark.bowlCutOut.contains(probe), isFalse);

    final between = Offset((slats[0] + slats[1]) / 2, depth);
    expect(JameiaCartMark.bowlCutOut.contains(between), isTrue);
    expect(JameiaCartMark.slats.contains(between), isFalse);
  });
}
