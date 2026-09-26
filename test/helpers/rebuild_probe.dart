import 'package:flutter/widgets.dart';

/// Counts `build()` runs of widgets of type [W], bucketed by [keyOf] — for
/// tests that pin a rebuild scope ("a tap on line A never rebuilds line B").
/// `debugOnRebuildDirtyWidget` fires for every element build, dirty or forced
/// by its parent. One probe at a time:
///
/// ```dart
/// final rows = RebuildProbe<CartLineTile, CartLineRef>((w) => w.lineRef)
///   ..start();
/// addTearDown(rows.stop);
/// ```
class RebuildProbe<W extends Widget, K> {
  RebuildProbe(this.keyOf);

  final K Function(W widget) keyOf;
  final Map<K, int> _counts = <K, int>{};

  void start() {
    assert(debugOnRebuildDirtyWidget == null, 'one probe at a time');
    debugOnRebuildDirtyWidget = (Element element, bool builtOnce) {
      final widget = element.widget;
      if (widget is W) {
        _counts.update(keyOf(widget), (n) => n + 1, ifAbsent: () => 1);
      }
    };
  }

  void stop() => debugOnRebuildDirtyWidget = null;

  void reset() => _counts.clear();

  int of(K key) => _counts[key] ?? 0;

  int get total => _counts.values.fold(0, (a, b) => a + b);
}
