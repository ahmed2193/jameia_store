// Generator for `assets/images/hero_shimmer_mask.png` — the WHITE-on-
// TRANSPARENT silhouette of the Hero bag mark (`HeroAssets.imagePlaceholder`,
// the glyph `HeroImagePlaceholder` draws) that every image loading shimmer
// (`lib/src/core/widgets/hero_image_shimmer.dart`) tints at draw time. Port of
// the reference app's `tool/gen_shimmer_logo_mask.dart`.
//
// Regenerate from the repo root (no external tools):
//
//   flutter test tool/gen_hero_shimmer_mask.dart
//
// Idempotent: the same SVG yields byte-identical output (one deterministic
// raster pass; the PNG encoder below has no timestamps or random state).
//
// Pipeline:
//   1. Parse the SVG (viewBox 48×48) with flutter_svg.
//   2. Draw it scaled to 256×256 inside ONE saveLayer whose
//      ColorFilter.mode(white, srcIn) turns every stroke white whatever its
//      colour; alpha carries the anti-aliased shape.
//   3. Force the colour channels to 255 everywhere (transparent pixels too —
//      invisible, and constant channels compress to almost nothing), then
//      encode 8-bit PNGs — RGBA and grey + alpha — with per-row filter search
//      and zlib level 9, and keep the smallest of those and Skia's own.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/design/hero_assets.dart';

const String _source = HeroAssets.imagePlaceholder;
const String _output = HeroAssets.imageShimmerMask;
const int _side = 256;
const int _maxBytes = 4 * 1024;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generate $_output', () async {
    final PictureInfo info = await vg.loadPicture(
      const SvgAssetLoader(_source),
      null,
    );
    final double scale = _side / info.size.width;
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    canvas.saveLayer(
      null,
      Paint()
        ..colorFilter = const ColorFilter.mode(Colors.white, BlendMode.srcIn),
    );
    canvas.scale(scale);
    canvas.drawPicture(info.picture);
    canvas.restore();
    final ui.Picture picture = recorder.endRecording();
    final ui.Image image = await picture.toImage(_side, _side);
    picture.dispose();
    info.picture.dispose();

    final Uint8List skiaPng = (await image.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List();
    final Uint8List rgba = (await image.toByteData(
      format: ui.ImageByteFormat.rawStraightRgba,
    ))!.buffer.asUint8List();
    image.dispose();

    final Uint8List grayAlpha = Uint8List(_side * _side * 2);
    for (int i = 0, j = 0; i < rgba.length; i += 4, j += 2) {
      rgba[i] = rgba[i + 1] = rgba[i + 2] = 255;
      grayAlpha[j] = 255;
      grayAlpha[j + 1] = rgba[i + 3];
    }
    final List<Uint8List> candidates = <Uint8List>[
      skiaPng,
      _encodePng(rgba, _side, _side, colorType: 6, bpp: 4),
      _encodePng(grayAlpha, _side, _side, colorType: 4, bpp: 2),
    ];
    final Uint8List out = candidates.reduce(
      (Uint8List a, Uint8List b) => b.length < a.length ? b : a,
    );

    File(_output).writeAsBytesSync(out, flush: true);
    stdout.writeln(
      '$_output: ${_side}x$_side, ${out.length} B '
      '(skia ${candidates[0].length} B, rgba ${candidates[1].length} B, '
      'grey+alpha ${candidates[2].length} B)',
    );

    // The file decodes back to the intended geometry and fits the budget.
    final ui.Codec codec = await ui.instantiateImageCodec(out);
    final ui.FrameInfo frame = await codec.getNextFrame();
    expect(frame.image.width, _side);
    expect(frame.image.height, _side);
    frame.image.dispose();
    codec.dispose();
    expect(out.length, lessThanOrEqualTo(_maxBytes));
  });
}

