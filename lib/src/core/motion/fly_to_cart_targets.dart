import 'package:flutter/widgets.dart';

/// Where add-to-cart flights land: a stack of cart icons (docs/motion CC-33).
///
/// Index 0 is the base target — the shell's cart badge, set with [register].
/// A full-screen surface that carries its OWN cart icon (the product page, a
/// cart sheet, the checkout bar) [push]es a temporary destination on top and
/// [pop]s it on dispose, so a flight always lands on the icon on screen.
///
/// `FlyToCart` owns the app's one registry; this class holds no flight logic
/// and can be tested on its own.
class FlyToCartTargets {
  final List<GlobalKey> _keys = <GlobalKey>[];

  /// Where a flight launched now would land (the top of the stack), or null
  /// when nothing is registered.
  GlobalKey? get top => _keys.isEmpty ? null : _keys.last;

  /// How many destinations are stacked (the base included).
  int get length => _keys.length;

  /// Every destination, the one a flight would try first leading (the top of
  /// the stack down to the base).
  Iterable<GlobalKey> get fromTop => _keys.reversed;

  /// Sets the base destination. Calling again replaces it (a rebuilt shell)
  /// and keeps every pushed destination above it.
  void register(GlobalKey key) {
    if (_keys.isEmpty) {
      _keys.add(key);
    } else {
      _keys[0] = key;
    }
  }

  /// Routes flights to [key] until it is [pop]ped.
  void push(GlobalKey key) => _keys.add(key);

  /// Removes a destination added by [push]; the one below it rules again.
  /// Unknown keys are ignored.
  void pop(GlobalKey key) => _keys.remove(key);
}
