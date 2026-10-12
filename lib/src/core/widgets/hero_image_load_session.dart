import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show ImageProvider;

import '../media/image_disk_index.dart';
import '../media/image_load_policy.dart';
import '../media/image_load_trace.dart';
import '../media/image_placeholder_anchor.dart';
import '../media/image_ram_key.dart';
import '../media/image_request.dart';
import 'hero_image_placeholder_plan.dart';

/// The image tile a [HeroImageLoadSession] serves (`HeroRetryingImage`'s
/// state).
abstract interface class HeroImageLoadTile {
  ImageRequest get request;

  /// Attempts so far (0 = the first load).
  int get attempt;

  bool get alive;

  /// Runs [apply] (a new decision) inside `setState`.
  void redecided(void Function() apply);
}

/// One image tile's load decision and what hangs off it: ONE decision per
/// RAM key ([ImageLoadPolicy.decide], taken on the first build, retaken only
/// when the request's key changes, or turned `network` → `disk` in place by
/// the disk-index seed), the shimmer [anchor], the remount [epoch], and the
/// plan for every placeholder octo_image asks for. Within one attempt the
/// placeholder's CONTENT never changes shape.
class HeroImageLoadSession {
  HeroImageLoadSession(this._tile);

  final HeroImageLoadTile _tile;

  ImageLoadDecision? _decision;

  /// When the tile's placeholder was first painted; cleared by a decision
  /// unless the tile was already waiting with nothing landed.
  final ImagePlaceholderAnchor anchor = ImagePlaceholderAnchor();
  bool _keepWaitStart = false;
  bool _watchingSeed = false;

  // The cached-variant placeholder's RAM re-check, once per attempt.
  ImageLoadDecision? _probedDecision;
  int _probedAttempt = -1;
  bool _variantLanded = false;

  /// Bumped when the RAM key changes before the old one landed: the inner
  /// image remounts instead of chaining octo's gapless handlers.
  int get epoch => _epoch;
  int _epoch = 0;

  ImageRequest get _req => _tile.request;

  Object get _ramKey => tileRamKey(
    _req.cacheKey,
    _req.memCacheWidth,
    _req.memCacheHeight,
    _req.variant,
  );

  /// The decision for the current RAM key; [networkFade] is the tile's fade
  /// for a network load.
  ImageLoadDecision decision(Duration networkFade) {
    final ImageLoadDecision? kept = _decision;
    if (kept != null) return kept;
    final ImageLoadDecision d = _decision = ImageLoadPolicy.decide(
      cacheKey: _req.cacheKey,
      memW: _req.memCacheWidth,
      memH: _req.memCacheHeight,
      assetId: _req.variant?.assetId,
      networkFadeIn: networkFade,
      networkFadeOut: networkFade,
      variant: _req.variant,
    );
    if (!_keepWaitStart) anchor.atUs = null;
    _keepWaitStart = false;
    // The decision just probed its cached variant: this attempt's check.
    _probedDecision = d;
    _probedAttempt = _tile.attempt;
    _variantLanded = d.placeholderProvider != null;
    if (d.source == ImageLoadSource.network) _watchSeed();
    return d;
  }

  /// The tile got [old]'s successor; true when it is another FILE (the retry
  /// machine starts over). Another decode size of the same file only takes a
  /// new decision.
  bool requestChanged(ImageRequest old) {
    final bool newFile = _req.cacheKey != old.cacheKey;
    if (!newFile &&
        _req.memCacheWidth == old.memCacheWidth &&
        _req.memCacheHeight == old.memCacheHeight) {
      return false;
    }
    // octo's gapless path keeps the old image only while it is complete in
    // RAM; otherwise remount, and keep the wait start (a running shimmer
    // stays running).
    final Object oldKey = tileRamKey(
      old.cacheKey,
      old.memCacheWidth,
      old.memCacheHeight,
      old.variant,
    );
    if (!imageRamKeyLanded(oldKey)) {
      _epoch++;
      _keepWaitStart = true;
    }
    _decision = null;
    return newFile;
  }

