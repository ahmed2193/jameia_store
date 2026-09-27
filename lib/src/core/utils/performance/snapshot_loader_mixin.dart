import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/data_snapshot.dart';
import '../../error/failures.dart';

/// The subscription half of the offline screen contract, written once: it
/// follows a cached read's snapshots and owns everything around them.
///
///   * [followSnapshots] runs one load per channel: starting a load cancels
///     the one still running there, so its late snapshots (a slow disk read
///     that lands after a refresh's network reply) are never delivered, and
///     nothing is delivered after [close];
///   * [refreshOnReconnect] is single-flight: a reconnect that is reported
///     twice (two tabs, a quick flap) still sends one request, and a read
///     already asking the server answers first.
///
/// A screen whose state holds a `ScreenLoad` gets the whole screen flow on
/// top of this from `ScreenLoaderMixin`; a cubit with its own flow (several
/// reads shown together) decides here what a snapshot or a failure means.
mixin SnapshotLoaderMixin<S> on Cubit<S> {
  static const Object _mainChannel = Object();

  final Map<Object, _Load> _loads = <Object, _Load>{};
  Future<void>? _reconnecting;

  /// Follows [source] on [channel] until it ends, replacing the load running
  /// there. Completes when this load is over — done, replaced, or the cubit
  /// closed — so a pull-to-refresh spinner can await it.
  Future<void> followSnapshots<T>(
    Stream<DataSnapshot<T>> source, {
    required void Function(DataSnapshot<T> snapshot) onSnapshot,
    required void Function(Failure failure) onFailure,
    Object channel = _mainChannel,
  }) {
    unawaited(_loads.remove(channel)?.cancel());
    final load = _Load();
    _loads[channel] = load;
    load.subscription = source.listen(
      (snapshot) {
        if (!isClosed) onSnapshot(snapshot);
      },
      onError: (Object error) {
        if (isClosed) return;
        onFailure(error is Failure ? error : UnexpectedFailure('$error'));
      },
      onDone: () {
        if (identical(_loads[channel], load)) _loads.remove(channel);
        load.finish();
      },
    );
    return load.done;
  }

  /// A load is still running on [channel] (a saved copy is being checked
  /// with the server).
  bool isReading([Object channel = _mainChannel]) =>
      _loads.containsKey(channel);

  /// Runs [refresh] once for a reconnect when [needed] (the screen is stale
  /// or failed). A read still running on [channel] answers first — its reply
  /// may make the refresh unnecessary; with none the refresh starts at once
  /// — and a second call while all this runs joins it.
  Future<void> refreshOnReconnect({
    required bool Function() needed,
    required Future<void> Function() refresh,
    Object channel = _mainChannel,
  }) => _reconnecting ??= _reconnect(
    needed,
    refresh,
    _loads[channel],
  ).whenComplete(() => _reconnecting = null);

  Future<void> _reconnect(
    bool Function() needed,
    Future<void> Function() refresh,
    _Load? running,
  ) async {
    if (running != null) await running.done;
    if (!isClosed && needed()) await refresh();
  }

  /// Cancels every load without waiting: the cancel of a read parked on its
  /// request only completes with that request, and the cubit must be closed
  /// at once (a popped page does no more work).
  @override
  Future<void> close() {
    final loads = _loads.values.toList();
    _loads.clear();
    for (final load in loads) {
      unawaited(load.cancel());
    }
    return super.close();
  }
}

/// One running load: its subscription and the future its caller awaits.
class _Load {
  StreamSubscription<Object?>? subscription;
  final Completer<void> _done = Completer<void>();

  Future<void> get done => _done.future;

  void finish() {
    if (!_done.isCompleted) _done.complete();
  }

  Future<void> cancel() async {
    finish();
    await subscription?.cancel();
  }
}
