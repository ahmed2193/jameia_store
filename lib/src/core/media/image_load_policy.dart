import 'dart:async';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/scheduler.dart' show SchedulerBinding;

import 'hero_image_cache_manager.dart';
import 'image_disk_index.dart';
import 'image_load_decision.dart';
import 'image_ram_key.dart';
import 'image_variant.dart';
import 'image_variant_index.dart';

export 'image_load_decision.dart';

/// The load-source probe. Pure apart from [ImageDiskIndex.markSeen] on a RAM
/// hit and the one-time seed start; allocation-light (RAM keys are cached per
/// variant, see `variantRamKey`) because it runs on every new mount.
class ImageLoadPolicy {
  ImageLoadPolicy._();

  /// Unknown source: the shimmer starts only if the image is still loading
  /// after this, so a disk hit the index did not know about (or a fast
  /// network) never flashes it.
  static const Duration networkShimmerDelay = Duration(milliseconds: 300);

  /// Disk-known: a disk decode lands in a few frames; the late shimmer is only
  /// the safety net for a file the OS purged after the index learned it.
  static const Duration diskShimmerDelay = Duration(seconds: 1);

  /// Fidelity floor of a SMALLER cached variant: it may stand in only if the
  /// tile shows it at most this much upscaled (wire widths). 4 rather than 3:
  /// the grid tile → product-page hero hop is 225 → 764 = 3.4x, and 225 →
  /// 900 = 4.0x on a dpr-2 phone. A blurry crop for the ~1 s a disk decode
  /// takes beats a shimmer; 50 → 764 (15x) and 185 → 764 (4.1x) still fail
  /// and fall back to `network` for that mount.
  static const double maxVariantUpscale = 4;

  /// The narrowest smaller variant that may stand in for a [wireW] request.
  static int minVariantWidth(int wireW) => (wireW / maxVariantUpscale).ceil();

  /// flutter_cache_manager's sync metadata probe (keys touched this process).
  @visibleForTesting
  static bool Function(String cacheKey) storeHint = _storeHint;

  static bool _storeHint(String cacheKey) =>
      HeroImageCacheManager.instance.store.memoryCacheContainsKey(cacheKey);

  /// Starts the disk-index seed ([HeroImageCacheManager.seedDiskIndex]).
  @visibleForTesting
  static Future<int> Function() startDiskSeed =
      HeroImageCacheManager.seedDiskIndex;

  static bool _seedScheduled = false;

  /// Lets the next [decide] schedule the seed again (tests only).
  @visibleForTesting
  static void debugResetSeed() => _seedScheduled = false;

  // The fallback start of the disk-index seed: `main()` starts it first
  // thing, and the seed runs once per process, so this only matters for an
  // entry point that did not. decide() runs in build, so the callback is that
  // frame's post-frame; ensureVisualUpdate only matters for a call outside a
  // frame (a post-frame callback alone never fires without a frame).
  static void _scheduleSeed() {
    _seedScheduled = true;
    SchedulerBinding.instance
      ..addPostFrameCallback((_) => unawaited(startDiskSeed()))
      ..ensureVisualUpdate();
  }

  /// Probe order: exact RAM key → disk-known → another variant of [assetId]
  /// complete in RAM (the narrowest at or above [memW], which downscales
  /// sharply, else the widest below it down to [minVariantWidth]) → network,
  /// whose fades are the tile's own ([networkFadeIn]/-Out). [variant] is the
  /// tile's own variant, whose RAM key is cached (see `tileRamKey`).
  static ImageLoadDecision decide({
    required String cacheKey,
    required int? memW,
    required int? memH,
    required String? assetId,
    required Duration networkFadeIn,
    required Duration networkFadeOut,
    ImageVariant? variant,
    ImageDiskIndex? diskIndex,
    ImageVariantIndex? variantIndex,
  }) {
    if (!_seedScheduled) _scheduleSeed();
    final ImageDiskIndex disk = diskIndex ?? ImageDiskIndex.instance;
    if (imageRamKeyLanded(tileRamKey(cacheKey, memW, memH, variant))) {
      disk.markSeen(cacheKey);
      return ImageLoadDecision.ram;
    }
    if (disk.contains(cacheKey) || storeHint(cacheKey)) {
      return ImageLoadDecision.disk;
    }
    if (assetId != null && memW != null) {
      // Same-asset variants only; a different crop (other aspect or fit) is
      // still the asset the user saw, and beats a shimmer.
      final ImageVariant? v = (variantIndex ?? ImageVariantIndex.instance)
          .nearestWhere(
            assetId,
            memW,
            (ImageVariant v) =>
                v.cacheKey != cacheKey && imageRamKeyLanded(variantRamKey(v)),
            minWidth: minVariantWidth(memW),
          );
      if (v != null) {
        return ImageLoadDecision.variant(
          imageRamProvider(
            v.cacheKey,
            v.wireW,
            v.wireH,
            cacheManager: HeroImageCacheManager.loader,
          ),
          variantRamKey(v),
        );
      }
    }
    return ImageLoadDecision.network(
      fadeIn: networkFadeIn,
      fadeOut: networkFadeOut,
    );
  }

  /// Re-takes a decision once the disk-index seed has landed: a `network`
  /// tile whose file turned out to be on disk becomes `disk` (no fade, the
  /// later safety-net shimmer); anything else stays (null). Only network →
  /// disk: both show the same quiet placeholder, so the tile keeps its shape
  /// mid-load. The caller skips a tile whose image landed.
  static ImageLoadDecision? afterSeed(
    ImageLoadDecision d,
    String cacheKey, {
    ImageDiskIndex? diskIndex,
  }) {
    if (d.source != ImageLoadSource.network) return null;
    final ImageDiskIndex disk = diskIndex ?? ImageDiskIndex.instance;
    return disk.contains(cacheKey) || storeHint(cacheKey)
        ? ImageLoadDecision.disk
        : null;
  }
}
