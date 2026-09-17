import 'package:flutter/foundation.dart';

/// `extra` for [Routes.pdpImageViewer]: everything the full-screen PDP image
/// viewer needs to open at a given page. The route pops with the final page
/// index (`int`).
@immutable
class PdpImageViewerArgs {
  const PdpImageViewerArgs({
    required this.images,
    required this.kcal,
    required this.initialIndex,
  });

  /// Product photo URLs, in gallery order.
  final List<String> images;

  /// Calories; a trailing nutrition page is shown when > 0.
  final int kcal;

  /// Page the viewer opens on.
  final int initialIndex;
}
