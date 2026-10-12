// Canonical image URLs — part of the image key policy (image_key_policy.dart
// re-exports this file). A URL is made canonical BEFORE it becomes a cache
// key, so two spellings of one asset can never be two disk files or two RAM
// entries. Hero's images live on the same CDN as the reference app's, with
// the same spellings (`https://media.jm3eia.com//2025/…` in the offline
// catalogue, host-less `//YYYY/M/D/x.ext` values joined onto `mediaBase`).

/// The image CDN host, and the base that host-less paths resolve against.
const String kMediaHost = 'media.jm3eia.com';
const String kMediaBase = 'https://$kMediaHost/';

final RegExp _scheme = RegExp(r'^[a-zA-Z][a-zA-Z0-9+.\-]*://');
final RegExp _leadingSlashes = RegExp(r'^/+');
final RegExp _hostEnd = RegExp(r'[/?#]');
// Compiled once: normalizeSlashes runs on every new URL string.
final RegExp _multiSlash = RegExp(r'/{2,}');

// The host-less image paths the backend really emits, and ONLY those: a dated
// first segment, `/YYYY/M/D/<file>.<image ext>` (the reference app's 84 API
// captures; Hero's catalogue `i` / `img` values have the same shape).
//
// Anything else host-less (`null`, `default`, `images`, a lone file name) is
// NOT resolved: the CDN answers a missing file with a blank PNG, 200 +
// `Cache-Control: immutable, max-age=1y`, which the disk cache would keep as
// that asset for a year. Left as is, such a string fails to load and the
// image keeps its placeholder + retry. The same goes for a value with
// trailing junk (`.jpegس`): it never reaches the CDN. Slash runs between
// segments are tolerated (`/2026//9/30/..`); the join collapses them.
final RegExp _hostlessImagePath = RegExp(
  r'^/*\d{4}/+\d{1,2}/+\d{1,2}/+[^\s?#]+\.(jpe?g|png|webp|gif|avif|svg)(\?.*)?$',
  caseSensitive: false,
);

// Per input string; a scrolling grid rebuilds the same URLs over and over.
// Cleared whole-cloth on overflow: LRU bookkeeping costs more than a recompute.
final Map<String, String> _memo = <String, String>{};
const int _kMemoMax = 2048;

/// The ONE spelling of an image URL:
///   * trimmed; empty stays `''`;
///   * host-less dated image paths (`/2026/9/30/x.jpeg`, `2026/..`,
///     `//2026/..`) resolve against [kMediaBase], which serves them; any
///     other host-less string (`null`, `default`, `images`) is returned
///     unchanged, never sent to the CDN;
///   * protocol-relative `//host/..` gets `https:`;
///   * on the CDN: `https`, scheme + host lower-cased (the PATH stays as is —
///     the CDN is case-sensitive), `//` runs collapsed, a trailing `?` dropped.
/// Any other absolute URL is only slash-normalised.
String canonicalImageUrl(String raw) {
  if (raw.isEmpty) return '';
  final String? hit = _memo[raw];
  if (hit != null) return hit;
  if (_memo.length >= _kMemoMax) _memo.clear();
  return _memo[raw] = _canonicalise(raw.trim());
}

/// Whether [canonicalUrl] (already canonical) is on the transforming CDN.
bool isMediaUrl(String canonicalUrl) => canonicalUrl.startsWith(kMediaBase);

/// The identity shared by every variant of one asset: the canonical URL
/// without its query.
String assetId(String canonicalUrl) {
  final int q = canonicalUrl.indexOf('?');
  return q < 0 ? canonicalUrl : canonicalUrl.substring(0, q);
}

/// Collapses `//` runs in host+path, keeping the scheme and the query:
/// `https://host//a//b?x=1` → `https://host/a/b?x=1`. The CDN answers 200 on
/// a `//` path, so this is purely for key stability. A clean URL comes back
/// as the same string, zero allocation.
String normalizeSlashes(String url) {
  final int schemeEnd = url.indexOf('://');
  if (schemeEnd < 0) return url;
  final int start = schemeEnd + 3;
  final int queryStart = url.indexOf('?', start);
  final int end = queryStart < 0 ? url.length : queryStart;
  final int dbl = url.indexOf('//', start);
  if (dbl < 0 || dbl >= end) return url;
  return url.substring(0, start) +
      url.substring(start, end).replaceAll(_multiSlash, '/') +
      (queryStart < 0 ? '' : url.substring(queryStart));
}

String _canonicalise(String url) {
  if (url.isEmpty) return '';
  String s = url;
  if (!_scheme.hasMatch(s)) {
    // `//host/..` is protocol-relative. A host-less path is resolved on the
    // CDN only when it looks like an image the backend emits (`//2026/..`
    // included: its first segment is not a host name); anything else comes
    // back untouched — see [_hostlessImagePath].
    final String rest = s.replaceFirst(_leadingSlashes, '');
    final int cut = rest.indexOf('/');
    final bool hostFirst =
        s.startsWith('//') && cut > 0 && rest.substring(0, cut).contains('.');
    if (hostFirst) {
      s = 'https://$rest';
    } else if (_hostlessImagePath.hasMatch(s)) {
      s = '$kMediaBase$rest';
    } else {
      return s;
    }
  }
  final int hostStart = s.indexOf('://') + 3;
  int hostEnd = s.indexOf(_hostEnd, hostStart);
  if (hostEnd < 0) hostEnd = s.length;
  if (s.substring(hostStart, hostEnd).toLowerCase() != kMediaHost) {
    return normalizeSlashes(s);
  }
  final String out = normalizeSlashes(
    'https://$kMediaHost${s.substring(hostEnd)}',
  );
  return out.endsWith('?') ? out.substring(0, out.length - 1) : out;
}
