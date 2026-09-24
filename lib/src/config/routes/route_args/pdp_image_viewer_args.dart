import 'package:flutter/foundation.dart';

/// `extra` for [Routes.pdpImageViewer]: everything the full-screen product
/// image viewer needs to open at a given page. The route pops with the final
/// page index (`int`).
@immutable
class PdpImageViewerArgs {
  const PdpImageViewerArgs({required this.images, required this.initialIndex});

  /// Product photo URLs, in gallery order.
  final List<String> images;

  /// Page the viewer opens on.
  final int initialIndex;
}