  /// The placeholder octo shows while [d]'s load runs. octo builds it once
  /// more on the frame the image LANDS, as the underlay of its fade-out: with
  /// time left on the deadline (or no frame painted yet) the RAM key is
  /// probed once, and a landed image gets the plain still box — no timer, no
  /// sweep starting under the fade. A passed deadline is a shimmer already
  /// running, which the crossfade keeps.
  HeroImagePlaceholderPlan placeholderPlan(
    ImageLoadDecision d, {
    required bool animate,
  }) {
    if (_tile.attempt > 0 || d.placeholderProvider != null) {
      return retryPlan(d, animate: animate);
    }
    final Duration? left = anchor.left(d.shimmerDelay);
    if ((left == null || left > Duration.zero) && imageRamKeyLanded(_ramKey)) {
      return const HeroImagePlaceholderPlan.still();
    }
    return HeroImagePlaceholderPlan.quiet(d.shimmerDelay, anchor);
  }

  /// A retry's (and a failure's) placeholder: [d]'s cached variant while it
  /// is still complete in RAM (it can be evicted while the tile retries for
  /// minutes; re-checked once per attempt), else the shimmer.
  HeroImagePlaceholderPlan retryPlan(
    ImageLoadDecision d, {
    required bool animate,
  }) {
    final ImageProvider<Object>? cached = d.placeholderProvider;
    final Object? cachedKey = d.placeholderRamKey;
    if (cached != null && cachedKey != null) {
      if (!identical(_probedDecision, d) || _probedAttempt != _tile.attempt) {
        _probedDecision = d;
        _probedAttempt = _tile.attempt;
        _variantLanded = imageRamKeyLanded(cachedKey);
      }
      if (_variantLanded) return HeroImagePlaceholderPlan.variant(cached);
    }
    return HeroImagePlaceholderPlan.shimmer(animate: animate);
  }

  void dispose() => _unwatchSeed();

  /// The debug `[IMGCACHE]` trace of the tile's build under [d]; [owner]
  /// (its Element) dedupes rebuilds. Free unless the trace is on.
  void traceBuild(Object owner, ImageLoadDecision d) {
    if (!kDebugMode || !ImageLoadTrace.enabled) return;
    ImageLoadTrace.onBuild(
      owner,
      _req.imageUrl,
      _req.cacheKey,
      _req.memCacheWidth,
      _req.memCacheHeight,
      _req.siteWidth,
      _req.siteHeight,
      policy: d.source.name,
    );
  }

  /// …of a placeholder octo asked for under [d], fading in over [fadeIn].
  void tracePlaceholder(ImageLoadDecision d, Duration fadeIn) {
    if (!kDebugMode || !ImageLoadTrace.enabled) return;
    ImageLoadTrace.onPlaceholder(
      _tile,
      _req.cacheKey,
      _req.memCacheWidth,
      _req.memCacheHeight,
      _tile.attempt,
      fadeIn,
      policy: d.source.name,
    );
  }

  /// …of a failure of the URL the tile shows.
  void traceFail(Object error) {
    if (!kDebugMode || !ImageLoadTrace.enabled) return;
    ImageLoadTrace.onFail(_tile, _req.cacheKey, _tile.attempt, error);
  }

  void _watchSeed() {
    final ValueListenable<bool> seeded = ImageDiskIndex.instance.seeded;
    if (_watchingSeed || seeded.value) return;
    _watchingSeed = true;
    seeded.addListener(_onSeeded);
  }

  void _unwatchSeed() {
    if (!_watchingSeed) return;
    _watchingSeed = false;
    ImageDiskIndex.instance.seeded.removeListener(_onSeeded);
  }

  // The seed landed while this tile waited on a `network` decision (a
  // cold-start tile that mounted first). If its file is on disk after all
  // and nothing has landed yet, it goes on as `disk` in place: same element,
  // same quiet placeholder (re-armed to the longer delay from the same
  // anchor), no fade.
  void _onSeeded() {
    if (!ImageDiskIndex.instance.seeded.value) return; // a reset (tests)
    _unwatchSeed();
    final ImageLoadDecision? d = _decision;
    if (!_tile.alive || d == null || _tile.attempt > 0) return;
    if (imageRamKeyLanded(_ramKey)) return; // landed: already transitioning
    final ImageLoadDecision? next = ImageLoadPolicy.afterSeed(d, _req.cacheKey);
    if (next == null) return;
    if (kDebugMode && ImageLoadTrace.enabled) {
      ImageLoadTrace.onRedecide(
        _tile,
        _req.cacheKey,
        from: d.source.name,
        to: next.source.name,
      );
    }
    _tile.redecided(() => _decision = next);
  }
}
