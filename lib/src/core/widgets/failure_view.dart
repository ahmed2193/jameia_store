import 'package:flutter/material.dart';

import '../error/failures.dart';
import '../motion/fade_through_switcher.dart';
import 'failure_verdict_builder.dart';
import 'hero_state_view.dart';
import 'state_issue.dart';

/// The whole-screen state of a first load that failed with nothing saved to
/// show — rule C.4 of the offline screen contract ([FailureVerdictBuilder])
/// as a full screen: "Checking your connection…" while the live check runs
/// (never "No connection" straight away), the calm "No connection" state
/// (the screen loads by itself when the connection returns), "Can't reach
/// Hero" when the connection is there but the store is not, or the failure
/// told by what went wrong ([HeroStateView.failure]: the timeout, the
/// server's trouble, the maintenance, the refusal …, each with its own
/// moving plate) with a retry. A verdict that changes in place (checking →
/// offline) cross-fades: the dots sit where the offline art's disc lands, so
/// nothing jumps.
class FailureView extends StatelessWidget {
  const FailureView({
    super.key,
    required this.failure,
    required this.onRetry,
    this.message,
  });

  final Failure? failure;
  final VoidCallback onRetry;

  /// The screen's own words for a failure that is not about the connection
  /// (the issue's or the store's words when omitted).
  final String? message;

  @override
  Widget build(BuildContext context) => FailureVerdictBuilder(
    failure: failure,
    onRetry: onRetry,
    builder: (context, verdict) => FadeThroughSwitcher(
      stateKey: verdict,
      crossFade: true,
      child: switch (verdict) {
        FailureVerdict.checking => const HeroStateView.checking(),
        FailureVerdict.offline => HeroStateView.offline(onRetry: onRetry),
        FailureVerdict.unreachable => HeroStateView.issue(
          issue: StateIssue.unreachable,
          onRetry: onRetry,
        ),
        FailureVerdict.error => HeroStateView.failure(
          failure: failure,
          message: message,
          onRetry: onRetry,
        ),
      },
    ),
  );
}
