import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_cache_manager/flutter_cache_manager.dart'
    show BaseCacheManager, CacheManager;

import 'hero_image_cache_manager.dart';
import 'image_disk_index.dart';
import 'image_load_trace.dart';
import 'image_net_activity.dart';
import 'image_prefetch_gate.dart';
import 'image_prefetch_token.dart';
import 'media_log.dart';

export 'image_net_activity.dart' show ImageGetLease, ImageNetActivity;
export 'image_prefetch_token.dart';

enum _Outcome { disk, offline, done, cancelled, failed }

/// One URL's job, queued on creation; shared by every token that wants it.
class _Job {
  _Job(this.url, this.isOnline, Queue<_Job> queue) {
    queue.add(this);
  }
  final String url;
  final bool Function() isOnline;
  final List<PrefetchToken> tokens = <PrefetchToken>[];
  final Completer<_Outcome> outcome = Completer<_Outcome>();
  bool get live => tokens.any((PrefetchToken t) => !t.isCancelled);
}

/// Disk warm-up for the images a screen is about to show; each URL is the
/// EXACT variant (= disk cacheKey) the destination requests. Skips disk-known,
/// recently failed ([PrefetchFailures]) and offline URLs, joins a URL already
/// queued here, runs the rest through `concurrency` workers: `downloadFile`,
/// which joins an in-flight load of the same key (WebHelper `_memCache`,
/// flutter_cache_manager 3.4.3 web_helper.dart:32-46) and whose file service
/// marks [ImageDiskIndex]. No `getFileFromCache` probe: after the index seed
/// a key it lacks is not on disk, and one that is anyway costs a conditional
/// GET → 304 (the CDN sends a stable ETag).
///
/// Start gate: a [SharedQuietGate] — ONE quiet-UI wait shared by the workers,
/// inside a budget a call that queues new work restarts; once spent, the rest
/// runs back to back, so the metadata writes of its downloads coalesce in the
/// repository's flush. A failure is swallowed and remembered. A static
/// singleton ([instance]); never in get_it.
class ImagePrefetcher {
  ImagePrefetcher({
    BaseCacheManager Function()? manager,
    bool Function(String cacheKey)? isKnownOnDisk,
    bool Function()? isOnline,
    QuietUiGate gate = const QuietUiGate(),
    PrefetchFailures? failures,
  }) : _manager = manager ?? (() => HeroImageCacheManager.loader),
       _isKnownOnDisk = isKnownOnDisk ?? _knownOnDisk,
       _isOnline = isOnline ?? (() => true),
       _gate = SharedQuietGate(gate),
       _failures = failures ?? PrefetchFailures();

  static final ImagePrefetcher instance = ImagePrefetcher();

  /// Of the image store's 10 fetch slots; visible tiles keep the rest.
  static const int maxConcurrency = 3;

  final BaseCacheManager Function() _manager;
  final bool Function(String) _isKnownOnDisk;
  final bool Function() _isOnline;
  final SharedQuietGate _gate;
  final PrefetchFailures _failures;
  final Queue<_Job> _queue = Queue<_Job>();
  final Map<String, _Job> _jobs = <String, _Job>{};
  int _running = 0;

  /// The load policy's sync probe: disk index, then the real store's memory.
  static bool _knownOnDisk(String k) {
    if (ImageDiskIndex.instance.contains(k)) return true;
    final BaseCacheManager m = HeroImageCacheManager.loader;
    return m is CacheManager && m.store.memoryCacheContainsKey(k);
  }

  /// Queues [resolvedUrls] for [token]; completes when each one is settled.
  /// [isOnline] overrides the constructor's connectivity read for this call.
  Future<PrefetchResult> prefetch(
    List<String> resolvedUrls, {
    required PrefetchToken token,
    int concurrency = 2,
    bool Function()? isOnline,
  }) async {
    final bool Function() online = isOnline ?? _isOnline;
    final List<Future<_Outcome>> mine = <Future<_Outcome>>[];
    final Set<String> seen = <String>{};
    int disk = 0, offline = 0, failed = 0;
    bool fresh = false;
    for (final String url in resolvedUrls) {
      if (token.isCancelled) break;
      if (url.isEmpty || !seen.add(url)) continue;
      if (_isKnownOnDisk(url)) {
        disk++;
      } else if (_failures.contains(url)) {
        failed++;
      } else if (!online()) {
        offline++;
      } else {
        final _Job job = _jobs[url] ??= _Job(url, online, _queue);
        fresh |= job.tokens.isEmpty;
        job.tokens.add(token);
        mine.add(job.outcome.future);
      }
    }
    if (mine.isNotEmpty) token.onCancel(_purge);
    if (fresh) _gate.restart(); // new work: a new defer budget
    final int cap = concurrency.clamp(1, maxConcurrency);
    while (_running < cap && _queue.isNotEmpty) {
      _running++;
      unawaited(_worker());
    }
    final List<_Outcome> out = await Future.wait(mine);
    int n(_Outcome o) => out.where((_Outcome x) => x == o).length;
    final PrefetchResult r = (
      queued: mine.length,
      skippedDisk: disk + n(_Outcome.disk),
      skippedOffline: offline + n(_Outcome.offline),
      done: n(_Outcome.done),
      cancelled: n(_Outcome.cancelled),
      failed: failed + n(_Outcome.failed),
    );
    if (kDebugMode && ImageLoadTrace.enabled) {
      MediaLog.line(MediaLog.trace, prefetchSummary(r));
    }
    return r;
  }

  Future<void> _worker() async {
    while (_queue.isNotEmpty) {
      final _Job job = _queue.removeFirst();
      _finish(job, await _run(job)); // _run never throws
    }
    _running--;
  }

  Future<_Outcome> _run(_Job job) async {
    try {
      await _gate.wait(() => job.live);
      if (!job.live) return _Outcome.cancelled;
      if (!job.isOnline()) return _Outcome.offline;
      if (_isKnownOnDisk(job.url)) return _Outcome.disk; // landed meanwhile
      ImageNetActivity.prefetchStarted(job.url); // not a screen's GET
      try {
        await _manager().downloadFile(job.url); // the service marks the index
      } finally {
        ImageNetActivity.prefetchEnded(job.url);
      }
      return _Outcome.done;
    } catch (_) {
      if (!job.isOnline()) return _Outcome.offline; // the network, not the URL
      _failures.add(job.url);
      return _Outcome.failed;
    }
  }

  /// Settles [job] (once) and forgets it; true, for [_purge]'s predicate.
  bool _finish(_Job job, _Outcome o) {
    if (identical(_jobs[job.url], job)) _jobs.remove(job.url);
    if (!job.outcome.isCompleted) job.outcome.complete(o);
    return true;
  }

  /// A token was cancelled: the queued jobs no live token wants drop now.
  void _purge() =>
      _queue.removeWhere((_Job j) => !j.live && _finish(j, _Outcome.cancelled));
}
