import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/routes/routes.dart';
import 'error_view.dart';

/// What a customer route shows on `UnauthorizedFailure`: the screen's own
/// invitation plus one way out — `go` (never `push`), so every page cubit is
/// rebuilt for the new session.
class SignedOutView extends StatelessWidget {
  const SignedOutView({super.key, required this.message});

  /// Screen-specific text, e.g. `'orders.sign_in_required'.tr()`.
  final String message;

  @override
  Widget build(BuildContext context) =>
      ErrorView(message: message, onRetry: () => context.go(Routes.login));
}
