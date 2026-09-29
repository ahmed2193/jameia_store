import 'package:flutter/material.dart';

import '../error/failures.dart';
import '../motion/fade_through_switcher.dart';
import '../utils/failure_message.dart';
import 'error_view.dart';
import 'failure_verdict_builder.dart';
import 'hero_state_view.dart';

/// The whole-screen state of a first load that failed with nothing saved to
/// show — rule C.4 of the offline screen contract ([FailureVerdictBuilder])
/// as a full screen: "Checking your connection…" while the live check runs
/// (never "No connection" straight away), the calm "No connection" state
/// (the screen loads by itself when the connection returns), or the error
/// with a retry ([errorBuilder] when the page draws its own). A verdict that
/// changes in place (checking → offline) cross-fades: the dots sit where the
/// offline art's disc lands, so nothing jumps.
class FailureView extends StatelessWidget {
  const FailureView({
    super.key,
    required this.failure,
    required this.onRetry,
    this.errorBuilder,
  });

  final Failure? failure;
  final VoidCallback onRetry;

  /// The page's own error state; `message` is the failure's text, or
  /// `null` for the generic one (the connection is there but the store did
  /// not answer — its own "no internet" text would be wrong). [ErrorView]
  /// when omitted.
  final Widget Function(String? message)? errorBuilder;

  @override
  Widget build(BuildContext context) => FailureVerdictBuilder(
    failure: failure,
    onRetry: onRetry,
    builder: (context, verdict) {
      // Unreachable: the generic words — its own "no internet" would be wrong.
      final message = verdict == FailureVerdict.unreachable
          ? null
          : failure?.localizedMessage;
      return FadeThroughSwitcher(
        // The two error verdicts are one screen.
        stateKey: verdict == FailureVerdict.unreachable
            ? FailureVerdict.error
            : verdict,
        crossFade: true,
        child: switch (verdict) {
          FailureVerdict.checking => const HeroStateView.checking(),
          FailureVerdict.offline => HeroStateView.offline(onRetry: onRetry),
          FailureVerdict.unreachable || FailureVerdict.error =>
            errorBuilder?.call(message) ??
                ErrorView(message: message, onRetry: onRetry),
        },
      );
    },
  );
}
