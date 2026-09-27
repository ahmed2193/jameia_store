import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/responsive/app_size.dart';
import 'package:hero_mart/src/core/widgets/hero_cdn_transform.dart';
import 'package:hero_mart/src/core/widgets/hero_image.dart';

Widget _host(Widget child) => MediaQuery(
  data: const MediaQueryData(),
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: Center(child: child),
  ),
);

void main() {
  group('HeroImage', () {
    testWidgets('empty url renders the sized placeholder icon tile', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const HeroImage(url: '', width: 60, height: 40)),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.image_outlined));
      expect(icon.size, AppSize.s28);
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
      await tester.pumpWidget(
        _host(const HeroImage.circle(url: '', size: 40)),
      );

      expect(tester.getSize(find.byType(HeroImage)), const Size(40, 40));
      expect(
        find.descendant(
          of: find.byType(ClipOval),
          matching: find.byIcon(Icons.image_outlined),
        ),
        findsOneWidget,
      );
    });
  });

  group('HeroCdnTransform', () {
    test('leaves non-CDN hosts untouched', () {
      const url = 'https://example.com/a.png';
      expect(
        HeroCdnTransform.apply(
          url: url,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          dpr: 3,
        ),
        url,
      );
    });

    test('collapses duplicate slashes and appends DPR-capped params', () {
      final result = HeroCdnTransform.apply(
        url: 'https://media.jm3eia.com//img//a.png',
        width: 100,
        height: null,
        fit: BoxFit.contain,
        dpr: 3,
      );
      expect(
        result,
        'https://media.jm3eia.com/img/a.png?w=200&fit=contain&format=webp',
      );
    });

    test('without dims returns only the slash-normalised url', () {
      expect(
        HeroCdnTransform.apply(
          url: 'https://media.jm3eia.com//img/a.png',
          width: null,
          height: null,
          fit: BoxFit.cover,
          dpr: 2,
        ),
        'https://media.jm3eia.com/img/a.png',
      );
    });
  });
}
