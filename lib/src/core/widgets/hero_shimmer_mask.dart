import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../design/hero_assets.dart';
import '../media/media_log.dart';

/// The Hero bag mark as a raster ALPHA mask (white on transparent, generated
/// from [HeroAssets.imagePlaceholder] by `tool/gen_hero_shimmer_mask.dart`),
/// decoded ONCE per process at [decodeSize] px and shared by every image
/// shimmer, which tints it at draw time — no SVG parse at runtime, no
/// saveLayer.
///
/// Lifetimes are bounded: one [ui.Image] for the app's life (~256 KB RGBA);
/// the codec is disposed right after its single frame; a failed load is
/// swallowed (the shimmer then draws without the mark) and can be retried;
/// [generation]'s only listeners are the painters' `repaint` subscriptions,
/// which the render objects drop on detach.
abstract final class HeroShimmerMask {
  /// Decode width == the asset's own width: no resample.
  static const int decodeSize = 256;

  static HeroShimmerMaskImage? _mask;
  static Future<ui.Image?>? _pending;
  static final ValueNotifier<int> _generation = ValueNotifier<int>(0);
  static int _epoch = 0; // bumped by debugReset: an in-flight load is dropped

  /// The decoded mask, or null until it lands.
  static HeroShimmerMaskImage? get mask => _mask;

  /// Ticks when the mask lands (and on [debugReset]), so painters repaint
  /// once.
  static ValueListenable<int> get generation => _generation;

  /// Starts the decode on first use; joins the one in flight; the bitmap
  /// once it is there.
  static Future<ui.Image?> ensureLoaded() {
    final HeroShimmerMaskImage? done = _mask;
    if (done != null) return Future<ui.Image?>.value(done.image);
    return _pending ??= _load();
  }

  /// Frees the bitmap and forgets an in-flight load (tests only).
  @visibleForTesting
  static void debugReset() {
    _epoch++;
    _mask?.image.dispose();
    _mask = null;
    _pending = null;
    _generation.value++;
  }

  static Future<ui.Image?> _load() async {
    final int epoch = _epoch;
    try {
      final ByteData bytes = await rootBundle.load(HeroAssets.imageShimmerMask);
      final ui.Codec codec = await ui.instantiateImageCodec(
        bytes.buffer.asUint8List(),
        targetWidth: decodeSize,
      );
      final ui.Image image;
      try {
        image = (await codec.getNextFrame()).image;
      } finally {
        codec.dispose();
      }
      if (epoch != _epoch) {
        image.dispose(); // debugReset ran mid-decode: never resurrect it
        return null;
      }
      _mask = HeroShimmerMaskImage(image);
      _generation.value++;
      return image;
    } catch (e) {
      if (kDebugMode) MediaLog.line(MediaLog.cache, 'shimmer mask: $e');
      return null;
    } finally {
      // Cleared on failure too, or one failed decode would block retries.
      if (epoch == _epoch) _pending = null;
    }
  }
}

/// The decoded mask and its source rect, computed once when it lands so a
/// painter allocates nothing for them per frame.
class HeroShimmerMaskImage {
  HeroShimmerMaskImage(this.image)
    : src = ui.Rect.fromLTWH(
        0,
        0,
        image.width.toDouble(),
        image.height.toDouble(),
      );

  final ui.Image image;
  final ui.Rect src;
}
