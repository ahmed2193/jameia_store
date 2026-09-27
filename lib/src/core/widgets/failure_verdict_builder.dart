import 'dart:async';

import 'package:flutter/widgets.dart';

import '../constants/app_constants.dart';
import '../domain/entities/connection_recheck.dart';
import '../error/failures.dart';
import 'connectivity_scope.dart';

/// What a load that failed with nothing saved to show should say.
enum FailureVerdict {
  /// A lost connection the app does not know about yet: the live check runs.
  checking,

  /// The connection is lost: the screen loads by itself when it returns.
  offline,

  /// The connection is there but the store did not answer (it failed again
  /// after its automatic retry): the error, never "No connection".
  unreachable,

  /// Anything else: the error with its message and a retry.
  error,
}

/// Rule C.4 of the offline screen contract, written once for every layout
/// (a whole screen, a block under a product card, a reviews section):
///
///   * a [NetworkFailure] while the app knows it is offline → [offline];
///   * a [NetworkFailure] while the app does NOT know it is offline (one
///     slow request at launch, a network hand-over) → [checking] first,
///     never "No connection" straight away: a live check
///     ([ConnectivityScope.recheckerOf]) held for at least
///     [AppConstants.offlineDebounce], so the verdict lands with the banner.
///     [ConnectionRecheck.retry] → [onRetry] runs by itself;
///     [ConnectionRecheck.reachable] → [unreachable];
///     [ConnectionRecheck.offline] → [offline];
///   * a timeout → [offline] once the app knows it is offline, else
///     [error] (server trouble is not offline);
///   * anything else → [error].
///
/// [builder] draws the verdict in the caller's layout.
class FailureVerdictBuilder extends StatefulWidget {
  const FailureVerdictBuilder({
    super.key,
    required this.failure,
    required this.onRetry,
    required this.builder,
  });

  final Failure? failure;

  /// Loads again — also by itself when the live check finds the connection.
  final VoidCallback onRetry;
  final Widget Function(BuildContext context, FailureVerdict verdict) builder;

  @override
  State<FailureVerdictBuilder> createState() => _FailureVerdictBuilderState();
}

class _FailureVerdictBuilderState extends State<FailureVerdictBuilder> {
  bool _checked = false;

  /// What the live check answered; `null` before it did (or while it runs).
  ConnectionRecheck? _answer;
  bool _checking = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkOnce();
  }

  @override
  void didUpdateWidget(FailureVerdictBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.failure != widget.failure) {
      _checked = false;
      _answer = null;
      _checkOnce();
    }
  }

  void _checkOnce() {
    if (_checked || widget.failure is! NetworkFailure) return;
    _checked = true;
    if (ConnectivityScope.readIsOffline(context)) return;
    final recheck = ConnectivityScope.recheckerOf(context);
    if (recheck == null) return;
    _checking = true;
    // Started after this build: the check updates the connection state.
    unawaited(_settle(Future<ConnectionRecheck>.microtask(recheck)));
  }

  Future<void> _settle(Future<ConnectionRecheck> recheck) async {
    final (answer, _) = await (
      recheck,
      Future<void>.delayed(AppConstants.offlineDebounce),
    ).wait;
    if (!mounted) return;
    // The retry first: the page swaps this view for its loader in the same
    // frame, so "No connection" never flashes in between.
    if (answer == ConnectionRecheck.retry) widget.onRetry();
    setState(() {
      _checking = false;
      _answer = answer;
    });
  }

  FailureVerdict _verdict(Failure? failure, {required bool offline}) {
    if (failure == null || !failure.isConnectionLoss(offline: offline)) {
      return FailureVerdict.error;
    }
    if (offline) return FailureVerdict.offline;
    if (_checking) return FailureVerdict.checking;
    return _answer == null || _answer == ConnectionRecheck.offline
        ? FailureVerdict.offline
        : FailureVerdict.unreachable;
  }

  @override
  Widget build(BuildContext context) => widget.builder(
    context,
    _verdict(widget.failure, offline: ConnectivityScope.isOfflineOf(context)),
  );
}
