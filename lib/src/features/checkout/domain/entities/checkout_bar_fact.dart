import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/catalog_product_entity.dart';
import 'checkout_block_reason.dart';

/// One line the place-order bar can show under the total.
enum CheckoutBarFactKind {
  /// Why the order cannot go (pinned, never rotates).
  blocked,

  /// No priced destination yet (pinned).
  chooseDestination,

  /// "Saving KD x" (every saving together).
  totalSavings,

  /// "KD x saved with CODE".
  couponSaved,

  /// "KD x off with points".
  pointsSaved,

  /// "Free delivery".
  freeDelivery,

  /// "Add KD x for free delivery".
  freeDeliveryGap,
}

class CheckoutBarFact extends Equatable {
  /// A fact of any kind but [CheckoutBarFactKind.blocked] (that one has
  /// [CheckoutBarFact.blocked], which cannot be built without its reason).
  const CheckoutBarFact(this.kind, {this.fils = 0, this.code = ''})
    : reason = null,
      assert(
        kind != CheckoutBarFactKind.blocked,
        'a blocked fact needs its reason: CheckoutBarFact.blocked',
      );

  /// Why the order cannot go; [fils] is the minimum-order shortfall.
  const CheckoutBarFact.blocked(
    CheckoutBlockReason this.reason, {
    this.fils = 0,
  }) : kind = CheckoutBarFactKind.blocked,
       code = '';

  final CheckoutBarFactKind kind;

  /// The amount the line names; `0` when it names none. For
  /// [CheckoutBlockReason.minOrder] it is the shortfall.
  final int fils;

  /// The coupon's code ([CheckoutBarFactKind.couponSaved]).
  final String code;

  /// Set exactly when [kind] is [CheckoutBarFactKind.blocked].
  final CheckoutBlockReason? reason;

  double get kd => fils / CatalogProductEntity.filsPerDinar;

  /// What a rotating line keys its item on: the kind (and the reason of a
  /// blocked line), not the amount — a new amount updates the line in
  /// place, a new kind is a new line.
  Object get id => kind == CheckoutBarFactKind.blocked ? (kind, reason) : kind;

  @override
  List<Object?> get props => [kind, fils, code, reason];
}
