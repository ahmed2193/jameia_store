import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';

/// Starts the Android Maps SDK ahead of the first map screen. Its first
/// start blocks the main thread for a moment — the first map would open
/// blank and stall — so a page that leads to a map (the saved addresses,
/// an order) calls [afterEntrance]: the SDK starts once that page has
/// finished coming in, never during a transition, once per app run. Other
/// platforms need nothing.
abstract final class HeroMapWarmup {
  static bool _started = false;

  static const String _logName = 'map';

  static void afterEntrance(BuildContext context) {
    if (_started || kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    _started = true;
    final entrance = ModalRoute.of(context)?.animation;
    if (entrance == null || entrance.isCompleted) {
      unawaited(_warm());
      return;
    }
    void landed(AnimationStatus status) {
      if (status.isAnimating) return;
      entrance.removeStatusListener(landed);
      if (status.isCompleted) {
        unawaited(_warm());
      } else {
        _started = false; // the page left before it landed: next time
      }
    }

    entrance.addStatusListener(landed);
  }

  static Future<void> _warm() async {
    try {
      await GoogleMapsFlutterAndroid().warmup();
    } on Object catch (error) {
      log('maps warm-up failed: $error', name: _logName);
    }
  }
}
