import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../../../core/widgets/hero_map.dart';

/// The picker map's picture as last taken (PNG bytes; the map's middle is
/// the pin) — what the form's map card shows. Taken while nothing moves:
/// the platform encodes the picture on the UI thread.
class MapPicture extends ValueNotifier<Uint8List?> {
  MapPicture() : super(null);

  static const String _logName = 'address';

  GoogleMapController? _map;
  bool _disposed = false;

  /// The map to picture, once it exists.
  void attach(GoogleMapController map) => _map = map;

  /// Pictures the map as it stands now; nothing while there is no map.
  Future<void> take() async {
    final map = _map;
    if (map == null) return;
    try {
      final bytes = await map.takeSnapshot();
      if (!_disposed && bytes != null) value = bytes;
    } on PlatformException catch (error) {
      log('map snapshot failed: $error', name: _logName);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
