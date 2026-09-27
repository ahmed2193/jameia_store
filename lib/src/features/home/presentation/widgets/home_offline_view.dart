import 'package:flutter/material.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/responsive/content_clamp.dart';
import '../../../../core/widgets/failure_view.dart';
import '../../domain/entities/home_bootstrap.dart';
import 'home_header_sliver.dart';

/// Home with no connection and nothing saved to show: the real header stays
/// usable (address, search, bell) above [FailureView] — "Checking your
/// connection…" until the app knows, then home loads again by itself or the
/// calm "No connection" state shows (it loads home when the connection
/// returns). Never "No connection" straight away at app open.
class HomeOfflineView extends StatelessWidget {
  const HomeOfflineView({
    super.key,
    required this.bootstrap,
    required this.onRetry,
  });

  /// The launch snapshot; empty until it lands.
  final HomeBootstrap bootstrap;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => ContentClamp(
    child: CustomScrollView(
      slivers: [
        HomeHeaderSliver(bootstrap: bootstrap),
        SliverFillRemaining(
          hasScrollBody: false,
          child: FailureView(failure: const NetworkFailure(), onRetry: onRetry),
        ),
      ],
    ),
  );
}
