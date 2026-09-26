import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/routes/routes.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_text_styles.dart';
import 'app_button.dart';
import 'jameia_secondary_button.dart';
import 'state_icon_plate.dart';

/// A whole-screen state: a muted icon plate, an optional bold title, the grey
/// message and one pill action. `.error` retries with a secondary button;
/// `.signedOut` sends the customer to sign in with `go` (never `push`, so
/// every page cubit is rebuilt for the new session).
class JameiaStateView extends StatelessWidget {
  const JameiaStateView({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.title,
    this.actionLabel,
    this.onAction,
    this.secondaryAction = false,
  }) : _signIn = false;

  /// Error with retry. [message] defaults to `core.something_went_wrong`.
  const JameiaStateView.error({
    super.key,
    String? message,
    required VoidCallback onRetry,
    this.icon = Icons.error_outline_rounded,
  }) : message = message ?? '',
       title = null,
       actionLabel = null,
       onAction = onRetry,
       secondaryAction = true,
       _signIn = false;

  /// A customer route hit `UnauthorizedFailure`: the screen's own invitation
  /// (e.g. `'orders.sign_in_required'.tr()`) and a sign-in button.
  const JameiaStateView.signedOut({super.key, required this.message})
    : icon = Icons.person_outline_rounded,
      title = null,
      actionLabel = null,
      onAction = null,
      secondaryAction = false,
      _signIn = true;

  final String message;
  final IconData icon;
  final String? title;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// The action is a white outlined pill instead of the green one.
  final bool secondaryAction;
  final bool _signIn;

  @override
  Widget build(BuildContext context) {
    final text = message.isEmpty ? 'core.something_went_wrong'.tr() : message;
    final label =
        actionLabel ??
        (_signIn
            ? 'core.sign_in'.tr()
            : (secondaryAction ? 'retry'.tr() : null));
    final VoidCallback? action = _signIn
        ? () => context.go(Routes.login)
        : onAction;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StateIconPlate(icon: icon),
            const SizedBox(height: AppSpacing.s16),
            if (title != null) ...[
              Text(
                title!,
                textAlign: TextAlign.center,
                style: AppTextStyles.groupTitle,
              ),
              const SizedBox(height: AppSpacing.s8),
            ],
            Text(
              text,
              textAlign: TextAlign.center,
              style: AppTextStyles.itemTitle.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
            if (label != null && action != null) ...[
              const SizedBox(height: AppSpacing.s24),
              if (secondaryAction)
                JameiaSecondaryButton(label: label, onPressed: action)
              else
                AppButton(label: label, onPressed: action, expanded: false),
            ],
          ],
        ),
      ),
    );
  }
}
