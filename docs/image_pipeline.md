# Image pipeline

Every network image in the app is a `HeroImage` (`lib/src/core/widgets/hero_image.dart`).
It is a port of the jameia app's measured pipeline (jm3eia_mobile
`docs/audit/image_cache/FINAL_REPORT.md`), re-skinned in Hero's skeleton family.
Feature code passes a URL and the size the layout gives it. Everything below happens
inside the widget.

## 1. Layers and files

| Layer | Files | Job |
|---|---|---|
| Entry | `core/widgets/hero_image.dart` | Public API (`url`, `width`, `height`, `radius`, `fit`, `memCacheWidth/Height`, `isCircular`, `.circle`). Clips only when needed. One `RepaintBoundary` per tile. An empty URL shows `HeroImagePlaceholder`. Also `cdnUrl(...)` and `retryAllPendingImages()`. |
| Site | `hero_image_network.dart` | Applies the key policy to this site (`ImageRequest.resolve`). Missing axes come from a `LayoutBuilder` (tight-axis rule, §5). Keys the tile by ASSET, so a size change keeps the element. |
| Load | `hero_retrying_image.dart`, `hero_image_load_session.dart`, `hero_image_attempt_key.dart` | Wraps `CachedNetworkImage`. Makes ONE load decision per mount (§3). The inner key is attempt + raw-fallback bit + remount epoch. Failures go to the retry machine. |
| Looks | `hero_image_loading_placeholder.dart`, `hero_image_placeholder_plan.dart`, `hero_image_still_box.dart`, `hero_image_delayed_shimmer.dart`, `hero_image_variant_placeholder.dart`, `hero_image_shape.dart` | Turn the decision into a still box, a quiet box that shimmers later, a cached other size, or a shimmer. |
| Shimmer | `hero_image_shimmer.dart` + `_painter.dart`, `hero_shimmer_clock.dart`, `hero_shimmer_run.dart`, `hero_shimmer_mask.dart`, `hero_shimmer_paints.dart` | The branded sweep. All tiles share one ticker; each run is whole laps within the ambient budget. The mask is decoded once, with one `Paint` per tint. The painter allocates nothing per frame. |
| Policy (no widgets) | `core/media/image_key_policy.dart` (+ `image_url_canonical.dart`, `image_variant.dart`), `image_cdn_transform.dart`, `image_request.dart` | Canonical URL, dpr rule, width ladder, CDN variant, transform-broken registry. |
| Decision | `image_load_policy.dart`, `image_load_decision.dart`, `image_disk_index.dart` (+ `image_disk_seed.dart`), `image_variant_index.dart`, `image_ram_key.dart`, `image_placeholder_anchor.dart` | Decide RAM / disk / variant / network. Record the first frame each shimmer delay is measured from. |
| Retry | `image_retry_machine.dart`, `image_load_failure.dart` | Backoff, jitter, concurrency cap, raw hop, reconnect. |
| Disk + RAM | `hero_image_cache_manager.dart` (+ `timeout_http_file_service.dart`, `disk_indexing_response.dart`, `indexed_json_cache_info_repository.dart`), `hero_widgets_binding.dart`, `trimming_image_cache.dart`, `image_cache_tuner.dart` | One disk store (`heroAppImageCache`, 1 y, 10 000 files). Header timeout is 25 s, body-idle stall is 15 s. The RAM budget is set per device tier; memory pressure trims the cache instead of wiping it. |
| Prefetch | `image_prefetcher.dart`, `image_prefetch_variant.dart` | Warms the exact file a destination will read. |
| Debug | `image_load_trace.dart` (+ `_stats.dart`), `image_bytes_tracker.dart`, `image_request_log.dart`, `media_log.dart` | The `[IMGCACHE]` trace (§6). |
| Asset | `assets/images/hero_shimmer_mask.png` | The bag silhouette, white on transparent: 256 px, ≤ 4 KB. Regenerate with `flutter test tool/gen_hero_shimmer_mask.dart`. |

## 2. The key policy: one URL per asset and rung

