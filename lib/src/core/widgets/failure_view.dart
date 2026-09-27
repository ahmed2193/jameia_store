import 'dart:async';

import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../error/failures.dart';
import '../utils/failure_message.dart';
import 'connectivity_scope.dart';
import 'error_view.dart';
import 'jameia_state_view.dart';

/// The whole-screen state of a first load that failed with nothing saved to
/// show — rule C.4 of the offline screen contract, in one place:
///
///   * a [NetworkFailure] while the app knows it is offline → the calm "No
///     connection" state (the screen loads by itself when the connection
///     returns);
///   * a [NetworkFailure] while the app does NOT know it is offline (one
///     slow request at launch, a network hand-over) → "Checking your
///     connection…" first, never "No connection" straight away: a live
///     check ([ConnectivityScope.recheckerOf]) held for at least
///     [AppConstants.offlineDebounce], so the verdict lands with the banner.
///     Reachable → the screen loads again by itself; not → "No connection";
///   * a timeout: "No connection" once the app knows it is offline, else its
///     own "request timed out" error (server trouble is not offline);
///   * anything else → the error with its message ([error] when the page
///     draws its own).
class FailureView extends StatefulWidget {
  const FailureView({
    super.key,
    required this.failure,
    required this.onRetry,
    this.error,
  });

  final Failure? failure;
  final VoidCallback onRetry;

  /// The page's own error state for a failure that is not the lost
  /// connection; [ErrorView] when omitted.
  final Widget? error;

  @override
  State<FailureView> createState() => _FailureViewState();
}

class _FailureViewState extends State<FailureView> {
  bool _checking = false;
  bool _checked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkOnce();
  }

  @override
  void didUpdateWidget(FailureView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.failure != widget.failure) {
      _checked = false;
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
    unawaited(_settle(Future<bool>.microtask(recheck)));
  }

  Future<void> _settle(Future<bool> recheck) async {
    final (retry, _) = await (
      recheck,
      Future<void>.delayed(AppConstants.offlineDebounce),
    ).wait;
    if (!mounted) return;
    // The retry first: the page swaps this view for its loader in the same
    // frame, so "No connection" never flashes in between.
    if (retry) widget.onRetry();
    setState(() => _checking = false);
  }

  @override
  Widget build(BuildContext context) {
    final failure = widget.failure;
    final offline = ConnectivityScope.isOfflineOf(context);
    if (failure == null || !failure.isConnectionLoss(offline: offline)) {
      return widget.error ??
          ErrorView(message: failure?.localizedMessage, onRetry: widget.onRetry);
    }
    return _checking && !offline
        ? const JameiaStateView.checking()
        : JameiaStateView.offline(onRetry: widget.onRetry);
  }
}
