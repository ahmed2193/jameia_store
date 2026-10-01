// BrandMark: an official brand mark drawn as its owner ships it — an SVG
// mark through SvgPicture, a raster mark through Image — never tinted and
// left out of the semantics tree.
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/design/hero_assets.dart';
import 'package:hero_mart/src/core/widgets/brand_mark.dart';

Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.rtl,
  child: Center(child: child),
);

void main() {
  testWidgets('an .svg mark is an untinted, unmirrored SvgPicture', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const BrandMark(HeroAssets.brandFacebook, size: 24)),
    );

    expect(find.byType(Image), findsNothing);
    final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
    expect(
      (svg.bytesLoader as SvgAssetLoader).assetName,
      HeroAssets.brandFacebook,
    );
    expect(svg.colorFilter, isNull);
    expect(svg.matchTextDirection, isFalse);
    expect(svg.excludeFromSemantics, isTrue);
    expect(svg.width, 24);
    expect(svg.height, 24);
  });

  testWidgets('a raster mark is an untinted Image of the asset', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const BrandMark(HeroAssets.brandGoogle, size: 24)),
    );

    expect(find.byType(SvgPicture), findsNothing);
    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as AssetImage).assetName, HeroAssets.brandGoogle);
    expect(image.color, isNull);
    expect(image.matchTextDirection, isFalse);
    expect(image.excludeFromSemantics, isTrue);
    expect(image.width, 24);
    expect(image.height, 24);
  });

  test('every brand constant resolves to the right drawing path', () {
    for (final asset in [
      HeroAssets.brandFacebook,
      HeroAssets.brandInstagram,
      HeroAssets.brandX,
    ]) {
      expect(BrandMark(asset, size: 24).isVector, isTrue, reason: asset);
    }
    for (final asset in [HeroAssets.brandGoogle, HeroAssets.brandApple]) {
      expect(BrandMark(asset, size: 24).isVector, isFalse, reason: asset);
    }
  });
}
