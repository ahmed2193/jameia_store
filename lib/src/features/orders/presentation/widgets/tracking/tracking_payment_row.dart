import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/hero_assets.dart';
import '../../../../../core/domain/entities/catalog_product_entity.dart';
import '../../../../../core/domain/entities/order_fulfillment_entities.dart';
import '../../../../../core/domain/entities/order_status.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/hero_tag.dart';

/// How the order is paid: the method's plate (cash / wallet), its name, the
/// wallet share when the wallet covered part of a cash order, and where the
/// payment stands — "Paid", "Pay on delivery" for cash still to hand
/// over, or "Not charged" once a cancelled order was never paid.
class TrackingPaymentRow extends StatelessWidget {
  const TrackingPaymentRow({
    super.key,
    required this.payment,
    this.cancelled = false,
  });

  final OrderPaymentEntity payment;

  /// The order was cancelled: nothing is due any more.
  final bool cancelled;

  /// The method takes three fifths of the row, the status tag up to two.
  static const int _methodFlex = 3;
  static const int _statusFlex = 2;

  @override
  Widget build(BuildContext context) {
    final method = switch (payment.method) {
      OrderPaymentMethod.cod => 'orders.payment_cod'.tr(),
      OrderPaymentMethod.wallet => 'orders.payment_wallet'.tr(),
      OrderPaymentMethod.other => 'orders.payment_other'.tr(),
    };
    final walletShare =
        payment.method != OrderPaymentMethod.wallet &&
            payment.walletUsedFils > 0
        ? 'orders.payment_wallet_share'.tr(
            namedArgs: {
              'amount': Formatters.isolate(
                Formatters.priceLtr(
                  payment.walletUsedFils / CatalogProductEntity.filsPerDinar,
                ),
              ),
            },
          )
        : '';
    final status = payment.isPaid
        ? 'orders.payment_paid'.tr()
        : cancelled
        ? 'orders.payment_not_charged'.tr()
        : payment.method == OrderPaymentMethod.cod
        ? 'orders.payment_due_on_delivery'.tr()
        : 'orders.payment_pending'.tr();
    return MergeSemantics(
      child: Row(
        children: [
          ExcludeSemantics(
            child: SvgPicture.asset(
              payment.method == OrderPaymentMethod.wallet
                  ? HeroAssets.checkoutWallet
                  : HeroAssets.checkoutCash,
              width: AppSize.s24,
              height: AppSize.s24,
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            flex: _methodFlex,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(method, style: AppTextStyles.itemTitle),
                if (walletShare.isNotEmpty)
                  Text(walletShare, style: AppTextStyles.meta),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          // At the row's end; may shrink (its label ellipsizes) before the
          // method does.
          Flexible(
            flex: _statusFlex,
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              heightFactor: 1,
              child: HeroTag(
                label: status,
                icon: payment.isPaid ? Icons.check_rounded : null,
                tone: payment.isPaid
                    ? HeroTagTone.brandSoft
                    : HeroTagTone.neutral,
                pill: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
