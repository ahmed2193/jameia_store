import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/routes/routes.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_text_styles.dart';
import '../design/hero_assets.dart';
import '../design/hero_icons.dart';
import 'app_button.dart';
import 'hero_secondary_button.dart';
import 'state_art.dart';
import 'state_art_loader.dart';
import 'state_icon_plate.dart';

/// A whole-screen state: its illustration ([StateArt]; a muted icon plate
/// when a screen has no [art]), an optional bold title, the grey message and
/// one pill action. `.error` retries with a secondary button; `.signedOut`
/// sends the customer to sign in with `go` (never `push`, so every page
/// cubit is rebuilt for the new session); `.offline` is the calm "no
/// connection" state of a screen with nothing saved to show; `.checking`
/// holds its place — the dots where the offline art's disc will be — while
/// the app checks whether it really is offline.
class HeroStateView extends StatelessWidget {
  const HeroStateView({
    super.key,
    required this.message,
    this.icon = HeroIcons.inbox,
    this.art,
    this.title,
    this.actionLabel,
    this.onAction,
    this.secondaryAction = false,
  }) : _signIn = false,
       _offline = false,
       _checking = false;

  /// Error with retry. [message] defaults to `core.something_went_wrong`.
  const HeroStateView.error({
    super.key,
    String? message,
    required VoidCallback onRetry,
  }) : message = message ?? '',
       icon = HeroIcons.warning,
       art = HeroAssets.stateError,
       title = null,
       actionLabel = null,
       onAction = onRetry,
       secondaryAction = true,
       _signIn = false,
       _offline = false,
       _checking = false;

  /// A customer route hit `UnauthorizedFailure`: the screen's own invitation
  /// (e.g. `'orders.sign_in_required'.tr()`) and a sign-in button.
  const HeroStateView.signedOut({super.key, required this.message})
    : icon = HeroIcons.person,
      art = HeroAssets.stateSignedOut,
      title = null,
      actionLabel = null,
      onAction = null,
      secondaryAction = false,
      _signIn = true,
      _offline = false,
      _checking = false;

  /// No connection and nothing saved to show: "No connection — this page
  /// loads as soon as you're back online" (the screen retries by itself on
  /// reconnect) and "Try again" to try now. Not an error: no red.
  const HeroStateView.offline({super.key, required VoidCallback onRetry})
    : message = '',
      icon = HeroIcons.offline,
      art = HeroAssets.stateOffline,
      title = null,
      actionLabel = null,
      onAction = onRetry,
      secondaryAction = true,
      _signIn = false,
      _offline = true,
      _checking = false;

  /// A first load failed for want of a connection and the app is checking
  /// whether it really is offline: the branded dots and "Checking your
  /// connection…", no action. It becomes the offline state, or the screen
  /// loads again by itself.
  const HeroStateView.checking({super.key})
    : message = '',
      icon = HeroIcons.wifi,
      art = null,
      title = null,
      actionLabel = null,
      onAction = null,
      secondaryAction = false,
      _signIn = false,
      _offline = false,
      _checking = true;

  final String message;

  /// The plate's glyph when there is no [art].
  final IconData icon;

  /// A `HeroAssets` state / empty illustration, drawn by [StateArt].
  final String? art;
  final String? title;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// The action is a white outlined pill instead of the green one.
  final bool secondaryAction;
  final bool _signIn;
  final bool _offline;
  final bool _checking;

  @override
  Widget build(BuildContext context) {
    final text = _checking
        ? 'connectivity.checking'.tr()
        : _offline
        ? 'connectivity.offline_state_message'.tr()
        : (message.isEmpty ? 'core.something_went_wrong'.tr() : message);
    final heading = _offline ? 'connectivity.offline_state_title'.tr() : title;
    final label =
        actionLabel ??
        (_signIn
            ? 'core.sign_in'.tr()
            : (secondaryAction ? 'retry'.tr() : null));
    final VoidCallback? action = _signIn
        ? () => context.go(Routes.login)
        : onAction;
    final asset = art;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_checking)
              const StateArtLoader()
            else if (asset != null)
              StateArt(asset: asset)
            else
              StateIconPlate(icon: icon),
            const SizedBox(height: AppSpacing.s16),
            if (heading != null) ...[
              Text(
                heading,
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
                HeroSecondaryButton(label: label, onPressed: action)
              else
                AppButton(label: label, onPressed: action, expanded: false),
            ],
          ],
        ),
      ),
    );
  }
}
