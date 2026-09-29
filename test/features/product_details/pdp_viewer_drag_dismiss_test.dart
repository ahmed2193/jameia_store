// Drag down to dismiss on the photo viewer (docs/motion B2-08): a drag down
// on a photo at rest pulls the viewer with the finger (the product page shows
// through); past the threshold it closes with the photo it was left on, short
// of it the viewer springs back; a zoomed photo pans instead.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hero_mart/src/core/navigation/navigation.dart';
import 'package:hero_mart/src/features/product_details/presentation/pages/pdp_image_viewer_page.dart';
import 'package:hero_mart/src/features/product_details/presentation/widgets/pdp_viewer_dismiss_drag.dart';
import 'package:hero_mart/src/features/product_details/presentation/widgets/pdp_zoomable_photo.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pdp_test_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await speakEnglish();
  });

  late int? returned;
  late bool popped;

  /// Opens the viewer as the app does: a slide-up page over the product.
  Future<void> openViewer(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(390 * 3, 2532)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    returned = null;
    popped = false;
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('product')),
        ),
        GoRoute(
          path: '/viewer',
          pageBuilder: (_, state) => HeroSlideUpTransitionPage<Object?>(
            key: state.pageKey,
            child: const PdpImageViewerPage(
              images: ['a.jpg', 'b.jpg', 'c.jpg'],
              initialIndex: 1,
              productSlug: 'milk',
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    router.push<int>('/viewer').then((value) {
      returned = value;
      popped = true;
    });
    await settle(tester);
  }

  final photo = find.byType(PdpZoomablePhoto);

  testWidgets('a drag past the threshold closes with the photo shown', (
    tester,
  ) async {
    await openViewer(tester);
    final height = tester.view.physicalSize.height / 3;

    final gesture = await tester.startGesture(tester.getCenter(photo.first));
    for (var i = 0; i < 20; i++) {
      await gesture.moveBy(Offset(0, height * 0.02));
      await tester.pump(const Duration(milliseconds: 40));
    }
    // Mid-pull: the viewer follows the finger down, the product shows.
    expect(find.text('product'), findsOneWidget);
    expect(
      tester.getTopLeft(find.byType(PdpImageViewerPage)).dy,
      greaterThan(0),
    );
    await gesture.up();
    await settle(tester);

    expect(popped, isTrue);
    expect(returned, 1);
    expect(find.byType(PdpImageViewerPage), findsNothing);
  });

  testWidgets('a short drag springs back', (tester) async {
    await openViewer(tester);
    final height = tester.view.physicalSize.height / 3;

    final gesture = await tester.startGesture(tester.getCenter(photo.first));
    for (var i = 0; i < 10; i++) {
      await gesture.moveBy(
        Offset(0, height * PdpViewerDismissDrag.dismissShare / 10),
      );
      await tester.pump(const Duration(milliseconds: 60));
    }
    await gesture.up();
    await settle(tester);

    expect(popped, isFalse);
    expect(find.byType(PdpImageViewerPage), findsOneWidget);
    expect(tester.getTopLeft(find.byType(PdpImageViewerPage)).dy, 0);
  });

  testWidgets('reduced motion: a fling closes at once', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(reduceMotion: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await openViewer(tester);

    await tester.fling(photo.first, const Offset(0, 300), 1500);
    await tester.pump();
    await tester.pump();

    expect(popped, isTrue);
    expect(returned, 1);
    expect(find.byType(PdpImageViewerPage), findsNothing);
  });
}
