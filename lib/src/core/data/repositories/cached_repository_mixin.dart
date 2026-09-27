import 'dart:async';
import 'dart:developer';

import '../../domain/entities/data_snapshot.dart';
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
///      so the screen keeps the copy and marks it stale.
///
/// A copy that no longer parses (the DTO changed, a corrupt file) is a miss:
/// it is deleted and logged, never shown as an error. A reply that lands
/// after the owner changed (signed out mid-request) is not saved. A copy
/// saved "in the future" (the clock moved back) is shown but never counts as
/// fresh. With [forceRefresh] the copy is not read at all: the screen already
/// shows data and wants the server's.
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
    if (cache != null && !forceRefresh) {
      final copy = await _readCopy(cache, toEntity);
      if (copy != null) {
        yield copy;
        final age = cacheClock().difference(copy.fetchedAt);
        final fresh = !age.isNegative && age < cache.namespace.freshFor;
        if (fresh) return;
      }
    }
    final payload = await fetch();
    final fetchedAt = cacheClock();
    final data = toEntity(payload.model);
    if (cache != null) _save(cache, payload.raw, fetchedAt);
    yield DataSnapshot<E>(
      data: data,
      fetchedAt: fetchedAt,
      origin: SnapshotOrigin.network,
    );
  }

  /// The device copy as a snapshot, or `null` — a miss, a copy past the
  /// namespace's `maxAge`, or one that no longer parses (then deleted).
  Future<DataSnapshot<E>?> _readCopy<M, E>(
    CacheSlot<M> cache,
    E Function(M model) toEntity,
  ) async {
    final saved = await cache.read();
    if (saved == null) return null;
    final age = cacheClock().difference(saved.savedAt);
    if (age > cache.namespace.maxAge) return null;
    try {
      return DataSnapshot<E>(
        data: toEntity(cache.parse(saved.data)),
        fetchedAt: saved.savedAt,
        origin: SnapshotOrigin.cache,
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
