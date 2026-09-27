import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/widgets/hero_surface_card.dart';
import 'cart_section.dart';
import 'cart_totals_summary.dart';

/// "Payment summary": the server's breakdown on a hairline card, which eases
/// to its new height when a discount or surcharge row comes or goes.
class CartSummarySection extends StatelessWidget {
  const CartSummarySection({super.key});

  @override
  Widget build(BuildContext context) {
    return CartSection(
      title: 'cart.section_summary'.tr(),
      card: const HeroSurfaceCard(child: CartTotalsSummary()),
    );
  }
}
