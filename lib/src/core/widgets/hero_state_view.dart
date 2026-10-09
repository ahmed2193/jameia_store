import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../config/routes/route_args/shell_tabs.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_text_styles.dart';
import '../design/hero_assets.dart';
import '../design/hero_icons.dart';
import '../error/failures.dart';
import '../motion/entrance_cascade_item.dart';
import '../motion/pop_scale.dart';
import '../navigation/sign_in_flow.dart';
import '../utils/failure_message.dart';
import 'app_button.dart';
import 'hero_secondary_button.dart';
import 'state_art.dart';
import 'state_art_loader.dart';
import 'state_icon_plate.dart';
import 'state_issue.dart';

/// A whole-screen state: its illustration ([StateArt]; a muted icon plate
/// when a screen has no [art]), an optional bold title, the grey message and
/// one pill action. `.failure` tells a failed load by what went wrong
/// ([StateIssue]: its own moving plate, title and words) with a retry;
/// `.error` is the same for a failure the screen words itself;
/// `.signedOut` sends the customer to sign in with `go` (never `push`, so
/// every page cubit is rebuilt for the new session) and back here once
/// signed in ([SignInFlow.open]); `.offline` is the calm "no connection"
/// state of a screen with nothing saved to show; `.checking` holds its
/// place — the dots where the offline art's disc will be — while the app
/// checks whether it really is offline.
///
/// It arrives once, on mount: the art settles in ([StateArt]; a plain plate
/// pops from [PopScale.artFrom]), then the words and the action rise in a
/// step apart ([EntranceCascadeItem.single]). Still under reduced motion;
/// an issue plate then acts its issue out, twice at most ([StateArt]).
class HeroStateView extends StatelessWidget {
  const HeroStateView({
    super.key,
    required this.message,
    this.icon = HeroIcons.inbox,
    this.art,
    this.illustration,
    this.title,
    this.actionLabel,
    this.onAction,
    this.secondaryAction = false,
  }) : issue = null,
       failure = null,
       _signIn = false,
       _checking = false,
       signInTab = ShellTab.home;

  /// Error with retry, in the screen's own words: the [StateIssue.unexpected]
  /// plate, "Something went wrong" and [message] ("Please try again" when
  /// omitted). A failed load whose [Failure] is known is [failure]'s.
  const HeroStateView.error({
    Key? key,
    String? message,
    required VoidCallback onRetry,
  }) : this._issue(
         key: key,
         issue: StateIssue.unexpected,
         art: HeroAssets.stateError,
         message: message,
         onRetry: onRetry,
       );

  /// A load that failed, told by what went wrong ([StateIssue.of]): the
  /// issue's moving plate, its title, and the store's own words when they
  /// are for the customer (the issue's words otherwise); [message] words it
  /// instead. A retry, or a sign-in for an [UnauthorizedFailure].
  factory HeroStateView.failure({
    Key? key,
    required Failure? failure,
    required VoidCallback onRetry,
    String? message,
    ShellTab signInTab = ShellTab.home,
  }) => HeroStateView.issue(
    key: key,
    issue: StateIssue.of(failure),
    failure: failure,
    message: message,
    onRetry: onRetry,
    signInTab: signInTab,
  );

  /// The screen of an [issue]: its plate, its title and [message] (or the
  /// words [failure] / the issue bring). Retries with a secondary pill;
  /// [StateIssue.signedOut] signs in instead (back to [signInTab] in the
  /// main shell).
  factory HeroStateView.issue({
    Key? key,
    required StateIssue issue,
    Failure? failure,
    String? message,
    VoidCallback? onRetry,
    ShellTab signInTab = ShellTab.home,
  }) => HeroStateView._issue(
    key: key,
    issue: issue,
    art: issue.art,
    failure: failure,
    message: message,
    onRetry: onRetry,
    signInTab: signInTab,
  );

  const HeroStateView._issue({
    super.key,
    required StateIssue this.issue,
    required String this.art,
    this.failure,
    String? message,
    VoidCallback? onRetry,
    this.signInTab = ShellTab.home,
  }) : message = message ?? '',
       icon = HeroIcons.warning,
       illustration = null,
       title = null,
       actionLabel = null,
       onAction = onRetry,
       secondaryAction = true,
       _signIn = false,
       _checking = false;