/// A minimal deterministic PNG encoder (8-bit, no interlace) for colour type
/// [colorType] at [bpp] bytes a pixel: tries each fixed scanline filter plus
/// a per-row min-sum heuristic and keeps the smallest zlib (level 9) stream.
Uint8List _encodePng(
  Uint8List pixels,
  int width,
  int height, {
  required int colorType,
  required int bpp,
}) {
  final int stride = width * bpp;
  Uint8List filterRow(int type, int y) {
    final Uint8List row = Uint8List(stride + 1)..[0] = type;
    final int base = y * stride;
    for (int x = 0; x < stride; x++) {
      final int cur = pixels[base + x];
      final int a = x >= bpp ? pixels[base + x - bpp] : 0;
      final int b = y > 0 ? pixels[base - stride + x] : 0;
      final int c = (x >= bpp && y > 0) ? pixels[base - stride + x - bpp] : 0;
      final int pred = switch (type) {
        0 => 0,
        1 => a,
        2 => b,
        3 => (a + b) >> 1,
        _ => _paeth(a, b, c),
      };
      row[x + 1] = (cur - pred) & 0xFF;
    }
    return row;
  }

  int cost(Uint8List row) {
    int s = 0;
    for (int i = 1; i < row.length; i++) {
      final int v = row[i];
      s += v < 128 ? v : 256 - v;
    }
    return s;
  }

  Uint8List? best;
  for (int strategy = 0; strategy <= 5; strategy++) {
    final BytesBuilder raw = BytesBuilder(copy: false);
    for (int y = 0; y < height; y++) {
      if (strategy < 5) {
        raw.add(filterRow(strategy, y));
      } else {
        Uint8List? pick;
        for (int t = 0; t < 5; t++) {
          final Uint8List r = filterRow(t, y);
          if (pick == null || cost(r) < cost(pick)) pick = r;
        }
        raw.add(pick!);
      }
    }
    final Uint8List z = Uint8List.fromList(
      ZLibCodec(
        level: ZLibOption.maxLevel,
        memLevel: ZLibOption.maxMemLevel,
      ).encode(raw.takeBytes()),
    );
    if (best == null || z.length < best.length) best = z;
  }

  final ByteData ihdr = ByteData(13)
    ..setUint32(0, width)
    ..setUint32(4, height)
    ..setUint8(8, 8) // bit depth
    ..setUint8(9, colorType)
    ..setUint8(10, 0)
    ..setUint8(11, 0)
    ..setUint8(12, 0);
  final BytesBuilder png = BytesBuilder(copy: false)
    ..add(const <int>[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
  _chunk(png, 'IHDR', ihdr.buffer.asUint8List());
  _chunk(png, 'IDAT', best!);
  _chunk(png, 'IEND', Uint8List(0));
  return png.takeBytes();
}

int _paeth(int a, int b, int c) {
  final int p = a + b - c;
  final int pa = (p - a).abs(), pb = (p - b).abs(), pc = (p - c).abs();
  if (pa <= pb && pa <= pc) return a;
  return pb <= pc ? b : c;
}

void _chunk(BytesBuilder out, String type, Uint8List data) {
  final Uint8List typeBytes = Uint8List.fromList(type.codeUnits);
  out
    ..add((ByteData(4)..setUint32(0, data.length)).buffer.asUint8List())
    ..add(typeBytes)
    ..add(data);
  int crc = 0xFFFFFFFF;
  for (final int byte in <int>[...typeBytes, ...data]) {
    crc = _crcTable[(crc ^ byte) & 0xFF] ^ (crc >>> 8);
  }
  out.add((ByteData(4)..setUint32(0, crc ^ 0xFFFFFFFF)).buffer.asUint8List());
}

final List<int> _crcTable = List<int>.generate(256, (int n) {
  int c = n;
  for (int k = 0; k < 8; k++) {
    c = (c & 1) != 0 ? 0xEDB88320 ^ (c >>> 1) : c >>> 1;
  }
  return c;
});
