import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/round_back_button.dart';

/// The white round back button of the redesigned screens, shown only when
/// there is a page to go back to: login is usually the root of the stack
/// (`context.go` after sign-out / expiry), but Mine pushes it.
class AuthBackButton extends StatelessWidget {
  const AuthBackButton({super.key});

  @override
  Widget build(BuildContext context) =>
      context.canPop() ? const RoundBackButton() : const SizedBox.shrink();
}