  /// A customer route hit `UnauthorizedFailure`: the screen's own invitation
  /// (e.g. `'orders.sign_in_required'.tr()`) and a sign-in button. Signing
  /// in comes back to this page; in the main shell, to [signInTab] (the tab
  /// the state sits in).
  const HeroStateView.signedOut({
    super.key,
    required this.message,
    this.signInTab = ShellTab.home,
  }) : icon = HeroIcons.person,
       art = HeroAssets.stateSignedOut,
       issue = null,
       failure = null,
       illustration = null,
       title = null,
       actionLabel = null,
       onAction = null,
       secondaryAction = false,
       _signIn = true,
       _checking = false;

  /// No connection and nothing saved to show: "No connection — this page
  /// loads as soon as you're back online" (the screen retries by itself on
  /// reconnect) and "Try again" to try now. Not an error: no red.
  const HeroStateView.offline({Key? key, required VoidCallback onRetry})
    : this._issue(
        key: key,
        issue: StateIssue.offline,
        art: HeroAssets.stateOffline,
        onRetry: onRetry,
      );

  /// A first load failed for want of a connection and the app is checking
  /// whether it really is offline: the branded dots and "Checking your
  /// connection…", no action. It becomes the offline state, or the screen
  /// loads again by itself.
  const HeroStateView.checking({super.key})
    : message = '',
      icon = HeroIcons.wifi,
      art = null,
      issue = null,
      failure = null,
      illustration = null,
      title = null,
      actionLabel = null,
      onAction = null,
      secondaryAction = false,
      _signIn = false,
      _checking = true,
      signInTab = ShellTab.home;

  /// The words; empty for the state's own (an [issue]'s, or "Something went
  /// wrong").
  final String message;

  /// The plate's glyph when there is no [art].
  final IconData icon;

  /// A `HeroAssets` state / empty illustration, drawn by [StateArt] (an
  /// [issue]'s own plate on a failure screen).
  final String? art;

  /// What went wrong, for a failure screen: its plate, title and words.
  final StateIssue? issue;

  /// The failure behind an [issue], for the store's own words.
  final Failure? failure;

  /// A composed illustration drawn in place of [art] / [icon] (the
  /// assistant with a prop).
  final Widget? illustration;
  final String? title;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// The action is a white outlined pill instead of the green one.
  final bool secondaryAction;
  final bool _signIn;
  final bool _checking;

  /// Where a signed-out state's sign-in comes back to in the main shell
  /// (a pushed page comes back to itself).
  final ShellTab signInTab;

  @override
  Widget build(BuildContext context) {
    final issue = this.issue;
    final heading = title ?? issue?.titleKey.tr();
    final text = _checking
        ? 'connectivity.checking'.tr()
        : issue != null
        ? _wordsOf(issue, heading)
        : (message.isEmpty ? 'core.something_went_wrong'.tr() : message);
    final signIn = _signIn || issue == StateIssue.signedOut;
    final secondary = secondaryAction && !signIn;
    final label =
        actionLabel ??
        (signIn ? 'core.sign_in'.tr() : (secondary ? 'retry'.tr() : null));
    final VoidCallback? action = signIn
        ? () => SignInFlow.open(context, tab: signInTab)
        : onAction;
    final asset = art;
    final drawn = illustration;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_checking)
              const StateArtLoader()
            else if (drawn != null)
              drawn
            else if (asset != null)
              StateArt(asset: asset)
            else
              PopScale.onMount(
                from: PopScale.artFrom,
                child: StateIconPlate(icon: icon),
              ),
            const SizedBox(height: AppSpacing.s16),
            EntranceCascadeItem.single(
              index: 1,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                ],
              ),
            ),
            if (label != null && action != null) ...[
              const SizedBox(height: AppSpacing.s24),
              EntranceCascadeItem.single(
                index: 2,
                child: secondary
                    ? HeroSecondaryButton(label: label, onPressed: action)
                    : AppButton(
                        label: label,
                        onPressed: action,
                        expanded: false,
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// [message] when given, else the store's own words when the issue says
  /// them, else the issue's own — never a repeat of the [heading].
  String _wordsOf(StateIssue issue, String? heading) {
    final words = message.isNotEmpty
        ? message
        : (issue.showsServerWords ? failure?.serverWords : null);
    return words == null || words == heading ? issue.messageKey.tr() : words;
  }
}
