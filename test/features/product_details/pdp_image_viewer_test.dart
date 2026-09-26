// The full-screen photo viewer, talabat-mart style: light grey, a round
// close button at the reading start that pops with the photo shown, the dots
// pill, and a strip of thumbnails (the current one outlined in the brand
// colour) that brings a photo up. One photo: no dots, no strip.
import 'dart:convert';

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
// ignore: implementation_imports
import 'package:easy_localization/src/localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:jameia_mart/src/config/theme/app_colors.dart';
import 'package:jameia_mart/src/core/widgets/round_outlined_button.dart';
import 'package:jameia_mart/src/features/product_details/presentation/pages/pdp_image_viewer_page.dart';
import 'package:jameia_mart/src/features/product_details/presentation/widgets/pdp_dots_pill.dart';
import 'package:jameia_mart/src/features/product_details/presentation/widgets/pdp_thumbnail.dart';
import 'package:jameia_mart/src/features/product_details/presentation/widgets/pdp_thumbnail_strip.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pdp_test_fakes.dart';

const List<String> _photos = ['a.jpg', 'b.jpg', 'c.jpg', 'd.jpg', 'e.jpg'];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    final enRaw = await rootBundle.loadString('assets/i18n/en.json');
    Localization.load(
      const Locale('en'),
      translations: Translations(
        withNewProductKeys(json.decode(enRaw) as Map<String, dynamic>, 'en'),
      ),
    );
  });

  late int? returned;
  late bool popped;

  /// Opens the viewer on [initialIndex] over a home page, the way the
  /// product page pushes it (awaiting the page it pops with).
  Future<void> openViewer(
    WidgetTester tester, {
    List<String> images = _photos,
    int initialIndex = 1,
    TextDirection direction = TextDirection.ltr,
    bool reducedMotion = false,
    double width = 390,
    double textScale = 1,
  }) async {
    tester.view.physicalSize = Size(width * 3, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    returned = null;
    popped = false;
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const Scaffold()),
        GoRoute(
          path: '/viewer',
          builder: (context, _) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              disableAnimations: reducedMotion,
              textScaler: TextScaler.linear(textScale),
            ),
            child: Directionality(
              textDirection: direction,
              child: PdpImageViewerPage(
                images: images,
                initialIndex: initialIndex,
              ),
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

  final thumbnails = find.byType(PdpThumbnail);

  List<bool> outlined(WidgetTester tester) => [
    for (final thumb in tester.widgetList<PdpThumbnail>(thumbnails))
      thumb.selected,
  ];

  testWidgets('light grey, no app bar, a round close at the reading start', (
    tester,
  ) async {
    await openViewer(tester);

    expect(
      tester.widget<Scaffold>(find.byType(Scaffold).last).backgroundColor,
      AppColors.smallBackground,
    );
    expect(find.byType(AppBar), findsNothing);
    final close = find.byType(RoundOutlinedButton);
    expect(close, findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    expect(tester.getCenter(close).dx, lessThan(390 / 2));
    expect(tester.getCenter(close).dy, lessThan(2532 / 3 / 4));
    expect(tester.widget<PdpDotsPill>(find.byType(PdpDotsPill)).count, 5);
    expect(find.byType(PdpThumbnailStrip), findsOneWidget);
  });

  testWidgets('close pops with the photo it was left on', (tester) async {
    await openViewer(tester, initialIndex: 2);

    await tester.tap(find.byType(RoundOutlinedButton));
    await settle(tester);
    expect(popped, isTrue);
    expect(returned, 2);
    expect(find.byType(PdpImageViewerPage), findsNothing);
  });

  testWidgets('a thumbnail brings its photo up, outlined', (tester) async {
    await openViewer(tester);
    final semantics = tester.ensureSemantics();

    expect(thumbnails, findsNWidgets(_photos.length));
    expect(outlined(tester), [false, true, false, false, false]);
    final ring =
        (tester
                        .widget<AnimatedContainer>(
                          find.descendant(
                            of: thumbnails.at(1),
                            matching: find.byType(AnimatedContainer),
                          ),
                        )
                        .decoration!
                    as BoxDecoration)
                .border!
            as Border;
    expect(ring.top.color, AppColors.primary);
    expect(ring.top.width, PdpThumbnail.ring);
    expect(find.bySemanticsLabel('Image 2/5'), findsWidgets);

    await tester.tap(thumbnails.at(3));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    // It glides there.
    expect(outlined(tester)[3], isFalse);
    await settle(tester);
    expect(outlined(tester), [false, false, false, true, false]);

    // A swipe moves the outline too.
    await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
    await settle(tester);
    expect(outlined(tester), [false, false, false, false, true]);

    await tester.tap(find.byType(RoundOutlinedButton));
    await settle(tester);
    expect(returned, 4);
    semantics.dispose();
  });

  testWidgets('reduced motion: the photo changes at once', (tester) async {
    await openViewer(tester, reducedMotion: true);

    await tester.tap(thumbnails.at(4));
    await tester.pump();
    expect(outlined(tester), [false, false, false, false, true]);
  });

  testWidgets('the strip keeps the current thumbnail in view', (tester) async {
    await openViewer(tester, images: [for (var i = 0; i < 12; i++) '$i.jpg']);
    final strip = tester.getRect(find.byType(PdpThumbnailStrip));
    final pager = tester.widget<PageView>(find.byType(PageView)).controller!;
    Finder thumbnail(int index) => find.byKey(ValueKey<int>(index));

    void expectInView(int index) {
      final rect = tester.getRect(thumbnail(index));
      expect(rect.left, greaterThanOrEqualTo(strip.left));
      expect(rect.right, lessThanOrEqualTo(strip.right));
      expect(tester.widget<PdpThumbnail>(thumbnail(index)).selected, isTrue);
    }

    // Far past the thumbnails the strip shows at first…
    expect(thumbnail(10), findsNothing);
    pager.jumpToPage(10);
    await settle(tester);
    expectInView(10);

    // …and back to the first one.
    pager.jumpToPage(0);
    await settle(tester);
    expectInView(0);
  });

  testWidgets('one photo: no dots, no strip', (tester) async {
    await openViewer(tester, images: const ['a.jpg'], initialIndex: 0);

    expect(find.byType(PdpDotsPill), findsNothing);
    expect(find.byType(PdpThumbnailStrip), findsNothing);
    expect(find.byType(RoundOutlinedButton), findsOneWidget);
  });

  testWidgets('right to left: close at the right, the strip from the right', (
    tester,
  ) async {
    await openViewer(tester, direction: TextDirection.rtl, initialIndex: 0);

    expect(
      tester.getCenter(find.byType(RoundOutlinedButton)).dx,
      greaterThan(390 / 2),
    );
    expect(
      tester.getCenter(thumbnails.at(0)).dx,
      greaterThan(tester.getCenter(thumbnails.at(1)).dx),
    );
  });

  testWidgets('a 320 dp phone at text scale 1.3: nothing overflows', (
    tester,
  ) async {
    await openViewer(tester, width: 320, textScale: 1.3);
    expect(tester.takeException(), isNull);
    await tester.tap(thumbnails.at(3));
    await settle(tester);
    expect(tester.takeException(), isNull);
  });
}

/// Lets every transition and glide run out.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
