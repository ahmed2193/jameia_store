// One CDN variant of an asset — part of the image key policy
// (image_key_policy.dart re-exports this file).

/// What goes on the wire for one asset at one size, and the key it is cached
/// under: on disk by [cacheKey], in RAM by
/// `ResizeImageKey(CachedNetworkImageProvider(cacheKey), wireW, wireH)` —
/// wire size == decode size, so both halves of the RAM key follow from here.
class ImageVariant {
  ImageVariant({
    required this.assetId,
    required this.wireW,
    required this.wireH,
    required this.fit,
    required this.format,
    this.query = '',
  });

  /// Splits an already-canonical URL into its asset id and the query the
  /// backend set (none today, kept so a signed URL would still work).
  factory ImageVariant.of(
    String canonicalUrl, {
    required int? wireW,
    required int? wireH,
    required String fit,
    required String format,
  }) {
    final int q = canonicalUrl.indexOf('?');
    return ImageVariant(
      assetId: q < 0 ? canonicalUrl : canonicalUrl.substring(0, q),
      query: q < 0 ? '' : canonicalUrl.substring(q + 1),
      wireW: wireW,
      wireH: wireH,
      fit: fit,
      format: format,
    );
  }

  static const Set<String> _transformKeys = <String>{'w', 'h', 'fit', 'format'};

  /// The canonical URL without a query: shared by every variant of the asset.
  final String assetId;

  /// Bucketed physical px (a ladder rung); `null` = axis not sent.
  final int? wireW;
  final int? wireH;

  /// The CDN's `fit` vocabulary (`cover`, `contain`, `fill`, `inside`).
  final String fit;
  final String format;

  /// The backend's own query string, without `?`; normally empty.
  final String query;

  /// [rawUrl] + `w`, `h`, `fit`, `format` in that fixed order, so one variant
  /// has exactly one spelling (stale transform params are replaced).
  late final String resolvedUrl = _resolve();

  /// The disk key (and the provider half of the RAM key).
  String get cacheKey => resolvedUrl;

  /// EXIF-500 fallback: the canonical URL with NO transform params. The retry
  /// machine fetches it under the SAME [cacheKey], so the raw bytes land in
  /// this variant's disk and RAM slot.
  String get rawUrl => query.isEmpty ? assetId : '$assetId?$query';

  String _resolve() {
    final Uri base = Uri.parse(rawUrl);
    final Map<String, String> params = Map<String, String>.of(
      base.queryParameters,
    )..removeWhere((String k, _) => _transformKeys.contains(k));
    if (wireW != null) params['w'] = '$wireW';
    if (wireH != null) params['h'] = '$wireH';
    params['fit'] = fit;
    params['format'] = format;
    return base.replace(queryParameters: params).toString();
  }

  @override
  bool operator ==(Object other) =>
      other is ImageVariant &&
      other.assetId == assetId &&
      other.wireW == wireW &&
      other.wireH == wireH &&
      other.fit == fit &&
      other.format == format &&
      other.query == query;

  @override
  int get hashCode => Object.hash(assetId, wireW, wireH, fit, format, query);

  @override
  String toString() => 'ImageVariant($resolvedUrl)';
}
