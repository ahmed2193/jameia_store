import 'package:flutter/widgets.dart';

import '../../../domain/entities/checkout_block_reason.dart';

/// Page-local UI signals of the checkout, shared by widgets that are far
/// apart in the tree (the place button, the destination row, the items
/// sheet, the payment section, the savings hint). Never business state:
/// what the order is lives in the cubits.
///
/// A sanctioned exception to "one cubit state per screen": these are pure
/// view signals (a shake serial, "open the items sheet", the hint was
/// dismissed, the anchors to scroll to). Provided once per page with a
/// `RepositoryProvider(create:, dispose:)`, which calls [dispose].
class CheckoutUiController {
  CheckoutUiController({DateTime Function()? clock})
    : clock = clock ?? DateTime.now;

  /// The time source of the page's clocks (the ETA card's minute clock);
  /// injectable for tests.
  final DateTime Function() clock;

  /// The savings hint was dismissed for this visit (tap, scroll, a failed
  /// place).
  final ValueNotifier<bool> hintDismissed = ValueNotifier<bool>(false);

  /// The last blocked tap on "Place order" and its serial (so the same
  /// reason twice still shakes twice); `null` before the first one.
  final ValueNotifier<(CheckoutBlockReason, int)?> blocked =
      ValueNotifier<(CheckoutBlockReason, int)?>(null);

  /// Bumped to ask the order summary to open the items sheet.
  final ValueNotifier<int> itemsRequests = ValueNotifier<int>(0);

  /// Bumped when the payment method was switched on the customer's behalf,
  /// so the section can draw the eye to it.
  final ValueNotifier<int> paymentBumps = ValueNotifier<int>(0);

  /// Links the savings hint (follower) to the place button (target).
  final LayerLink barLink = LayerLink();

  /// What a blocked tap scrolls to.
  final GlobalKey destinationAnchor = GlobalKey(
    debugLabel: 'checkout.destination',
  );
  final GlobalKey timingAnchor = GlobalKey(debugLabel: 'checkout.timing');

  int _blockedSerial = 0;

  void signalBlocked(CheckoutBlockReason reason) =>
      blocked.value = (reason, ++_blockedSerial);

  void requestItems() => itemsRequests.value++;

  void bumpPayment() => paymentBumps.value++;

  void dispose() {
    hintDismissed.dispose();
    blocked.dispose();
    itemsRequests.dispose();
    paymentBumps.dispose();
  }
}
