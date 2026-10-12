// Locks ImageVariantIndex (lib/src/core/media/image_variant_index.dart):
// per-asset variant records with rebuild dedupe, the nearest-size query the
// load policy builds on, the memory bounds, and clear() (the disk cache was
// emptied). (On-disk knowledge lives in ImageDiskIndex.)

import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/media/image_key_policy.dart';
import 'package:hero_mart/src/core/media/image_variant_index.dart';

const String _a = 'https://media.jm3eia.com/2026/1/a.jpeg';
const String _b = 'https://media.jm3eia.com/2026/1/b.jpeg';
const String _c = 'https://media.jm3eia.com/2026/1/c.jpeg';

ImageVariant _v(int? w, {int? h, String asset = _a}) => ImageVariant.of(
  asset,
  wireW: w,
  wireH: h ?? w,
  fit: 'cover',
  format: 'webp',
);

void main() {
  late ImageVariantIndex index;
  setUp(() => index = ImageVariantIndex());

  test('a rebuild (same or equal variant) is recorded once', () {
    final ImageVariant v = _v(270);
    index.record(_a, v);
    index.record(_a, v);
    index.record(_a, _v(270));
    expect(index.count, 1);
    expect(index.variantsOf(_a), <ImageVariant>[v]);
  });

  test('variants are per asset, oldest first', () {
    index.record(_a, _v(100));
    index.record(_a, _v(764));
    index.record(_b, _v(270, asset: _b));
    expect(index.count, 3);
    expect(index.variantsOf(_a).map((ImageVariant v) => v.wireW), <int>[
      100,
      764,
    ]);
    expect(index.variantsOf(_b), hasLength(1));
    expect(index.variantsOf(_c), isEmpty);
    expect(() => index.variantsOf(_a).add(_v(50)), throwsUnsupportedError);
  });

  test('nearestWhere: narrowest at or above, else widest below, filtered', () {
    for (final int w in <int>[225, 548, 764, 100]) {
      index.record(_a, _v(w));
    }
    index.record(_a, _v(null, h: 225)); // width-less: never an answer
    bool any(ImageVariant v) => true;
    // A larger variant beats a smaller one.
    expect(index.nearestWhere(_a, 467, any)?.wireW, 548);
    // Equal width counts as "at least".
    expect(index.nearestWhere(_a, 225, any)?.wireW, 225);
    // Nothing at or above: fall back to the widest below.
    expect(index.nearestWhere(_a, 900, any)?.wireW, 764);
    // Nothing smaller: the narrowest larger one.
    expect(index.nearestWhere(_a, 50, any)?.wireW, 100);
    // The predicate filters: only the smaller candidates pass for 467.
    expect(
      index.nearestWhere(_a, 467, (ImageVariant v) => v.wireW! < 467)?.wireW,
      225,
    );
    // Excluding the narrowest larger one moves to the next larger one.
    expect(
      index.nearestWhere(_a, 467, (ImageVariant v) => v.wireW != 548)?.wireW,
      764,
    );
    expect(index.nearestWhere(_a, 467, (ImageVariant v) => false), isNull);
    expect(index.nearestWhere(_b, 467, any), isNull);
  });

  test('nearestWhere minWidth: a floor for smaller variants only', () {
    for (final int w in <int>[50, 100, 185, 225]) {
      index.record(_a, _v(w));
    }
    bool any(ImageVariant v) => true;
    // 764 wants ≥ 219: the widest smaller one passing the floor.
    expect(index.nearestWhere(_a, 764, any, minWidth: 219)?.wireW, 225);
    // Nothing smaller passes a higher floor (and nothing is larger).
    expect(index.nearestWhere(_a, 900, any, minWidth: 258), isNull);
    // The predicate still runs only on candidates above the floor.
    final List<int> probed = <int>[];
    index.nearestWhere(_a, 764, (ImageVariant v) {
      probed.add(v.wireW!);
      return false;
    }, minWidth: 219);
    expect(probed, <int>[225]);
    // A larger variant ignores the floor.
    index.record(_a, _v(900));
    expect(index.nearestWhere(_a, 50, any, minWidth: 1000)?.wireW, 50);
    expect(index.nearestWhere(_a, 764, any, minWidth: 5000)?.wireW, 900);
  });

  test('bounded: per-asset drops the oldest, overflow starts over', () {
    index = ImageVariantIndex(maxAssets: 2, maxPerAsset: 2);
    index
      ..record(_a, _v(100))
      ..record(_a, _v(270))
      ..record(_a, _v(764));
    expect(index.variantsOf(_a).map((ImageVariant v) => v.wireW), <int>[
      270,
      764,
    ]);
    expect(index.count, 2);

    index.record(_b, _v(270, asset: _b));
    expect(index.count, 3);
    index.record(_c, _v(270, asset: _c)); // third asset > maxAssets
    expect(index.count, 1);
    expect(index.variantsOf(_a), isEmpty);
    expect(index.variantsOf(_c), hasLength(1));
  });

  test('clear / reset forget everything; one process-wide instance', () {
    index.record(_a, _v(270));
    index.clear();
    expect(index.count, 0);
    expect(index.variantsOf(_a), isEmpty);
    index.record(_a, _v(270));
    index.reset();
    expect(index.count, 0);
    expect(
      identical(ImageVariantIndex.instance, ImageVariantIndex.instance),
      isTrue,
    );
  });
}
