import 'package:flutter/scheduler.dart';

/// What the chat list knows about its newest row (index 0 of the reversed
/// list), shared by that row's [AssistantAnchoredItem] and the list's
/// [AssistantAnchoredScrollPhysics].
///
/// The newest row reports its height on every layout. When the SAME row
/// grows (a streamed word, a card arriving) the growth is kept as a pending
/// delta for the physics to take in the same frame: while the reader is
/// scrolled up — or the reply is taller than the screen — the list moves by
/// that delta so what they read stays still. A row that is new, or a row
/// rebuilt after being scrolled far away, reports no delta: the sliver keeps
/// the visible rows in place by itself then.
class AssistantScrollAnchor {
  String? _key;
  double? _extent;
  double _pending = 0;
  bool _resetScheduled = false;

  /// The list is running its own scroll animation (back to the newest
  /// message): growth is not compensated meanwhile — the animation owns the
  /// offset, and a correction would only make it jitter.
  bool suspended = false;

  /// Height of the newest row at its last layout (`0` before any).
  double get newestExtent => _extent ?? 0;

  /// Called by the newest row after its layout. [previousExtent] is the
  /// row's own height before this layout, `null` on its first layout.
  void report(String key, double extent, double? previousExtent) {
    final sameRow = _key == key && previousExtent != null;
    _key = key;
    _extent = extent;
    if (!sameRow) return;
    final delta = extent - previousExtent;
    if (delta == 0) return;
    _pending += delta;
    _scheduleReset();
  }

  /// The growth since the physics last looked; reading it clears it.
  double takePending() {
    final delta = _pending;
    _pending = 0;
    return delta;
  }

  /// A delta the physics did not take this frame (the scroll extents did
  /// not change) must not leak into a later, unrelated frame.
  void _scheduleReset() {
    if (_resetScheduled) return;
    _resetScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _resetScheduled = false;
      _pending = 0;
    });
  }
}
