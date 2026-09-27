import 'package:flutter/material.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/responsive/content_clamp.dart';
import '../../../../core/widgets/failure_view.dart';
import '../../domain/entities/home_bootstrap.dart';
import 'home_header_sliver.dart';

/// Home that failed with nothing saved to show: the real header stays
/// usable (address, search, bell) above [FailureView]. A lost connection
/// shows "Checking your connection…" until the app knows, then home loads
/// again by itself or the calm "No connection" state shows (it loads home
/// when the connection returns) — never "No connection" straight away at
/// app open. Any other failure is the error + retry.
class HomeFailureView extends StatelessWidget {
  const HomeFailureView({
    super.key,
    required this.bootstrap,
    required this.failure,
    required this.onRetry,
  });

  /// The launch snapshot; empty until it lands.
  final HomeBootstrap bootstrap;
  final Failure? failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => ContentClamp(
    child: CustomScrollView(
      slivers: [
        HomeHeaderSliver(bootstrap: bootstrap),
        SliverFillRemaining(
          hasScrollBody: false,
          child: FailureView(failure: failure, onRetry: onRetry),
        ),
      ],
    ),
  );
}
