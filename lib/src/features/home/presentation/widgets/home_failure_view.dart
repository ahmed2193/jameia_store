import 'package:flutter/material.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/widgets/failure_view.dart';

/// Home that failed with nothing saved to show: the sliver under the real
/// header ([HomeFrame]), which stays usable (address, search, bell) above
/// [FailureView]. A lost connection shows "Checking your connection…" until
/// the app knows, then home loads again by itself or the calm "No
/// connection" state shows (it loads home when the connection returns) —
/// never "No connection" straight away at app open. Any other failure is
/// the error + retry.
class HomeFailureView extends StatelessWidget {
  const HomeFailureView({
    super.key,
    required this.failure,
    required this.onRetry,
  });

  final Failure? failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => SliverFillRemaining(
    hasScrollBody: false,
    child: FailureView(failure: failure, onRetry: onRetry),
  );
}
