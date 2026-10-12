// The image key policy (ported from the reference app, jm3eia_mobile
// `docs/audit/image_cache/FINAL_REPORT.md` §5, `CALL_SITE_AUDIT.md` §E).
// ONE canonical URL per asset, ONE dpr rule, ONE width ladder: the same asset
// at the same or a nearby size, on any screen, resolves to the same variant —
// one disk file (cacheKey) and one RAM entry (ResizeImageKey(cacheKey, wireW,
// wireH)). Wire size == decode size. Layout-driven sizes stop at 900 px; an
// explicit memCacheWidth/Height (a full-screen viewer) may go up to the CDN's
// own 2048.
//
// URL canonicalisation and the variant value type live next door and are
// re-exported, so this import is the whole policy.
import 'package:flutter/painting.dart' show BoxFit;

export 'image_url_canonical.dart';
export 'image_variant.dart';

const int kMinWirePx = 50;

/// Ceiling of the DEFAULT (layout-driven) path: no layout box needs more than
/// this, and a screen-sized decode is 4+ MB of RGBA.
const int kMaxWirePx = 900;

/// Ceiling for an axis the caller sized EXPLICITLY (`memCacheWidth/Height`):
/// the CDN's own maximum. Everything else stays under [kMaxWirePx] because it
/// never passes an override.
const int kMaxOverridePx = 2048;

/// Wire == decode widths in physical px: ≈×1.2 steps (×1.25 below 100 px,
/// where bytes are negligible), shifted so a rung lands on 270. Every audited
/// size cluster spans ≤ 2 rungs: badges 50-60 → 50/64, marks 67-100 → 80/100,
/// thumbs 112-128 → 122/150, tiles 144-185 → 150/185, product cards 216-264 →
/// 225/270 (a 3-column grid, 229-264, is 270 alone), rows 252-298 → 270/324,
/// 280-372 → 324/389, wide 500-642 → 548/648, banners and heroes 656-824 →
/// 764/900. The rungs ABOVE 900 (1080 … 2048) serve explicit overrides only;
/// the default path stops at 900 ([kMaxWirePx]).
const List<int> kWidthLadder = <int>[
  50,
  64,
  80,
  100,
  122,
  150,
  185,
  225,
  270,
  324,
  389,
  467,
  548,
  648,
  764,
  900,
  1080,
  1296,
  1555,
  1866,
  2048,
];

/// Snaps [px] UP to the next rung — never below the painted pixels, so never
/// blurrier — clamped to [kMinWirePx, [max]]. [max] defaults to the
/// layout-driven ceiling [kMaxWirePx]; pass [kMaxOverridePx] for an explicit
/// decode override. Beyond [max] the answer is the largest rung that fits it.
int bucketWidth(int px, {int max = kMaxWirePx}) {
  int top = kMinWirePx;
  for (final int rung in kWidthLadder) {
    if (rung > max) break;
    if (px <= rung) return rung;
    top = rung;
  }
  return top;
}

/// The height that keeps the layout box's aspect at the bucketed width, so
/// `fit` cover/contain/fill paint identically from a slightly larger decode.
/// Clamped to [kMinWirePx, [max]] ([kMaxWirePx] unless the height was an
/// explicit override): a layout box taller than the cap loses its aspect.
int bucketHeightFor({
  required int bucketW,
  required int rawW,
  required int rawH,
  int max = kMaxWirePx,
}) {
  if (rawW <= 0) return bucketWidth(rawH, max: max);
  return (bucketW * rawH / rawW).round().clamp(kMinWirePx, max);
}

/// THE dpr rule: `logical × min(dpr, 2)`, snapped to the ladder. Above 2× the
/// sharpness gain is invisible while bytes and decode cost nearly double.
int decodePx(double logicalPx, double dpr) =>
    bucketWidth(_physical(logicalPx, dpr));

/// Wire size == decode size for one render site; a `null` axis is unknown and
/// is neither sent nor decoded to (the tight-axis rule).
///
/// [pixelW]/[pixelH] are a caller's decode override (`memCacheWidth/Height`)
/// in physical px at [dpr]. They go back to logical px first, so they obey the
/// SAME dpr rule and ladder as the default path: a `memCacheWidth: 144` on a
/// dpr-3 phone is the 48-dp default, not a variant. The one difference is the
/// ceiling: an axis the caller sized explicitly may climb to [kMaxOverridePx],
/// a layout-driven axis stops at [kMaxWirePx].
({int? w, int? h}) wireSizeFor({
  double? logicalW,
  double? logicalH,
  int? pixelW,
  int? pixelH,
  required double dpr,
}) {
  final double d = dpr > 0 ? dpr : 1.0;
  final int maxW = (pixelW ?? 0) > 0 ? kMaxOverridePx : kMaxWirePx;
  final int maxH = (pixelH ?? 0) > 0 ? kMaxOverridePx : kMaxWirePx;
  final int rawW = _physical(
    pixelW != null && pixelW > 0 ? pixelW / d : logicalW,
    d,
  );
  final int rawH = _physical(
    pixelH != null && pixelH > 0 ? pixelH / d : logicalH,
    d,
  );
  if (rawW > 0 && rawH > 0) {
    final int w = bucketWidth(rawW, max: maxW);
    return (
      w: w,
      h: bucketHeightFor(bucketW: w, rawW: rawW, rawH: rawH, max: maxH),
    );
  }
  return (
    w: rawW > 0 ? bucketWidth(rawW, max: maxW) : null,
    h: rawH > 0 ? bucketWidth(rawH, max: maxH) : null,
  );
}

/// [BoxFit] in the CDN's `fit` vocabulary.
String cdnFitParam(BoxFit fit) => switch (fit) {
  BoxFit.contain || BoxFit.scaleDown => 'contain',
  BoxFit.fill => 'fill',
  BoxFit.fitWidth || BoxFit.fitHeight => 'inside',
  BoxFit.cover || BoxFit.none => 'cover',
};

/// Physical px for a logical length at the capped dpr; 0 = unknown.
int _physical(double? logical, double dpr) {
  if (logical == null || !logical.isFinite || logical <= 0) return 0;
  final int px = (logical * dpr.clamp(1.0, 2.0)).round();
  return px < 1 ? 1 : px;
}
