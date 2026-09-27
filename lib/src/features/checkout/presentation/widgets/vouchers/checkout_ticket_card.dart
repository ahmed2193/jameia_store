import 'package:flutter/widgets.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import 'checkout_ticket_border.dart';
import 'checkout_ticket_ribbon.dart';

/// The white ticket every card of the "Coupons & offers" page sits on: the
/// notched [CheckoutTicketBorder] (no shadow, no clip), 16 dp of padding
/// (24 dp on top, clear of the ribbon), an optional [ribbon] in the top-end
/// corner, and 12 dp below it to the next card.
class CheckoutTicketCard extends StatelessWidget {
  const CheckoutTicketCard({super.key, required this.child, this.ribbon});

  final Widget child;

  /// The ribbon's text; no ribbon when null.
  final String? ribbon;

  static const ShapeDecoration _decoration = ShapeDecoration(
    color: AppColors.white,
    shape: CheckoutTicketBorder(),
  );

  @override
  Widget build(BuildContext context) {
    final label = ribbon;
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.s12),
      child: Stack(
        children: [
          DecoratedBox(
            decoration: _decoration,
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.s16,
                AppSpacing.s24,
                AppSpacing.s16,
                AppSpacing.s16,
              ),
              child: child,
            ),
          ),
          if (label != null)
            PositionedDirectional(
              top: 0,
              end: 0,
              child: CheckoutTicketRibbon(label: label),
            ),
        ],
      ),
    );
  }
}