1. **Canonical URL.** HTTPS, lower-case CDN host, `//` runs collapsed. A host-less path is resolved against `media.jm3eia.com` only if it is a dated path (`/2026/9/30/x.jpeg`). Junk like `null` or `default` is never sent to the CDN.
2. **Wire size.** Take `logical × min(dpr, 2)` and snap it UP to a `kWidthLadder` rung (50 … 900). An explicit `memCacheWidth/Height` is first turned back into logical px, so it follows the same rule, but it may climb to 2048. With both axes, the height keeps the box's aspect at the snapped width.
3. **Variant URL.** On `media.jm3eia.com` the URL becomes `?w=&h=&fit=&format=webp` (always `fit` and `format=webp`, even with no size). Any other host is left untouched.
4. **One URL, three uses.** The resolved URL is the disk cacheKey. The RAM key is `ResizeImageKey(provider(cacheKey), w, h)`. **Wire size == decode size.**
5. **Transform-broken assets.** A CDN reject (≥ 400) of a transform marks the whole asset as broken. From then on, every size and spelling of it fetches the raw file, for this process.

`HeroImage.cdnUrl(...)` and `prefetchVariantFor(...)` run the same `ImageRequest.resolve`, so they always produce the URL the widget itself would request.

## 3. Decision table (once per mount, `ImageLoadPolicy.decide`)

| Source | When | First frame | Shimmer | Fade |
|---|---|---|---|---|
| `ram` | This key is decoded in RAM | The image | Never | None |
| `disk` | `ImageDiskIndex` knows the cacheKey | Still box | After 1 s (safety net for a purged file) | None |
| `variant` | Another size of the asset is in RAM, at most 4× upscaled | That size, in the box | None (if its frame is late, the still box shows) | None |
| `network` | Anything else | Still box | After 300 ms, measured from the tile's first frame | `AppMotion.fast` (`MotionGuard`: 0 under reduced motion) |
| Retry (attempt > 0) | After a failure | The cached other size while it stays in RAM, else the shimmer at once | Frozen from attempt 8 on | `AppMotion.fast` |

* **Late disk seed.** A `network` decision whose key turns up in the disk seed later re-decides to `disk`: the still box stays and no shimmer starts.
* **Size or URL change, same asset.** octo's gapless path keeps the old pixels until the new size decodes, with no shimmer. If nothing had landed, the tile remounts instead of nesting handlers, and a running shimmer keeps running.

## 4. Loading looks

