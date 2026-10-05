import 'dart:async';
import 'dart:developer';

import '../../domain/entities/data_snapshot.dart';
import '../../error/exceptions.dart';
import '../../storage/json_cache_store.dart';
import '../datasources/cache_slots.dart';
import '../models/remote_payload.dart';
import 'base_repository_mixin.dart';

/// The ONE cache-then-network read every cached screen shares (the offline
/// screen contract). A repository calls [cachedRead] and exposes the stream:
///
///   1. the device copy first, at once — unless it is older than the
///      namespace's `maxAge`. A copy younger than `freshFor` ends the read
///      there: no request (a pull to refresh passes [forceRefresh]);
///   2. then the network: its snapshot replaces the copy and is saved
///      (fire and forget — a slow or failed write never delays the screen);
///   3. a failure arrives as a `Failure` on the error channel AFTER any copy,
///      so the screen keeps the copy and marks it stale. When no copy was
///      shown yet — [forceRefresh] skipped it, or it was past `maxAge` — the
///      saved copy comes first as a [SnapshotOrigin.fallback] snapshot: a
///      screen with nothing on it shows it (dated, stale) instead of an
///      error, and one that shows data keeps its own. So whatever asked —
///      a first load, a pull, a reconnect, a recreated screen — a failure
///      never hides what the device has saved.
///
/// A copy that no longer parses (the DTO changed, a corrupt file) is a miss:
/// it is deleted and logged, never shown as an error. A reply that lands
/// after the owner changed (signed out mid-request) is not saved, and no
/// copy is handed over for them. A copy saved "in the future" (the clock
/// moved back) is shown but never counts as fresh. With [forceRefresh] the
/// copy is read only when the request fails — the happy path costs no disk
/// read.
mixin CachedRepositoryMixin on BaseRepositoryMixin {
  static const String _logName = 'cache';

  /// What time it is (tests pin it).
  DateTime cacheClock() => DateTime.now();

  Stream<DataSnapshot<E>> cachedRead<M, E>({
    required CacheSlot<M>? cache,
    required Future<RemotePayload<M>> Function() fetch,
    required E Function(M model) toEntity,
    bool forceRefresh = false,
  }) => guardStream(
    _cachedRead(
      cache: cache,
      fetch: fetch,
      toEntity: toEntity,
      forceRefresh: forceRefresh,
    ),
  );

  Stream<DataSnapshot<E>> _cachedRead<M, E>({
    required CacheSlot<M>? cache,
    required Future<RemotePayload<M>> Function() fetch,
    required E Function(M model) toEntity,
    required bool forceRefresh,
  }) async* {
    var copyShown = false;
    // Past `maxAge`: not shown first, kept in case the request fails.
    CachedJson? tooOld;
    if (cache != null && !forceRefresh) {
      final saved = await cache.read();
      if (saved != null && _isTooOld(cache, saved)) {
        tooOld = saved;
      } else if (saved != null) {
        final copy = _snapshotOf(cache, saved, toEntity, SnapshotOrigin.cache);
        if (copy != null) {
          yield copy;
          copyShown = true;
          final age = cacheClock().difference(copy.fetchedAt);
          final fresh = !age.isNegative && age < cache.namespace.freshFor;
          if (fresh) return;
        }
      }
    }
    final RemotePayload<M> payload;
    try {
      payload = await fetch();
    } on Object catch (error) {
      if (cache != null && !copyShown && _copyMayStandIn(error)) {
        final fallback = await _fallback(
          cache,
          toEntity,
          saved: tooOld,
          readSaved: forceRefresh,
        );
        if (fallback != null) yield fallback;
      }
      rethrow;
    }
    final fetchedAt = cacheClock();
    final data = toEntity(payload.model);
    if (cache != null) _save(cache, payload.raw, fetchedAt);
    yield DataSnapshot<E>(
      data: data,
      fetchedAt: fetchedAt,
      origin: SnapshotOrigin.network,
    );
  }

  /// The connection or the server failed — the saved copy may stand in. A
  /// reply about the data itself — gone (404), not yours (401 / 403) — is
  /// the screen's answer, and a copy never hides it.
  static bool _copyMayStandIn(Object error) =>
      error is! UnauthorizedException &&
      error is! ForbiddenException &&
      error is! NotFoundException;

  bool _isTooOld<M>(CacheSlot<M> cache, CachedJson saved) =>
      cacheClock().difference(saved.savedAt) > cache.namespace.maxAge;

  /// The request failed with no copy on screen: the saved one, whatever its
  /// age — [saved] when the read already holds it (past `maxAge`), else
  /// read now when [readSaved] (a forced read skipped it) — or `null`. Never
  /// for an owner who changed during the request, and never an error of its
  /// own: the request's failure is what the screen is told.
  Future<DataSnapshot<E>?> _fallback<M, E>(
    CacheSlot<M> cache,
    E Function(M model) toEntity, {
    required CachedJson? saved,
    required bool readSaved,
  }) async {
    if (!cache.isCurrent) return null;
    try {
      final copy = saved ?? (readSaved ? await cache.read() : null);
      if (copy == null) return null;
      return _snapshotOf(cache, copy, toEntity, SnapshotOrigin.fallback);
    } on Object catch (error) {
      log(
        '${cache.namespace.name}: saved copy unreadable '
        '(${error.runtimeType})',
        name: _logName,
      );
      return null;
    }
  }

  /// [saved] as a snapshot from [origin], or `null` when it no longer
  /// parses (then deleted and logged).
  DataSnapshot<E>? _snapshotOf<M, E>(
    CacheSlot<M> cache,
    CachedJson saved,
    E Function(M model) toEntity,
    SnapshotOrigin origin,
  ) {
    try {
      return DataSnapshot<E>(
        data: toEntity(cache.parse(saved.data)),
        fetchedAt: saved.savedAt,
        origin: origin,
      );
    } on Object catch (error) {
      log(
        '${cache.namespace.name}: saved copy no longer parses '
        '(${error.runtimeType}) — dropped',
        name: _logName,
      );
      unawaited(cache.remove());
      return null;
    }
  }

  /// Keeps a mutation's reply as the device copy of the read it answers — a
  /// cancelled order replaces the order's copy, so a reopen offline shows it
  /// as it now is. Fire and forget; [cache] is taken when the request starts,
  /// so a reply for an owner who changed meanwhile is not saved.
  void keepReply<M>(CacheSlot<M>? cache, Object raw) {
    if (cache != null) _save(cache, raw, cacheClock());
  }

  void _save<M>(CacheSlot<M> cache, Object raw, DateTime fetchedAt) {
    if (!cache.isCurrent) {
      log(
        '${cache.namespace.name}: owner changed during the request — '
        'reply not saved',
        name: _logName,
      );
      return;
    }
    unawaited(cache.write(raw, savedAt: fetchedAt));
  }
}
