// Locks the CDN URL contract every HeroImage request satisfies (ported from
// the reference's test/core/app_image_cdn_url_test.dart;
// docs/image_pipeline.md):
//
//   https://media.jm3eia.com/<path>?w=<px>&h=<px>&fit=<mode>&format=webp
//
//   1. A media.jm3eia.com URL always leaves with `fit` + `format=webp`, even
//      with no size hint: never the source JPEG / PNG.
//   2. Wire == decode: the size on the wire is the size Skia decodes to
//      (the mounted CachedNetworkImage's memCacheWidth/Height).
//   3. Never a dimension the layout didn't fix: an axis neither given nor
//      tight is neither sent nor decoded to.
//   4. Ladder rungs: `logical × min(dpr, 2)` — or a memCacheWidth/Height
//      override turned back into logical px — snapped UP to a rung of
//      kWidthLadder (50..900 for a layout size; an override up to 2048); with
//      both axes the height keeps the box's aspect at that width.
//   5. Non-CDN hosts are left alone (only `//` is repaired); host-less junk
//      never becomes a CDN URL.
//   6. A transform-broken asset goes raw at every size and spelling.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/media/hero_image_cache_manager.dart';
import 'package:hero_mart/src/core/media/image_cdn_transform.dart';
import 'package:hero_mart/src/core/media/image_key_policy.dart';
import 'package:hero_mart/src/core/media/image_prefetch_variant.dart';
import 'package:hero_mart/src/core/widgets/hero_image.dart';

import 'hero_image_test_support.dart';

Map<String, String> _params(String url) => Uri.parse(url).queryParameters;

