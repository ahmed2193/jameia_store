import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/media/image_key_policy.dart';
import 'package:hero_mart/src/core/widgets/hero_image.dart';
import 'package:hero_mart/src/core/widgets/hero_image_placeholder.dart';

Widget _host(Widget child) => MediaQuery(
  data: const MediaQueryData(),
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: Center(child: child),
  ),
);

void main() {
  group('HeroImage', () {
    testWidgets('empty url renders the sized brand placeholder', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const HeroImage(url: '', width: 60, height: 40)),
      );

      // The grey fill with the bag outline, 40 % of the short side.
      expect(find.byType(HeroImagePlaceholder), findsOneWidget);
      final glyph = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(glyph.width, 40 * 0.4);
      expect(find.byIcon(Icons.image_outlined), findsNothing);
      expect(tester.getSize(find.byType(HeroImage)), const Size(60, 40));
      expect(
        find.descendant(
          of: find.byType(HeroImage),
          matching: find.byType(RepaintBoundary),
        ),
        findsWidgets,
      );
      expect(find.byType(ClipOval), findsNothing);
    });

    testWidgets('circle wraps the repaint boundary in a ClipOval', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const HeroImage.circle(url: '', size: 40)));

      expect(tester.getSize(find.byType(HeroImage)), const Size(40, 40));
      expect(
        find.descendant(
          of: find.byType(ClipOval),
          matching: find.byType(HeroImagePlaceholder),
        ),
        findsOneWidget,
      );
    });
  });

  // The CDN URL a HeroImage requests (HeroImage.cdnUrl = the widget's own key
  // policy). The full contract is test/core/widgets/hero_image/
  // hero_image_cdn_url_test.dart; these are the cases the old
  // HeroCdnTransform locked, on the new contract (sizes go through the
  // ladder, `wireSizeFor`, so no rung is hard-coded here).
  group('HeroImage.cdnUrl', () {
    test('leaves non-CDN hosts untouched', () {
      const url = 'https://example.com/a.png';
      expect(HeroImage.cdnUrl(url: url, width: 100, height: 100, dpr: 3), url);
    });

    test('collapses duplicate slashes and appends DPR-capped params', () {
      final result = HeroImage.cdnUrl(
        url: 'https://media.jm3eia.com//img//a.png',
        width: 100,
        height: null,
        fit: BoxFit.contain,
        dpr: 3,
      );
      // 100 dp × min(3, 2) = 200 px, snapped up to its ladder rung.
      final wire = wireSizeFor(logicalW: 100, dpr: 3);
      expect(wire.w, bucketWidth(200));
      expect(wire.h, isNull);
      expect(
        result,
        'https://media.jm3eia.com/img/a.png'
        '?w=${wire.w}&fit=contain&format=webp',
      );
      // The dpr cap: a dpr-3 phone asks what a dpr-2 phone asks.
      expect(
        HeroImage.cdnUrl(
          url: 'https://media.jm3eia.com//img//a.png',
          width: 100,
          height: null,
          fit: BoxFit.contain,
          dpr: 2,
        ),
        result,
      );
    });

    test('without dims: the slash-normalised url, still fit + webp', () {
      // The new contract: a CDN url never leaves as its source file, even
      // with no size (the old transform returned it bare).
      expect(
        HeroImage.cdnUrl(
          url: 'https://media.jm3eia.com//img/a.png',
          width: null,
          height: null,
          dpr: 2,
        ),
        'https://media.jm3eia.com/img/a.png?fit=cover&format=webp',
      );
    });
  });
}
