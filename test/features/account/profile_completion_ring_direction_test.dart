// B1-20: the profile completion ring grows in the reading direction —
// clockwise from twelve o'clock, counter-clockwise under RTL.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/features/account/presentation/widgets/profile/profile_completion_ring_painter.dart';

Widget _ring(TextDirection direction) => Center(
  child: SizedBox.square(
    dimension: 80,
    child: CustomPaint(
      painter: ProfileCompletionRingPainter(
        progress: 0.25,
        color: Colors.white,
        trackColor: Colors.black,
        strokeWidth: 6,
        textDirection: direction,
      ),
    ),
  ),
);

void main() {
  testWidgets('LTR: clockwise', (tester) async {
    await tester.pumpWidget(_ring(TextDirection.ltr));
    expect(
      find.byType(CustomPaint).last,
      paints..arc(sweepAngle: 0.25 * 2 * 3.141592653589793),
    );
  });

  testWidgets('RTL: counter-clockwise', (tester) async {
    await tester.pumpWidget(_ring(TextDirection.rtl));
    expect(
      find.byType(CustomPaint).last,
      paints..arc(sweepAngle: -0.25 * 2 * 3.141592653589793),
    );
  });
}
