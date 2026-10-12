import 'package:flutter/foundation.dart' show visibleForTesting;

/// Image GETs on the wire for a screen: every GET the image file service
/// starts except the prefetcher's own (tagged with [prefetchStarted]). A 200
/// counts until its body is done, failed or cancelled; anything else until
/// its headers arrive (or fail). The prefetch gate waits while any is out.
abstract final class ImageNetActivity {
  static int _visible = 0;
  static final Set<String> _prefetching = <String>{};

  static int get visibleInFlight => _visible;

  /// The prefetcher's `downloadFile([url])` runs: its GET is not a screen's.
  static void prefetchStarted(String url) => _prefetching.add(url);

  static void prefetchEnded(String url) => _prefetching.remove(url);

  /// A GET of [url] starts: the lease to [ImageGetLease.end], or null for a
  /// prefetch GET (not counted).
  static ImageGetLease? begin(String url) =>
      _prefetching.contains(url) ? null : ImageGetLease._();

  @visibleForTesting
  static void debugReset() {
    _visible = 0;
    _prefetching.clear();
  }
}

/// One counted image GET; [end] is idempotent.
final class ImageGetLease {
  ImageGetLease._() {
    ImageNetActivity._visible++;
  }

  bool _ended = false;

  void end() {
    if (_ended) return;
    _ended = true;
    ImageNetActivity._visible--;
  }
}
