import 'dart:async';
import 'dart:ui' show VoidCallback;

import '../../../../../core/motion/motion.dart';

/// One run of the camera riding along with the rider
/// ([LiveMapChaseCamera]): it glides in first — the native camera's own
/// glide, from wherever it was, over [AppMotion.cameraGlide] — and only
/// once it is there does it keep to the rider frame by frame ([live]);
/// never both at once, so the two never fight over the camera. [end] stops
/// either: the customer took the map, the ride stands still, the screen
/// went.
class LiveMapChase {
  Timer? _flyIn;
  bool _live = false;
  double? _trackedMeters;

  /// The camera rides along: gliding in, or there.
  bool get active => _live || _flyIn != null;

  /// The camera is there and keeps to the rider frame by frame.
  bool get live => _live;

  /// The glide in has started; [onLive] once it is over.
  void flyIn(VoidCallback onLive) {
    end();
    _flyIn = Timer(AppMotion.cameraGlide, () {
      _flyIn = null;
      _live = true;
      onLive();
    });
  }

  /// Whether the camera moves for a rider shown at [meters]: once live,
  /// when they moved since the camera last did ([force]: whatever it last
  /// did — the room around the map changed). Records it when so.
  bool shouldTrack(double meters, {bool force = false}) {
    if (!_live || (!force && meters == _trackedMeters)) return false;
    _trackedMeters = meters;
    return true;
  }

  void end() {
    _flyIn?.cancel();
    _flyIn = null;
    _live = false;
    _trackedMeters = null;
  }
}