* **Still box.** `AppColors.divider`, in the image's own shape (rect, rounded, circle). It never carries a glyph.
* **Shimmer** (Hero's skeleton family):
  * Colours: base `AppColors.divider`, highlight `AppColors.smallBackground`. One sweep per `AppMotion.shimmer`; the band enters from the START edge and is mirrored in RTL.
  * Bag mark: drawn from the mask at 40 % of the tile's short side (16–48 dp, left out below 16) and tinted with the highlight at 90 %.
  * Timing: a run is whole laps within `AppMotion.ambientBudget`, then a still frame. A fresh run starts when the tile comes back on screen (`TickerMode`) or on the next attempt.
  * Static: under reduced motion, with `TickerMode` off, or once frozen, it shows base + mark with no band and no ticker.
* **`HeroImagePlaceholder`** (grey tile + bag outline) is only for a slot with NO photo (empty URL). It is never a loading look.

## 5. Failures and call-site rules

**Failures**
* Every failure retries forever. Backoff runs 0.5 s → 1 s → … → 30 min, with ±25 % jitter and at most 6 attempts in flight.
* The first failure of a transformed URL hops to the raw URL at once, under the same cacheKey.
* A stalled body retries the same variant on the backoff: no hop, no verdict.
* A header timeout hops but publishes no verdict.
* `app.dart`'s reconnect listener calls `HeroImage.retryAllPendingImages()`, so every waiting tile tries again immediately.

**Call-site rules**
* **Tight-axis rule.** Pass the axes the layout fixes. An axis you leave out is read from the layout only when it is TIGHT (or when you pass neither axis, in which case any finite bound counts). A loose or unbounded axis is neither sent nor decoded to. Never invent a height the layout did not fix: the CDN would crop to it and the tile would size itself to that crop.
* **Collapsing header.** Pass the EXPANDED height, the size the image lands at. Passing the live height turns every collapse frame into a new rung, and so a new download.
* **Fly-to-cart.** Prefer a thumb that reuses the source card's size (`checkout_rail_tile.dart`): it is the same variant, so it is a RAM hit with no new file. The default 56 dp thumb (`CatalogCartGestures`) still asks for its own rung; the variant stand-in paints the card's bitmap at once and that small rung downloads once per product.
* **Decode size.** Never pass `memCacheWidth` / `memCacheHeight` to shrink a tile: the decode already equals the wire size. They are only for a bitmap that must be sharper than its box (a viewer).
* **One size per role.** A role (card thumb, rail tile, avatar) uses one dp size on every screen, so all its sites share one rung. Near-miss sizes multiply variants.
* **URLs outside the widget.** A viewer's provider or a prefetch builds its URL with `HeroImage.cdnUrl` / `prefetchVariantFor`, never by hand. A full-screen viewer passes `memCacheWidth/Height` (up to 2048).
* **Never in features.** `Image.network`, `CachedNetworkImage`, `NetworkImage`, a hand-built CDN URL, or a spinner over an image.

## 6. Debug trace

```
flutter run --dart-define=IMGCACHE_TRACE=true      # debug builds only
```

Lines go to `dart:developer` log (DevTools → Logging) under these names:

```
[IMGCACHE] build src=network? seen=0 key=https://media.jm3eia.com/…?w=225&h=225&fit=cover&format=webp mem=225x225 site=100x100 policy=network
[IMGCACHE] resolve key=… src=disk            # or network / disk-stale
[IMGCACHE] shimmer key=… seen=0 attempt=0    # placeholder_disk / placeholder_variant / shimmer_retry
[IMGCACHE] fade key=… seen=0 ms=150
[IMGCACHE] fail key=… status=500 attempt=0
[IMGCACHE] retry attempt=2 inFlight=1/6 (raw) url=…
[IMGCACHE] redecide key=… seen=0 policy=disk from=network cause=seed
[ImageBytes] logical=100x100 mem=225x225 dpr=2.6 fit=cover url=…
```

`ImageLoadTrace.summary()` logs `[IMGCACHE] SUMMARY mounts=… mem=… disk=… net=… shimmer=… fade=… fail=… | … dupGET=…`. `ImageLoadTrace.imageCacheStats()` logs the RAM cache. `[ImageCacheTuner]` (tier, trims) and `[ImageDiskIndex]` (seed) lines appear in every debug run.

## 7. Tests that lock it

| Test | Locks |
|---|---|
| `test/core/widgets/hero_image/hero_image_load_source_test.dart` | Decision → look and fades. A load landing mid-shimmer crossfades from the LIVE shimmer. Reduced motion has no fade. |
| `…/hero_image_first_frame_test.dart` | The shimmer delay is measured from the tile's first frame (a slow first frame), not from mount. |
| `…/hero_image_resize_test.dart` | Gapless size change, the variant fidelity floor, the late variant frame showing the still box, remount instead of nesting. |
| `…/hero_image_retry_test.dart` | Backoff, raw hop, stall, timeout, registry, `retryAllPendingImages`. |
| `…/hero_image_seed_test.dart` | Late disk seed re-decides. The `[IMGCACHE]` lines. |
| `…/hero_image_shimmer_test.dart` | Still box, mask asset + cache, painter pixels (LTR / RTL band), size rule, one ticker, `TickerMode`, reduced motion, lap budget. |
| `…/hero_image_cdn_url_test.dart` | The URL contract: `fit` + `format=webp`, wire == decode on the mounted widget, tight-axis rule, ladder rungs, hygiene, registry. |
| `test/core/hero_image_test.dart` | Empty URL, circle, `cdnUrl`. |
| `test/core/media/*` | Key policy, load policy, disk / variant indexes, RAM key, prefetcher, trace, tuner, trimming cache, binding. |
