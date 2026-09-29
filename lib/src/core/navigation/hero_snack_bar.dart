import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../error/failures.dart';
import '../motion/motion.dart';
import '../utils/failure_message.dart';
import '../widgets/connectivity_scope.dart';
import 'hero_snack_content.dart';
import 'hero_snack_message.dart';

export 'hero_snack_message.dart' show HeroSnackTone;

/// The snack a messenger shows right now, while it is on screen.
final Expando<_ShownSnack> _shownSnacks = Expando<_ShownSnack>('hero snack');

class _ShownSnack {
  _ShownSnack(this.message);

  final HeroSnackMessage message;
  bool open = true;
}

/// The one way to show a transient message (docs/motion §9.4 #15, B3-03).
///
/// A floating snack ([AppTheme]'s snack bar theme) with a [tone] glyph
/// (success / warning / error / offline; [HeroSnackTone.info] has none) and
/// an optional action — "Undo", "View" — named [actionLabel] and run by
/// [onAction] (the snack closes on the tap). It rises in over
/// [AppMotion.medium], stays [AppMotion.snackDwell] (with an action too),
/// and leaves over [AppMotion.fast]. A new message while one is on screen
/// takes its place at once and its words cross-fade from the old ones —
/// rapid messages never queue, and never leave and come back.
void showHeroSnackBar(
  BuildContext context,
  String message, {
  HeroSnackTone tone = HeroSnackTone.info,
  String? actionLabel,
  VoidCallback? onAction,
}) => showHeroSnackBarOn(
  ScaffoldMessenger.of(context),
  message,
  tone: tone,
  actionLabel: actionLabel,
  onAction: onAction,
);

/// [showHeroSnackBar] on a [messenger] read before an `await` — for a flow
/// whose own widget may be gone when the answer comes (the cart that turns
/// into its empty state once cleared).
void showHeroSnackBarOn(
  ScaffoldMessengerState messenger,
  String message, {
  HeroSnackTone tone = HeroSnackTone.info,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  if (!messenger.mounted) return;
  final next = HeroSnackMessage(message, tone: tone);
  final current = _shownSnacks[messenger];
  final previous = current != null && current.open ? current.message : null;
  final replacing = previous != null;
  final motion = messenger.context;
  if (replacing) {
    // In place: no exit, no entrance — the words cross-fade instead.
    messenger.removeCurrentSnackBar();
  } else {
    messenger.hideCurrentSnackBar();
  }
  final shown = _ShownSnack(next);
  _shownSnacks[messenger] = shown;
  final label = actionLabel;
  final controller = messenger.showSnackBar(
    SnackBar(
      content: HeroSnackContent(
        key: ValueKey<HeroSnackMessage>(next),
        message: next,
        previous: previous,
      ),
      action: label == null || onAction == null
          ? null
          : SnackBarAction(label: label, onPressed: onAction),
      duration: AppMotion.snackDwell,
      persist: false,
    ),
    snackBarAnimationStyle: AnimationStyle(
      duration: replacing
          ? Duration.zero
          : MotionGuard.duration(motion, AppMotion.medium),
      reverseDuration: MotionGuard.duration(motion, AppMotion.fast),
    ),
  );
  unawaited(controller.closed.then((_) => shown.open = false));
}

/// [showFailureSnackBar] for a failed ACTION, on a [messenger] read before
/// an `await` — for an outcome that lands after its screen is gone (a
/// delete refused once the customer left the list). [offline] is what the
/// app knew when it was read (the banner is not nudged from here).
void showActionFailureSnackBarOn(
  ScaffoldMessengerState messenger,
  Failure failure, {
  required bool offline,
}) {
  final lost = failure.isConnectionLoss(offline: offline);
  showHeroSnackBarOn(
    messenger,
    lost ? 'connectivity.action_needs_internet'.tr() : failure.localizedMessage,
    tone: lost ? HeroSnackTone.offline : HeroSnackTone.error,
  );
}

/// The one way to tell the customer a request failed.
///
/// A READ that failed in transport (no connection, timeout) shows nothing of
/// its own: the failure already asked for a connection check, and the
/// banner — once that check confirms it — and the screen's stale note speak.
/// Never a "No internet" toast before the app knows (while offline the
/// banner is nudged). A failed [action] (a submit, a save, a toggle: the
/// customer's input is kept) says "you're offline, your changes are kept"
/// once for a lost connection (the offline tone; the banner is nudged), its
/// own message otherwise. Anything else shows
/// [FailureMessage.localizedMessage] in the error tone.
void showFailureSnackBar(
  BuildContext context,
  Failure failure, {
  bool action = false,
}) {
  final offline = ConnectivityScope.readIsOffline(context);
  if (offline && failure.isTransport) ConnectivityScope.nudge(context);
  if (action) {
    showActionFailureSnackBarOn(
      ScaffoldMessenger.of(context),
      failure,
      offline: offline,
    );
    return;
  }
  if (failure.isTransport) return;
  showHeroSnackBar(
    context,
    failure.localizedMessage,
    tone: HeroSnackTone.error,
  );
}
