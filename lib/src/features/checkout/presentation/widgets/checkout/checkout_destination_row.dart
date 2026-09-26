import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/widgets/jameia_list_card.dart';
import '../../../../../core/widgets/jameia_list_row.dart';
import 'checkout_destination_trailing.dart';

/// The one-row card of a destination section (delivery address or pickup
/// branch): what is chosen, or the prompt to choose, with a loader / "Change"
/// / chevron at the end. The row ignores taps while the server selects it.
class CheckoutDestinationRow extends StatelessWidget {
  const CheckoutDestinationRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.chosen,
    required this.selecting,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  /// A destination is picked: the end reads "Change" instead of a chevron.
  final bool chosen;

  /// The server is selecting it: a loader at the end, taps ignored.
  final bool selecting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return JameiaListCard(
      children: [
        JameiaListRow(
          icon: icon,
          title: title,
          subtitle: subtitle,
          subtitleMaxLines: 2,
          showChevron: false,
          trailing: CheckoutDestinationTrailing(
            selecting: selecting,
            chosen: chosen,
            changeLabel: 'checkout.address_change'.tr(),
          ),
          onTap: selecting ? null : onTap,
        ),
      ],
    );
  }
}
