/// A caller's lifetime for `ImagePrefetcher.prefetch`: [cancel] drops every
/// job still queued for it (a job another live token shares stays). Downloads
/// already on the wire finish and land on disk; nothing is ever retried.
class PrefetchToken {
  bool _cancelled = false;
  final List<void Function()> _listeners = <void Function()>[];

  bool get isCancelled => _cancelled;

  /// Runs [listener] once, on [cancel]; adding the same listener twice keeps
  /// one. A no-op after cancellation (the caller checks [isCancelled] first).
  void onCancel(void Function() listener) {
    if (_cancelled || _listeners.contains(listener)) return;
    _listeners.add(listener);
  }

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    final List<void Function()> listeners = List.of(_listeners);
    _listeners.clear();
    for (final void Function() l in listeners) {
      l();
    }
  }
}

/// What one `ImagePrefetcher.prefetch` call did with its distinct URLs:
/// [queued] jobs it waited on (new or joined), each settled as [done]
/// (downloaded), disk (counted in [skippedDisk] with the URLs skipped up
/// front), offline ([skippedOffline], likewise), [cancelled] or [failed]
/// (likewise: a URL that failed within the prefetcher's negative-cache TTL is
/// skipped up front and counted here).
typedef PrefetchResult = ({
  int queued,
  int skippedDisk,
  int skippedOffline,
  int done,
  int cancelled,
  int failed,
});

/// The prefetcher's process-lifetime negative cache: a URL whose warm-up
/// failed (a 404, an EXIF 500, a timeout) is skipped for [ttl], so a repeated
/// warm-up does not re-send a doomed GET that can hold a fetch slot for the
/// 25 s header timeout. At most [maxEntries]; the oldest goes first.
class PrefetchFailures {
  PrefetchFailures({
    this.ttl = const Duration(minutes: 10),
    this.maxEntries = 256,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final Duration ttl;
  final int maxEntries;
  final DateTime Function() _now;
  final Map<String, DateTime> _at = <String, DateTime>{};

  /// [url] failed less than [ttl] ago.
  bool contains(String url) {
    final DateTime? at = _at[url];
    if (at == null) return false;
    if (_now().difference(at) < ttl) return true;
    _at.remove(url);
    return false;
  }

  void add(String url) {
    _at.remove(url); // re-inserted last: the map stays oldest-first
    if (_at.isNotEmpty && _at.length >= maxEntries) _at.remove(_at.keys.first);
    _at[url] = _now();
  }
}

/// The debug `prefetch …` line for [r], logged under `IMGCACHE` (so the VM
/// log tail prints the reference's `[IMGCACHE] prefetch queued=…` line).
String prefetchSummary(PrefetchResult r) =>
    'prefetch '
    'queued=${r.queued} skipped_disk=${r.skippedDisk} '
    'skipped_offline=${r.skippedOffline} done=${r.done} '
    'cancelled=${r.cancelled} failed=${r.failed}';
