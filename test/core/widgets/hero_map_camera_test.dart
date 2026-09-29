// B1-12: the native map camera never reads Flutter's reduced-motion flag, so
// every programmatic move goes through HeroMapCamera.glideTo — a glide
// normally, a jump (moveCamera) under reduced motion.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/widgets/hero_map.dart';

/// Records which camera call ran; every other member is unused here.
class _RecordingController implements GoogleMapController {
  final List<Symbol> calls = <Symbol>[];

  @override
  dynamic noSuchMethod(Invocation invocation) {
    calls.add(invocation.memberName);
    return Future<void>.value();
  }
}

void main() {
  Future<BuildContext> pumpContext(
    WidgetTester tester, {
    required bool reduced,
  }) async {
    late BuildContext captured;
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(disableAnimations: reduced),
        child: Builder(
          builder: (context) {
            captured = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    return captured;
  }

  final update = CameraUpdate.newLatLng(const LatLng(29.37, 47.98));

  testWidgets('glides the camera normally', (tester) async {
    final context = await pumpContext(tester, reduced: false);
    final map = _RecordingController();

    await map.glideTo(context, update);

    expect(map.calls, [#animateCamera]);
  });

  testWidgets('jumps the camera under reduced motion', (tester) async {
    final context = await pumpContext(tester, reduced: true);
    final map = _RecordingController();

    await map.glideTo(context, update);

    expect(map.calls, [#moveCamera]);
  });
}