String _url({
  required String url,
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
  double dpr = 2,
  int? memCacheWidth,
  int? memCacheHeight,
}) => HeroImage.cdnUrl(
  url: url,
  width: width,
  height: height,
  fit: fit,
  dpr: dpr,
  memCacheWidth: memCacheWidth,
  memCacheHeight: memCacheHeight,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpImagePipeline();

  group('HeroImage.cdnUrl — fit + format', () {
    test('both dimensions: w, h, fit and format=webp', () {
      final Map<String, String> p = _params(
        _url(
          url: '$cdn/2026/3/25/fc91473529979bf8.jpeg',
          width: 200,
          height: 100,
        ),
      );
      expect(p['format'], 'webp');
      expect(p['fit'], 'cover');
      // 200 dp × 2 = 400 px → rung 467; the 2:1 box at that width: 233.5 → 234.
      expect(p['w'], '467');
      expect(p['h'], '234');
    });

    test('format=webp and fit even with NO size hint at all', () {
      final Map<String, String> p = _params(
        _url(url: '$cdn/2026/3/25/nosize.jpeg'),
      );
      expect(p['format'], 'webp');
      expect(p['fit'], 'cover');
      expect(p.containsKey('w'), isFalse);
      expect(p.containsKey('h'), isFalse);
    });

    test('only the axis it knows', () {
      final Map<String, String> p = _params(
        _url(url: '$cdn/2026/3/25/wonly.jpeg', width: 150),
      );
      expect(p['w'], '324'); // 150 × 2 = 300 px → rung 324
      expect(p.containsKey('h'), isFalse);
      expect(p['format'], 'webp');
    });

    test('every CDN URL carries fit + format=webp, whatever the source', () {
      for (final String ext in <String>['jpeg', 'png', 'gif', 'webp']) {
        for (final BoxFit fit in BoxFit.values) {
          for (final (double?, double?) size in const <(double?, double?)>[
            (null, null),
            (64, null),
            (null, 64),
            (175, 120),
          ]) {
            final String u = _url(
              url: '$cdn/2026/3/25/any.$ext',
              width: size.$1,
              height: size.$2,
              fit: fit,
            );
            expect(_params(u)['format'], 'webp', reason: u);
            expect(_params(u)['fit'], cdnFitParam(fit), reason: u);
          }
        }
      }
    });

    test('BoxFit maps onto the CDN fit vocabulary', () {
      String fitOf(BoxFit f) => _params(
        _url(
          url: '$cdn/2026/3/25/fit-${f.name}.jpeg',
          width: 100,
          height: 100,
          fit: f,
        ),
      )['fit']!;

      expect(fitOf(BoxFit.cover), 'cover');
      expect(fitOf(BoxFit.contain), 'contain');
      expect(fitOf(BoxFit.scaleDown), 'contain');
      expect(fitOf(BoxFit.fill), 'fill');
      expect(fitOf(BoxFit.fitWidth), 'inside');
      expect(fitOf(BoxFit.fitHeight), 'inside');
      expect(fitOf(BoxFit.none), 'cover');
    });
  });

  group('HeroImage.cdnUrl — ladder sizing', () {
    test('memCacheWidth/Height beat the logical size × dpr', () {
      final Map<String, String> p = _params(
        _url(
          url: '$cdn/2026/3/25/exact.jpeg',
          width: 200,
          height: 100,
          memCacheWidth: 333,
          memCacheHeight: 222,
        ),
      );
      // 333 px → rung 389; the height keeps 333:222 → 259. The logical size
      // alone would be 467 × 234.
      expect(p['w'], '389');
      expect(p['h'], '259');
    });

    test('memCacheWidth alone sizes by width and keeps the art\'s ratio', () {
      final Map<String, String> p = _params(
        _url(
          url: '$cdn/2026/3/25/push.jpeg',
          fit: BoxFit.contain,
          memCacheWidth: 1024,
        ),
      );
      // An explicit decode size is not cut at 900: up to the 1080 rung.
      expect(p['w'], '1080');
      expect(p.containsKey('h'), isFalse);
      expect(p['fit'], 'contain');
      expect(p['format'], 'webp');
    });

    test('dpr is capped at 2', () {
      final String at3x = _url(
        url: '$cdn/2026/3/25/dpr.jpeg',
        width: 100,
        height: 100,
        dpr: 3.5,
      );
      expect(_params(at3x)['w'], '225'); // 200 px, not 350 → 389
      expect(
        at3x,
        _url(url: '$cdn/2026/3/25/dpr.jpeg', width: 100, height: 100),
        reason: 'one variant for every dpr ≥ 2',
      );
    });

    test('an override obeys the same dpr cap as the logical size', () {
      // memCacheWidth 144 on a dpr-3 phone is the 48-dp default (96 px →
      // rung 100), not a third variant at 144 → 150.
      final String byOverride = _url(
        url: '$cdn/2026/3/25/override.jpeg',
        dpr: 3,
        memCacheWidth: 144,
        memCacheHeight: 144,
      );
      final String byLayout = _url(
        url: '$cdn/2026/3/25/override.jpeg',
        width: 48,
        height: 48,
        dpr: 3,
      );
      expect(_params(byOverride)['w'], '100');
      expect(byOverride, byLayout);
    });

    test('a layout size stops at 900; only an override goes past', () {
      final String byLayout = _url(
        url: '$cdn/2026/3/25/wide.jpeg',
        width: 1024,
        height: 1024,
      );
      expect(_params(byLayout)['w'], '900');
      expect(_params(byLayout)['h'], '900');
      final String byOverride = _url(
        url: '$cdn/2026/3/25/wide.jpeg',
        width: 1024,
        height: 1024,
        memCacheWidth: 2048,
        memCacheHeight: 2048,
      );
      expect(_params(byOverride)['w'], '2048');
      expect(_params(byOverride)['h'], '2048');
      // dpr 3 still obeys min(dpr, 2): 2048 px = 682.7 dp × 2 = 1365 → 1555.
      expect(
        _params(
          _url(url: '$cdn/2026/3/25/wide.jpeg', dpr: 3, memCacheWidth: 2048),
        )['w'],
        '1555',
      );
    });

    test('override sizes clamp to the 50..2048 wire bounds', () {
      expect(
        _params(
          _url(
            url: '$cdn/2026/3/25/tiny.jpeg',
            memCacheWidth: 4,
            memCacheHeight: 4,
          ),
        )['w'],
        '50',
      );
      final Map<String, String> huge = _params(
        _url(
          url: '$cdn/2026/3/25/huge.jpeg',
          memCacheWidth: 9000,
          memCacheHeight: 9000,
        ),
      );
      expect(huge['w'], '2048');
      expect(huge['h'], '2048');
    });

    test('every wire width is a ladder rung, every lone height too', () {
      for (final double dpr in <double>[1, 1.5, 2, 2.625, 3, 3.5]) {
        for (double dp = 4; dp <= 1200; dp += 7.5) {
          final String both = _url(
            url: '$cdn/2026/3/25/rung.jpeg',
            width: dp,
            height: dp * 0.75,
            dpr: dpr,
          );
          final String w = _params(both)['w']!;
          expect(kWidthLadder, contains(int.parse(w)), reason: both);
          expect(int.parse(w), lessThanOrEqualTo(kMaxWirePx), reason: both);
          final String lone = _url(
            url: '$cdn/2026/3/25/rung.jpeg',
            height: dp,
            dpr: dpr,
          );
          expect(
            kWidthLadder,
            contains(int.parse(_params(lone)['h']!)),
            reason: lone,
          );
        }
      }
    });
  });

  group('HeroImage.cdnUrl — URL hygiene', () {
    test('collapses the double slash every API CDN URL carries', () {
      final String u = _url(
        url: '$cdn//2022/1/1//photo.jpeg',
        width: 100,
        height: 100,
      );
      expect(u.startsWith('$cdn/2022/1/1/photo.jpeg?'), isTrue, reason: u);
    });

    test('host-less API paths resolve against the CDN and transform', () {
      final String u = _url(
        url: '/2026/9/30/rel.jpeg',
        width: 100,
        height: 100,
      );
      expect(u, '$cdn/2026/9/30/rel.jpeg?w=225&h=225&fit=cover&format=webp');
      expect(
        _url(
          url: 'HTTP://Media.JM3EIA.com/2026/9/30/rel.jpeg',
          width: 100,
          height: 100,
        ),
        u,
        reason: 'http + host case are one spelling; the path case is kept',
      );
    });

    test('host-less junk is NOT sent to the CDN', () {
      for (final String junk in <String>[
        'null',
        'default',
        'images',
        'logo.png',
      ]) {
        expect(_url(url: junk, width: 100, height: 100), junk, reason: junk);
        expect(ImageCdnTransform.raw(junk), junk, reason: junk);
      }
      // Protocol-relative keeps its own host (not ours: no transform).
      expect(
        _url(url: '//cdn.example.com/a.png', width: 100, height: 100),
        'https://cdn.example.com/a.png',
      );
    });

    test('keeps the backend\'s own query; transform params in ONE order', () {
      final String u = _url(
        url: '$cdn/2026/3/25/signed.jpeg?token=abc',
        width: 100,
        height: 100,
      );
      final Map<String, String> p = _params(u);
      expect(p['token'], 'abc');
      expect(p.keys.toList(), <String>['token', 'w', 'h', 'fit', 'format']);
    });

    test('leaves other hosts untouched; empty stays empty', () {
      const String other = 'https://cdn.example.com/a.jpg';
      expect(_url(url: other, width: 100, height: 100), other);
      expect(_url(url: '', width: 100, height: 100), '');
    });

    test('the raw fallback normalises slashes and adds nothing else', () {
      expect(
        ImageCdnTransform.raw('$cdn//2022/1/1//photo.jpeg'),
        '$cdn/2022/1/1/photo.jpeg',
      );
      expect(
        ImageCdnTransform.raw('2022/1/1/photo.jpeg'),
        '$cdn/2022/1/1/photo.jpeg',
      );
    });

    test('prefetchVariantFor is HeroImage.cdnUrl, byte for byte', () {
      for (final BoxFit fit in <BoxFit>[BoxFit.cover, BoxFit.contain]) {
        for (final double dpr in <double>[1, 2, 3]) {
          expect(
            prefetchVariantFor(
              rawUrl: '$cdn//2026/3/25/warm.jpeg',
              logicalW: 175,
              logicalH: 120,
              fit: fit,
              dpr: dpr,
            ),
            _url(
              url: '$cdn//2026/3/25/warm.jpeg',
              width: 175,
              height: 120,
              fit: fit,
              dpr: dpr,
            ),
          );
        }
      }
    });
  });

  group('ImageCdnTransform.markTransformBroken', () {
    test('every size of a broken asset goes raw', () {
      const String asset = '$cdn/2026/3/25/bad-exif.jpeg';
      expect(_params(_url(url: asset, width: 100, height: 100))['w'], '225');

      ImageCdnTransform.markTransformBroken('$asset?w=225&h=225&format=webp');

      expect(_url(url: asset, width: 100, height: 100), asset);
      expect(_url(url: asset, width: 400, height: 400), asset);
      expect(
        _params(
          _url(url: '$cdn/2026/3/25/good.jpeg', width: 100, height: 100),
        )['w'],
        '225',
        reason: 'other assets are unaffected',
      );
    });

    test('the verdict is keyed by asset id, whatever the spelling', () {
      ImageCdnTransform.markTransformBroken(
        '$cdn//2026/3/26/bad-exif-2.jpeg?w=270&h=270&fit=cover',
      );
      const String raw = '$cdn/2026/3/26/bad-exif-2.jpeg';
      expect(_url(url: raw, width: 60, height: 60), raw);
      expect(
        _url(url: '/2026/3/26/bad-exif-2.jpeg', width: 300, height: 150),
        raw,
      );
    });
  });

  // The mounted widget: the URL it fetches, the decode size it asks for and
  // the layout axes it adopts.
  group('a mounted HeroImage', () {
    setUp(() => HeroImageCacheManager.debugLoaderOverride = SilentLoader());

    Future<CachedNetworkImage> mount(WidgetTester t, Widget child) async {
      await t.pumpWidget(host(child));
      expect(t.takeException(), isNull);
      return cni(t);
    }

    void expectWireIsDecode(CachedNetworkImage image) {
      final Map<String, String> p = _params(image.imageUrl);
      expect(p['w'], image.memCacheWidth?.toString(), reason: image.imageUrl);
      expect(p['h'], image.memCacheHeight?.toString(), reason: image.imageUrl);
      expect(image.cacheKey, image.imageUrl);
    }

    testWidgets('wire == decode, with both axes given', (t) async {
      const String raw = '$cdn/2026/3/25/mounted.jpeg';
      final CachedNetworkImage image = await mount(
        t,
        const HeroImage(url: raw, width: 200, height: 100),
      );
      expect(image.imageUrl, _url(url: raw, width: 200, height: 100));
      expect((image.memCacheWidth, image.memCacheHeight), (467, 234));
      expectWireIsDecode(image);
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('wire == decode for an explicit override (a viewer)', (
      t,
    ) async {
      const String raw = '$cdn/2026/3/25/viewer.jpeg';
      final CachedNetworkImage image = await mount(
        t,
        const HeroImage(
          url: raw,
          width: 300,
          height: 300,
          fit: BoxFit.contain,
          memCacheWidth: 2048,
          memCacheHeight: 2048,
        ),
      );
      expect((image.memCacheWidth, image.memCacheHeight), (2048, 2048));
      expect(_params(image.imageUrl)['fit'], 'contain');
      expectWireIsDecode(image);
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('a LOOSE other axis is never sent nor decoded to', (t) async {
      const String raw = '$cdn/2026/3/25/loose.jpeg';
      final CachedNetworkImage image = await mount(
        t,
        const HeroImage(url: raw, width: 150),
      );
      expect(image.imageUrl, _url(url: raw, width: 150));
      expect(image.memCacheWidth, 324);
      expect(image.memCacheHeight, isNull);
      expectWireIsDecode(image);
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('an unbounded axis is never sent', (t) async {
      const String raw = '$cdn/2026/3/25/row.jpeg';
      final CachedNetworkImage image = await mount(
        t,
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[HeroImage(url: raw, height: 80)],
        ),
      );
      expect(image.memCacheWidth, isNull);
      expect(image.memCacheHeight, 185); // 160 px → rung 185
      expectWireIsDecode(image);
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('a TIGHT other axis is the box: adopted', (t) async {
      const String raw = '$cdn/2026/3/25/tight.jpeg';
      final CachedNetworkImage image = await mount(
        t,
        const SizedBox(height: 100, child: HeroImage(url: raw, width: 150)),
      );
      expect(image.imageUrl, _url(url: raw, width: 150, height: 100));
      expect((image.memCacheWidth, image.memCacheHeight), (324, 216));
      expectWireIsDecode(image);
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('no axis given: the finite box is the size', (t) async {
      const String raw = '$cdn/2026/3/25/boxed.jpeg';
      final CachedNetworkImage image = await mount(
        t,
        const SizedBox(width: 120, height: 90, child: HeroImage(url: raw)),
      );
      expect(image.imageUrl, _url(url: raw, width: 120, height: 90));
      expect((image.memCacheWidth, image.memCacheHeight), (270, 203));
      expectWireIsDecode(image);
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('a non-CDN host: fetched as is, never resized', (t) async {
      const String other = 'https://cdn.example.com/a.jpg';
      final CachedNetworkImage image = await mount(
        t,
        const HeroImage(url: other, width: 100, height: 100),
      );
      expect(image.imageUrl, other);
      // Decoded at the painted size all the same (wire == decode does not
      // apply: this host ignores w / h).
      expect((image.memCacheWidth, image.memCacheHeight), (225, 225));
      await t.pumpWidget(const SizedBox());
    });
  });
}
