import 'dart:async';
import 'dart:developer';

import 'package:dartz/dartz.dart';

import '../../../../core/data/repositories/base_repository_mixin.dart';
import '../../../../core/domain/entities/cart_entity.dart';
import '../../../../core/domain/entities/cart_item_request.dart';
import '../../../../core/domain/entities/cart_line_entity.dart';
import '../../../../core/domain/entities/cart_line_ref.dart';
import '../../../../core/domain/entities/catalog_product_entity.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/cart_pending_change.dart';
import '../../domain/entities/cart_projection.dart';
import '../../domain/entities/cart_snapshot.dart';
import '../../domain/repositories/cart_repository.dart';
import '../datasources/cart_local_data_source.dart';
import '../datasources/cart_remote_data_source.dart';
import '../mappers/cart_mapper.dart';
import '../models/cart_mirror_model.dart';
import '../models/cart_model.dart';

/// Offline-first mirror of the server cart.
///
/// * Quantity taps merge into ONE pending change per line (`+3` instead of
///   three requests) and apply to the projected cart at once.
/// * A single write lane serializes every request, so replies arrive in
///   order and each one carries the whole cart, which replaces the server
///   copy; the pending change a reply covered is dropped (or, when more taps
///   landed while it was in flight, reduced to what is still owed).
/// * New lines go out in one `POST /v1/cart/items` batch, existing lines as
///   absolute `PATCH` / `DELETE` calls, [flushDelay] after the last tap.
/// * A transport failure keeps the changes (`isUnsynced`) and retries after
///   [retryDelay], doubling up to [maxRetryDelay] while it keeps failing;
///   a rejection drops what was sent and refetches the cart.
/// * The server cart and the pending changes are written to the device
///   [persistDelay] after they change; [restore] paints them at cold start.
/// * [reset] bumps a generation: a reply of an older generation is ignored.
class CartRepositoryImpl with BaseRepositoryMixin implements CartRepository {
  CartRepositoryImpl(
    this._remote,
    this._local, {
    this.flushDelay = defaultFlushDelay,
    this.retryDelay = defaultRetryDelay,
    this.persistDelay = defaultPersistDelay,
  });

  static const Duration defaultFlushDelay = Duration(milliseconds: 400);
  static const Duration defaultRetryDelay = Duration(seconds: 5);

  /// Ceiling of the retry back-off. A customer who walks out of coverage
  /// used to cost one request every [retryDelay] for as long as the cart
  /// screen lived; the wait now doubles to this and stays there.
  static const Duration maxRetryDelay = Duration(seconds: 80);
  static const Duration defaultPersistDelay = Duration(milliseconds: 300);
  static const int _serverErrorFloor = 500;
  static const String _logName = 'CartRepositoryImpl';

  final CartRemoteDataSource _remote;
  final CartLocalDataSource _local;
  final Duration flushDelay;
  final Duration retryDelay;
  final Duration persistDelay;

  final StreamController<CartSnapshot> _changes =
      StreamController<CartSnapshot>.broadcast();
  final Map<CartLineRef, CartPendingChange> _pending =
      <CartLineRef, CartPendingChange>{};

  CartSnapshot _snapshot = const CartSnapshot();
  CartEntity _server = CartEntity.empty;
  CartModel? _serverModel;
  String _ownerId = '';
  bool _restored = false;
  bool _unsynced = false;
  int _generation = 0;
  int _activeRequests = 0;
  bool _flushQueued = false;
  Future<void> _lane = Future<void>.value();
  Timer? _flushTimer;
  Timer? _retryTimer;

  /// How long the next retry waits: [retryDelay] doubled once per failed
  /// attempt, reset by a reply that got through or by a fresh tap.
  Duration _retryBackoff = Duration.zero;
  Timer? _persistTimer;

  /// The latest snapshot (tests and the cubit's first frame).
  CartSnapshot get snapshot => _snapshot;

  // ── Stream ───────────────────────────────────────────────────────────────

