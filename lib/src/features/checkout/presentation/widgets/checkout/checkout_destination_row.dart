import 'package:flutter/material.dart';

import '../../../../../core/widgets/jameia_list_row.dart';
import 'checkout_destination_trailing.dart';

/// The flat Keeta row of a destination (delivery address or pickup branch):
/// a 20 dp icon, what is chosen or the prompt to choose, and a loader /
/// chevron at the end, over a hairline that runs from the text to the end
/// edge. The row ignores taps while the server selects it.
class CheckoutDestinationRow extends StatelessWidget {
  const CheckoutDestinationRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.selecting,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  /// The server is selecting it: a loader at the end, taps ignored.
  final bool selecting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return JameiaListRow(
      dense: true,
      divider: true,
      icon: icon,
      title: title,
      subtitle: subtitle,
      subtitleMaxLines: 2,
      showChevron: false,
      trailing: CheckoutDestinationTrailing(selecting: selecting),
      onTap: selecting ? null : onTap,
    );
  }
}
