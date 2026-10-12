// Locks the image key policy (lib/src/core/media/image_key_policy.dart),
// ported from the reference app with its tests:
//   * the bucket ladder: snapping up, the 50 floor, the 900 ceiling of the
//     layout-driven path, the 2048 ceiling of an explicit memCache override,
//     and at most 2 rungs per audited size cluster;
//   * ONE dpr rule for the default size and for caller memCache overrides;
//   * the tight-axis rule (only known axes are sent) and aspect preservation;
//   * URL canonicalisation and the asset id; host-less strings resolve against
//     the CDN only when they are dated image paths, never for junk — including
//     the spelling Hero's offline catalogue produces (`mediaBase` + `//YYYY/…`);
//   * ImageVariant: one fixed param order, cacheKey == resolvedUrl, raw
//     fallback.
// (The widget half — two sizes sharing one key on screen — is Stage B's.)

import 'package:flutter/painting.dart' show BoxFit;
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/media/image_key_policy.dart';

const String _cdn = 'https://media.jm3eia.com';

ImageVariant _v(String url, int? w, int? h) =>
    ImageVariant.of(url, wireW: w, wireH: h, fit: 'cover', format: 'webp');

void main() {
  group('ladder', () {
    test(
      'shape: 50..2048, increasing in ≈×1.2 steps, rungs at 270 and 900',
      () {
        expect(kWidthLadder.first, 50);
        expect(kWidthLadder.last, kMaxOverridePx);
        expect(kWidthLadder, contains(270));
        expect(kWidthLadder, contains(kMaxWirePx));
        expect(kWidthLadder.skipWhile((int r) => r <= kMaxWirePx), <int>[
          1080,
          1296,
          1555,
          1866,
          2048,
        ]);
        for (int i = 1; i < kWidthLadder.length; i++) {
          final double step = kWidthLadder[i] / kWidthLadder[i - 1];
          // 1.09: the last hop, 1866 → 2048, stops at the CDN's own maximum.
          expect(step, inInclusiveRange(1.09, 1.3), reason: 'step $i');
        }
      },
    );

    test('bucketWidth snaps UP to a rung, clamped to 50..900', () {
      expect(bucketWidth(270), 270); // exact rung
      expect(bucketWidth(271), 324); // one above
      expect(bucketWidth(269), 270);
      expect(bucketWidth(51), 64);
      expect(bucketWidth(50), 50);
      expect(bucketWidth(1), 50); // floor
      expect(bucketWidth(0), 50);
      expect(bucketWidth(900), 900);
      expect(bucketWidth(901), 900); // ceiling
      expect(bucketWidth(5000), 900);
      for (int px = 1; px <= 900; px++) {
        // Never below the painted pixels → never blurrier.
        expect(bucketWidth(px), greaterThanOrEqualTo(px));
        expect(kWidthLadder, contains(bucketWidth(px)));
      }
    });

    test('bucketWidth(max: kMaxOverridePx) climbs past 900 up to 2048', () {
      int up(int px) => bucketWidth(px, max: kMaxOverridePx);
      expect(up(901), 1080);
      expect(up(1080), 1080);
      expect(up(1200), 1296);
      expect(up(1297), 1555);
      expect(up(1556), 1866);
      expect(up(1867), 2048);
      expect(up(2048), 2048);
      expect(up(2049), 2048); // ceiling
      expect(up(9000), 2048);
      expect(up(1), 50); // floor
      // Below the default ceiling both paths agree.
      for (int px = 1; px <= 900; px++) {
        expect(up(px), bucketWidth(px), reason: '$px');
      }
      for (int px = 1; px <= 2048; px++) {
        expect(up(px), greaterThanOrEqualTo(px), reason: 'never blurrier');
        expect(kWidthLadder, contains(up(px)));
      }
      // A cap that is not a rung falls back to the largest rung under it.
      expect(bucketWidth(5000, max: 1000), 900);
    });

    test('every audited size cluster spans at most 2 rungs', () {
      const List<List<int>> clusters = <List<int>>[
        <int>[50, 60],
        <int>[67, 100],
        <int>[112, 128],
        <int>[144, 185],
        <int>[200, 238],
        <int>[216, 264],
        <int>[252, 298],
        <int>[280, 372],
        <int>[500, 642],
        <int>[656, 824],
      ];
      for (final List<int> c in clusters) {
        final Set<int> rungs = <int>{
          for (int px = c[0]; px <= c[1]; px++) bucketWidth(px),
        };
        expect(rungs.length, lessThanOrEqualTo(2), reason: '$c → $rungs');
      }
      // A 3-column product grid (229-264 px) is ONE rung.
      expect(
        <int>{for (int px = 229; px <= 264; px++) bucketWidth(px)},
        <int>{270},
      );
    });
  });

  group('dpr rule', () {
    test('a 120-dp tile is one rung at dpr 2.0, 2.75, 3.0 and 3.5', () {
      for (final double dpr in <double>[2.0, 2.75, 3.0, 3.5]) {
        expect(decodePx(120, dpr), 270, reason: 'dpr $dpr');
      }
      expect(decodePx(120, 1.0), 122);
    });

    test('a memCache override lands on the default path rung', () {
      // memCacheWidth: 144 on a dpr-3 phone is the 48-dp tile: 96 px → 100.
      expect(wireSizeFor(pixelW: 144, pixelH: 144, dpr: 3), (w: 100, h: 100));
      expect(wireSizeFor(logicalW: 48, logicalH: 48, dpr: 3), (w: 100, h: 100));
      // A 120-dp cap at dpr 2.75 = 330 px.
      expect(wireSizeFor(pixelW: 330, dpr: 2.75).w, decodePx(120, 2.75));
      // One-axis override + layout axis: square like the box.
      final ({int? w, int? h}) row = wireSizeFor(
        logicalW: 126,
        logicalH: 126,
        pixelW: 347,
        dpr: 2.75,
      );
      expect(row, (w: 270, h: 270));
    });
  });

  group('override ceiling', () {
    test('the layout-driven path stops at 900', () {
      // 1024 logical at dpr 2 = 2048 px asked by the layout → still 900.
      expect(wireSizeFor(logicalW: 1024, dpr: 2).w, 900);
      expect(wireSizeFor(logicalH: 1024, dpr: 2).h, 900);
      expect(wireSizeFor(logicalW: 1024, logicalH: 1024, dpr: 2), (
        w: 900,
        h: 900,
      ));
      expect(decodePx(1024, 2), 900);
    });

    test('an explicit override climbs to the 2048 rung', () {
      expect(wireSizeFor(pixelW: 2048, dpr: 2).w, 2048);
      expect(wireSizeFor(pixelH: 2048, dpr: 2).h, 2048);
      expect(wireSizeFor(pixelW: 1200, dpr: 2).w, 1296);
      expect(wireSizeFor(pixelW: 5000, dpr: 2).w, 2048); // ceiling
      // Below 900 an override is exactly the default path.
      expect(wireSizeFor(pixelW: 330, dpr: 2.75).w, decodePx(120, 2.75));
    });

    test('an override still goes through logical px and min(dpr, 2)', () {
      // 2048 px at dpr 3 = 682.7 logical × 2 = 1365 px → 1555, not 2048.
      expect(wireSizeFor(pixelW: 2048, dpr: 3).w, 1555);
      // 1200 px at dpr 3 = 400 logical × 2 = 800 px → 900 (the default rung).
      expect(wireSizeFor(pixelW: 1200, dpr: 3).w, 900);
      // dpr 1 is not boosted: 1200 px stays 1200 → 1296.
      expect(wireSizeFor(pixelW: 1200, dpr: 1).w, 1296);
    });

    test('a full-screen viewer keeps the screen aspect on both axes', () {
      // A 393×852 dp, dpr-3 phone asking for its screen pixels: 1179×2556.
      final ({int? w, int? h}) s = wireSizeFor(
        logicalW: 393,
        logicalH: 852,
        pixelW: 1179,
        pixelH: 2556,
        dpr: 3,
      );
      expect(s.w, 900); // 786 px → 900
      expect(s.h, 1951); // 900 × 1704 / 786, no longer capped to 900
      expect(s.h! / s.w!, closeTo(1704 / 786, 0.5 / s.w!));
    });

    test('only the axis the caller sized may exceed 900', () {
      expect(wireSizeFor(logicalH: 1500, dpr: 1).h, 900);
      expect(wireSizeFor(pixelH: 1500, dpr: 1).h, 1555);
      // Layout width + override height: the width stays on the default cap.
      final ({int? w, int? h}) s = wireSizeFor(
        logicalW: 1000,
        pixelH: 2000,
        dpr: 1,
      );
      expect(s.w, 900);
      expect(s.h, lessThanOrEqualTo(kMaxOverridePx));
      expect(
        bucketHeightFor(bucketW: 900, rawW: 1000, rawH: 2000, max: 2048),
        1800,
      );
      expect(bucketHeightFor(bucketW: 900, rawW: 1000, rawH: 2000), 900);
    });
  });

  group('wire size', () {
    test('tight-axis: only the known axis is sent', () {
      expect(wireSizeFor(logicalW: 100, dpr: 2), (w: 225, h: null));
      expect(wireSizeFor(logicalH: 100, dpr: 2), (w: null, h: 225));
      expect(wireSizeFor(dpr: 2), (w: null, h: null));
      expect(wireSizeFor(logicalW: double.infinity, logicalH: 0, dpr: 2), (
        w: null,
        h: null,
      ));
    });

    test('both axes: the box aspect is kept at the bucketed width', () {
      const List<List<double>> boxes = <List<double>>[
        <double>[100, 80],
        <double>[115, 102],
        <double>[336, 136],
        <double>[60, 60],
        <double>[250, 150],
        <double>[126, 126],
        <double>[360, 400],
        <double>[44, 30],
      ];
      for (final List<double> box in boxes) {
        final int rawW = (box[0] * 2).round();
        final int rawH = (box[1] * 2).round();
        final ({int? w, int? h}) s = wireSizeFor(
          logicalW: box[0],
          logicalH: box[1],
          dpr: 2,
        );
        expect(s.w, bucketWidth(rawW), reason: '$box');
        expect(
          s.h! / s.w!,
          closeTo(rawH / rawW, 0.5 / s.w! + 1e-9),
          reason: '$box → $s',
        );
        expect(s.h, greaterThanOrEqualTo(rawH), reason: 'never blurrier');
      }
    });

    test('cdnFitParam speaks the CDN vocabulary', () {
      expect(cdnFitParam(BoxFit.cover), 'cover');
      expect(cdnFitParam(BoxFit.none), 'cover');
      expect(cdnFitParam(BoxFit.contain), 'contain');
      expect(cdnFitParam(BoxFit.scaleDown), 'contain');
      expect(cdnFitParam(BoxFit.fill), 'fill');
      expect(cdnFitParam(BoxFit.fitWidth), 'inside');
      expect(cdnFitParam(BoxFit.fitHeight), 'inside');
    });
  });

  group('canonicalImageUrl', () {
    const String c = '$_cdn/2026/9/30/94dec2d5.jpeg';

    test('every spelling of one CDN asset collapses to one', () {
      for (final String s in <String>[
        c,
        '  $c  ',
        '$_cdn//2026/9/30/94dec2d5.jpeg', // the API / catalogue spelling
        '$_cdn/2026//9///30/94dec2d5.jpeg',
        'http://media.jm3eia.com/2026/9/30/94dec2d5.jpeg',
        'HTTPS://Media.JM3EIA.com/2026/9/30/94dec2d5.jpeg',
        '/2026/9/30/94dec2d5.jpeg',
        '2026/9/30/94dec2d5.jpeg',
        '//2026/9/30/94dec2d5.jpeg', // a catalogue `i` / `img` value as is
        '//media.jm3eia.com/2026/9/30/94dec2d5.jpeg', // protocol-relative
        '$c?',
      ]) {
        expect(canonicalImageUrl(s), c, reason: s);
        expect(
          canonicalImageUrl(canonicalImageUrl(s)),
          c,
          reason: 'idempotent',
        );
      }
    });

    test('the path keeps its case; a host-less png resolves too', () {
      expect(
        canonicalImageUrl('$_cdn/2026/A/Photo.JPEG'),
        '$_cdn/2026/A/Photo.JPEG',
      );
      expect(
        canonicalImageUrl('2026/9/30/Logo.PNG'),
        '$_cdn/2026/9/30/Logo.PNG',
      );
    });

    test('host-less: only dated CDN image paths resolve against the CDN', () {
      expect(canonicalImageUrl('2026/3/25/x.jpeg'), '$_cdn/2026/3/25/x.jpeg');
      expect(canonicalImageUrl('/2026/3/25/x.jpeg'), '$_cdn/2026/3/25/x.jpeg');
      expect(
        canonicalImageUrl('  /2026/3/25/x.jpeg '),
        '$_cdn/2026/3/25/x.jpeg',
      );
      expect(canonicalImageUrl('/2026//3/25/x.jpeg'), '$_cdn/2026/3/25/x.jpeg');
      expect(
        canonicalImageUrl('/2026/3/25/x.png?v=1'),
        '$_cdn/2026/3/25/x.png?v=1',
      );

      // Junk would fetch the CDN's soft-404 (a blank PNG, immutable for a
      // year): returned unchanged, so it fails to load and keeps the
      // placeholder.
      for (final String s in <String>[
        'null',
        'default',
        'images',
        'undefined',
        'N/A',
        'logo.png', // a lone file name
        '/images/logo.png',
        '/supplier/12/logo.png',
        'supplier/42/logo.png',
        '/2026/3/25/', // a folder, not a file
        '/2026/3/25/readme.txt',
        '/2025/11/15/971920be.jpegس', // a stray-character picture
      ]) {
        expect(canonicalImageUrl(s), s, reason: s);
        expect(isMediaUrl(canonicalImageUrl(s)), isFalse, reason: s);
      }
      expect(canonicalImageUrl('  null '), 'null');

      // Protocol-relative keeps its host.
      expect(
        canonicalImageUrl('//cdn.example.com/a.png'),
        'https://cdn.example.com/a.png',
      );
    });

    test('non-CDN absolute URLs are only slash-normalised', () {
      const String unsplash =
          'https://images.unsplash.com/photo-1?w=400&h=400&fit=crop';
      expect(canonicalImageUrl(unsplash), unsplash);
      expect(
        canonicalImageUrl('https://example.com//images//a.png'),
        'https://example.com/images/a.png',
      );
      expect(
        canonicalImageUrl('http://Example.com/A.png?'),
        'http://Example.com/A.png?',
      );
    });

    test('a backend query is kept; empty stays empty', () {
      expect(
        canonicalImageUrl('$_cdn//a/b.jpeg?token=x'),
        '$_cdn/a/b.jpeg?token=x',
      );
      expect(canonicalImageUrl(''), '');
      expect(canonicalImageUrl('   '), '');
    });

    test('assetId strips the query; isMediaUrl spots the CDN', () {
      expect(assetId('$c?w=270&h=270&fit=cover&format=webp'), c);
      expect(assetId(c), c);
      expect(isMediaUrl(c), isTrue);
      expect(isMediaUrl('https://example.com/images/a.png'), isFalse);
    });

    test('normalizeSlashes keeps the scheme and the query', () {
      expect(
        normalizeSlashes('https://host//a//b?x=//1'),
        'https://host/a/b?x=//1',
      );
      const String clean = 'https://host/a/b';
      expect(identical(normalizeSlashes(clean), clean), isTrue);
      expect(normalizeSlashes('no-scheme//a'), 'no-scheme//a');
    });
  });

  group('ImageVariant', () {
    test('w, h, fit, format in one fixed order; cacheKey == resolvedUrl', () {
      final ImageVariant a = _v('$_cdn/a/b.jpeg', 270, 270);
      expect(a.resolvedUrl, '$_cdn/a/b.jpeg?w=270&h=270&fit=cover&format=webp');
      expect(a.cacheKey, a.resolvedUrl);
      expect(a.assetId, '$_cdn/a/b.jpeg');
      // Stale transform params, in any order, are replaced: same key.
      final ImageVariant b = _v(
        '$_cdn/a/b.jpeg?format=png&fit=fill&h=9&w=9',
        270,
        270,
      );
      expect(b.cacheKey, a.cacheKey);
    });

    test('only known axes are sent; no size still carries fit + format', () {
      expect(
        _v('$_cdn/a.jpeg', 324, null).resolvedUrl,
        '$_cdn/a.jpeg?w=324&fit=cover&format=webp',
      );
      expect(
        _v('$_cdn/a.jpeg', null, 225).resolvedUrl,
        '$_cdn/a.jpeg?h=225&fit=cover&format=webp',
      );
      expect(
        _v('$_cdn/a.jpeg', null, null).resolvedUrl,
        '$_cdn/a.jpeg?fit=cover&format=webp',
      );
    });

    test('raw fallback: no transform params, one file for every size', () {
      final ImageVariant small = _v('$_cdn/a/b.jpeg', 100, 100);
      final ImageVariant big = _v('$_cdn/a/b.jpeg', 764, 764);
      expect(small.rawUrl, '$_cdn/a/b.jpeg');
      expect(big.rawUrl, small.rawUrl);
      expect(small.cacheKey == big.cacheKey, isFalse);
      final ImageVariant signed = _v('$_cdn/a/b.jpeg?token=t', 100, 100);
      expect(signed.rawUrl, '$_cdn/a/b.jpeg?token=t');
      expect(
        signed.resolvedUrl,
        '$_cdn/a/b.jpeg?token=t&w=100&h=100&fit=cover&format=webp',
      );
    });

    test('value equality', () {
      expect(_v('$_cdn/a.jpeg', 270, 270), _v('$_cdn/a.jpeg', 270, 270));
      expect(
        _v('$_cdn/a.jpeg', 270, 270).hashCode,
        _v('$_cdn/a.jpeg', 270, 270).hashCode,
      );
      expect(
        _v('$_cdn/a.jpeg', 270, 270) == _v('$_cdn/a.jpeg', 270, 324),
        isFalse,
      );
    });
  });
}