  @override
  Stream<CartSnapshot> watch() {
    late final StreamController<CartSnapshot> out;
    StreamSubscription<CartSnapshot>? subscription;
    out = StreamController<CartSnapshot>(
      onListen: () {
        out.add(_snapshot);
        subscription = _changes.stream.listen(out.add);
      },
      onCancel: () => subscription?.cancel(),
    );
    return out.stream;
  }

  void _emit({Failure? failure, CartAction failedAction = CartAction.none}) {
    final next = CartSnapshot(
      cart: _server.project(_pending),
      isRestored: _restored,
      isSyncing: _activeRequests > 0,
      hasPendingChanges: _pending.isNotEmpty,
      isUnsynced: _unsynced,
      failure: failure,
      failedAction: failedAction,
      revision: _snapshot.revision + 1,
    );
    // A failure always goes out (two equal-looking ones must both be seen);
    // anything that moved nothing does not.
    if (failure == null && next.sameStateAs(_snapshot)) return;
    _snapshot = next;
    if (!_changes.isClosed) _changes.add(_snapshot);
  }

  // ── Lifecycle ────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, Unit>> restore() => execute(() async {
    CartMirrorModel? mirror;
    try {
      mirror = _local.readMirror();
    } on AppException catch (error) {
      log('mirror dropped: $error', name: _logName);
      await _local.clearMirror();
    }
    if (mirror != null) {
      _ownerId = mirror.ownerId;
      final cart = mirror.cart;
      if (cart != null) {
        _serverModel = cart;
        _server = cart.toEntity();
      }
      _pending
        ..clear()
        ..addAll(mirror.pending.toEntities());
    }
    _restored = true;
    _emit();
    return unit;
  });

  @override
  Future<Either<Failure, Unit>> syncOwner(String ownerId) => _laneOp(() async {
    if (_ownerId != ownerId) {
      // A guest's unsent taps follow the customer they just became; another
      // customer's mirror never does.
      final keepPending =
          _ownerId.isEmpty || _ownerId == CartRepository.guestOwnerId;
      if (!keepPending) {
        // A customer's replies still in flight must not land in the next
        // owner's cart.
        _generation++;
        _cancelTimers();
        _flushQueued = false;
        _pending.clear();
        _unsynced = false;
      }
      _server = CartEntity.empty;
      _serverModel = null;
      _ownerId = ownerId;
      _markDirty();
      _emit();
    }
    try {
      await _enqueue(_fetchTask);
    } on AppException catch (error) {
      _afterFetchFailure(error);
      rethrow;
    }
    if (_pending.isNotEmpty) await _enqueue(_flushTask);
  });

  @override
  Future<Either<Failure, Unit>> reset() => execute(() async {
    _generation++;
    _cancelTimers();
    _flushQueued = false;
    _pending.clear();
    _server = CartEntity.empty;
    _serverModel = null;
    _unsynced = false;
    _ownerId = '';
    _restored = true;
    _emit();
    await _local.clearMirror();
    return unit;
  });

  /// Tests only: stops timers and closes the stream.
  void dispose() {
    _cancelTimers();
    _changes.close();
  }

  void _cancelTimers() {
    _flushTimer?.cancel();
    _flushTimer = null;
    _retryTimer?.cancel();
    _retryTimer = null;
    _persistTimer?.cancel();
    _persistTimer = null;
  }

  // ── Optimistic line changes ──────────────────────────────────────────────

  @override
  Either<Failure, Unit> adjustLine({
    required CatalogProductEntity product,
    String? variantId,
    required int delta,
  }) => executeSync(() {
    final ref = CartLineRef(product.id, variantId);
    _merge(
      ref,
      (_pending[ref] ?? CartPendingChange(ref: ref)).plus(
        delta,
        product: product,
      ),
    );
    return unit;
  });

  @override
  Either<Failure, Unit> setLineQuantity(CartLineRef ref, int quantity) =>
      executeSync(() {
        final current = _pending[ref] ?? CartPendingChange(ref: ref);
        _merge(ref, current.setTo(quantity, product: _productOf(ref)));
        return unit;
      });

  @override
  Either<Failure, Unit> removeLine(CartLineRef ref) => setLineQuantity(ref, 0);

  CatalogProductEntity? _productOf(CartLineRef ref) =>
      _server.lineFor(ref)?.product;

  void _merge(CartLineRef ref, CartPendingChange change) {
    if (change.isNoOp) {
      _pending.remove(ref);
    } else {
      _pending[ref] = change;
    }
    // Fresh activity: retry now rather than after the back-off.
    _retryTimer?.cancel();
    _retryTimer = null;
    _resetRetryBackoff();
    _scheduleFlush();
    _markDirty();
    _emit();
  }

  void _scheduleFlush() {
    _flushTimer?.cancel();
    _flushTimer = Timer(flushDelay, () {
      _flushTimer = null;
      _queueFlush();
    });
  }

  void _queueFlush() {
    if (_flushQueued) return;
    _flushQueued = true;
    unawaited(
      _enqueue(() {
        _flushQueued = false;
        return _flushTask();
      }).catchError((Object error) {
        // The failure already reached the UI through the snapshot _flushTask
        // emitted; a retryable one is queued again.
        log('flush stopped: $error', name: _logName);
      }),
    );
  }

  @override
  Future<Either<Failure, Unit>> flush() {
    _flushTimer?.cancel();
    _flushTimer = null;
    return _laneOp(() => _enqueue(_flushTask));
  }

  /// Sends pending changes until none is left. Rethrows the exception that
  /// stopped it, so the caller's `execute` reports one failure on one
  /// channel; a retryable one is also queued for another try.
  Future<void> _flushTask() async {
    while (_pending.isNotEmpty) {
      final round = _nextRound();
      if (round.isEmpty) return;
      try {
        final CartModel reply;
        if (round.first.line == null) {
          reply = await _request(
            () => _remote.addItems([
              for (final sent in round)
                CartItemRequest(
                  productId: sent.change.ref.productId,
                  variantId: sent.change.ref.variantId,
                  quantity: sent.applied,
                ).toBody(),
            ]),
          );
        } else {
          final sent = round.first;
          final line = sent.line!;
          final target = line.quantity + sent.applied;
          reply = await _request(
            () => target <= 0
                ? _remote.removeLine(line.key)
                : _remote.setLineQuantity(line.key, target),
          );
        }
        _acceptServerCart(reply);
        round.forEach(_rebase);
        _unsynced = false;
        _resetRetryBackoff();
        _emit();
      } on _StaleReply {
        log('flush reply dropped: the cart was replaced', name: _logName);
        return;
      } on AppException catch (error) {
        final failure = mapToFailure(error);
        if (_isRetryable(error)) {
          _unsynced = true;
          _emit(failure: failure, failedAction: CartAction.sync);
          _scheduleRetry();
          rethrow;
        }
        // Rejected (out of stock, bad line …): forget what was sent and take
        // the server's word on what the cart holds now.
        for (final sent in round) {
          _pending.remove(sent.change.ref);
        }
        _markDirty();
        try {
          await _fetchTask();
        } on AppException catch (fetchError) {
          log('refetch after rejection failed: $fetchError', name: _logName);
        }
        _emit(failure: failure, failedAction: CartAction.sync);
        // The change was rejected, not lost: the cart now holds the server's
        // word, so the call itself is done.
        return;
      }
    }
  }

  /// What to send next: every new line in one batch, else the first
  /// existing line that changed. No-op changes are pruned on the way.
  List<_SentChange> _nextRound() {
    final posts = <_SentChange>[];
    _SentChange? patch;
    for (final change in _pending.values.toList(growable: false)) {
      final line = _server.lineFor(change.ref);
      if (line == null) {
        final target = change.targetQuantity(0);
        if (target <= 0) {
          _pending.remove(change.ref);
        } else if (posts.length < CartItemRequest.maxItemsPerRequest) {
          posts.add(_SentChange(change, applied: target));
        }
      } else {
        final applied = change.targetQuantity(line.quantity) - line.quantity;
        if (applied == 0) {
          _pending.remove(change.ref);
        } else {
          patch ??= _SentChange(change, line: line, applied: applied);
        }
      }
    }
    if (posts.isNotEmpty) return posts;
    return patch == null ? const <_SentChange>[] : <_SentChange>[patch];
  }

  /// Drops the change a reply covered, or keeps what arrived meanwhile.
  void _rebase(_SentChange sent) {
    final ref = sent.change.ref;
    final current = _pending[ref];
    if (current == null) return;
    if (current.version == sent.change.version) {
      _pending.remove(ref);
      return;
    }
    final remaining = current.afterApplied(sent.applied);
    if (remaining == null) {
      _pending.remove(ref);
    } else {
      _pending[ref] = remaining;
    }
  }

  void _scheduleRetry() {
    if (_retryTimer != null) return;
    final wait = _retryBackoff == Duration.zero ? retryDelay : _retryBackoff;
    _retryBackoff = wait * 2 > maxRetryDelay ? maxRetryDelay : wait * 2;
    _retryTimer = Timer(wait, () {
      _retryTimer = null;
      _queueFlush();
    });
  }

  /// Back to the first, short wait: the connection just worked, or the
  /// customer is tapping again and expects the cart to try now.
  void _resetRetryBackoff() => _retryBackoff = Duration.zero;

  bool _isRetryable(AppException error) => switch (error) {
    NetworkException() => true,
    RateLimitedException() => true,
    ServerException(:final statusCode) =>
      (statusCode ?? _serverErrorFloor) >= _serverErrorFloor,
    _ => false,
  };

  // ── Server-confirmed operations ──────────────────────────────────────────

  @override
  Future<Either<Failure, Unit>> fetch() => _laneOp(() async {
    try {
      await _enqueue(_fetchTask);
    } on AppException catch (error) {
      _afterFetchFailure(error);
      rethrow;
    }
    if (_pending.isNotEmpty) _scheduleFlush();
  });

  /// The cart could not be read. Whatever the customer already tapped stays
  /// in the queue, so it is marked unsynced and retried instead of waiting
  /// for the next tap.
  void _afterFetchFailure(AppException error) {
    if (_pending.isNotEmpty) {
      _unsynced = true;
      _scheduleRetry();
    }
    _emit(failure: mapToFailure(error), failedAction: CartAction.sync);
  }

  @override
  Future<Either<Failure, Unit>> addItems(List<CartItemRequest> items) {
    // What to send is the use case's rule (validity, the per-request cap).
    if (items.isEmpty) return Future.value(const Right(unit));
    return _serverOp(
      () => _remote.addItems(items.toBody()),
      action: CartAction.addItems,
    );
  }

  @override
  Future<Either<Failure, Unit>> clear() => _laneOp(() async {
    final previous = _server;
    final previousModel = _serverModel;
    _pending.clear();
    _flushTimer?.cancel();
    _flushTimer = null;
    _server = CartEntity(cartToken: previous.cartToken);
    _serverModel = null;
    _markDirty();
    _emit();
    await _enqueue(() async {
      try {
        _acceptServerCart(await _request(_remote.clear));
      } on AppException catch (error) {
        // Roll back unless a newer reply already replaced the cart.
        if (_serverModel == null) {
          _server = previous;
          _serverModel = previousModel;
          _markDirty();
        }
        // On the snapshot, so the asynchronous stream cannot erase it —
        // see the note on _serverOp.
        _emit(failure: mapToFailure(error), failedAction: CartAction.clear);
        rethrow;
      }
      _emit();
    });
  });

  @override
  Future<Either<Failure, Unit>> applyCoupon(String code) =>
      _serverOp(() => _remote.applyCoupon(code), action: CartAction.coupon);

  @override
  Future<Either<Failure, Unit>> removeCoupon() =>
      _serverOp(_remote.removeCoupon, action: CartAction.coupon);

  @override
  Future<Either<Failure, Unit>> applyLoyalty(int points) =>
      _serverOp(() => _remote.applyLoyalty(points), action: CartAction.loyalty);

  @override
  Future<Either<Failure, Unit>> removeLoyalty() =>
      _serverOp(_remote.removeLoyalty, action: CartAction.loyalty);

  @override
  Future<Either<Failure, Unit>> setExpress({required bool enabled}) =>
      _serverOp(
        () => _remote.setExpress(enabled: enabled),
        action: CartAction.express,
      );

  /// Runs [call] on the lane after the pending taps went out, so the server
  /// applies it to the cart the customer sees.
  /// One server-confirmed cart write. [action] is what the customer asked
  /// for, and a refusal goes out ON THE SNAPSHOT under that name.
  ///
  /// The snapshot stream is asynchronous, so a snapshot emitted here lands in
  /// the cubit AFTER the `Either` this returns. Emitting it without the
  /// failure erased the one the cubit had just recorded, and a refused coupon
  /// looked to the customer like nothing happened at all.
  Future<Either<Failure, Unit>> _serverOp(
    Future<CartModel> Function() call, {
    required CartAction action,
  }) => _laneOp(
    () => _enqueue(() async {
      // The taps must be on the server first, or the coupon / loyalty /
      // express reply would price a cart the customer no longer sees.
      await _flushTask();
      try {
        _acceptServerCart(await _request(call));
        _emit();
      } on AppException catch (error) {
        _emit(failure: mapToFailure(error), failedAction: action);
        rethrow;
      }
    }),
  );

  /// Runs [body] on the write lane. A reset / owner change that happened
  /// meanwhile abandons the work on purpose, so it reports success: the UI
  /// must not raise an error for a cart nobody owns any more.
  Future<Either<Failure, Unit>> _laneOp(Future<void> Function() body) =>
      execute(() async {
        try {
          await body();
        } on _StaleReply {
          log('lane task abandoned: the cart was replaced', name: _logName);
        }
        return unit;
      });

  Future<void> _fetchTask() async {
    try {
      _acceptServerCart(await _request(_remote.getCart));
    } on _StaleReply {
      log('cart reply dropped: another owner took the lane', name: _logName);
      return;
    }
    _emit();
  }

  // ── Lane, replies, persistence ───────────────────────────────────────────

  /// Serializes [task] behind every queued request. A task queued before a
  /// [reset] never runs after it.
  Future<T> _enqueue<T>(Future<T> Function() task) {
    final generation = _generation;
    final run = _lane.then((_) {
      if (generation != _generation) throw const _StaleReply();
      return task();
    });
    _lane = run.then<void>((_) {}, onError: (_) {});
    return run;
  }

  Future<CartModel> _request(Future<CartModel> Function() call) async {
    final generation = _generation;
    _activeRequests++;
    _emit();
    try {
      final reply = await call();
      if (generation != _generation) throw const _StaleReply();
      return reply;
    } on _StaleReply {
      rethrow;
    } on AppException {
      if (generation != _generation) throw const _StaleReply();
      rethrow;
    } finally {
      _activeRequests--;
      // Every early return above (stale reply, thrown failure) would leave
      // the last snapshot claiming a request is still in flight.
      if (_activeRequests == 0) _emit();
    }
  }

  void _acceptServerCart(CartModel model) {
    _serverModel = model;
    _server = model.toEntity();
    _restored = true;
    _markDirty();
    unawaited(
      _local.rememberCartToken(model.cartToken).catchError((Object error) {
        log('cart token not stored: $error', name: _logName);
      }),
    );
  }

  void _markDirty() {
    _persistTimer ??= Timer(persistDelay, () {
      _persistTimer = null;
      unawaited(_persist());
    });
  }

  Future<void> _persist() async {
    final mirror = CartMirrorModel(
      ownerId: _ownerId.isEmpty ? CartRepository.guestOwnerId : _ownerId,
      cart: _serverModel,
      pending: [for (final change in _pending.values) change.toModel()],
    );
    try {
      await _local.saveMirror(mirror);
    } on AppException catch (error) {
      log('mirror not saved: $error', name: _logName);
    }
  }
}

/// A change as it went out: the version sent and the quantity delta the
/// request applied (for a new line, its whole quantity).
class _SentChange {
  const _SentChange(this.change, {this.line, required this.applied});

  final CartPendingChange change;
  final CartLineEntity? line;
  final int applied;
}

/// The reply belongs to a generation that [CartRepository.reset] ended.
class _StaleReply implements Exception {
  const _StaleReply();
}
