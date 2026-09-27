import 'package:flutter/foundation.dart';

/// `extra` for [Routes.pdpImageViewer]: everything the full-screen product
/// image viewer needs to open at a given page. The route pops with the final
/// page index (`int`).
@immutable
class PdpImageViewerArgs {
  const PdpImageViewerArgs({
    required this.images,
    required this.initialIndex,
    required this.productSlug,
  });

  /// Product photo URLs, in gallery order.
  final List<String> images;

  /// Page the viewer opens on.
  final int initialIndex;

  /// The product the photos belong to: its page is the only one the photo
  /// flies back to (another product page with the same photo is not).
  final String productSlug;
}
