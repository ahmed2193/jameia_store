import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../core/responsive/app_size.dart';
import 'home_first_order_art.dart';
import 'home_first_order_details.dart';

/// The details behind the first-order bar, in the confirmation dialog's card
/// (docs/design_system.md §5): the riding Hero on the bar's green with the ✕
/// ([HomeFirstOrderArt]), then the offer and how it works
/// ([HomeFirstOrderDetails]); "Start shopping" closes it like the ✕
/// ([onClose]) — the customer is already where shopping starts.
///
/// It arrives like the other Hero dialogs: the card springs in (the route),
/// the rider drives in, the words rise in one after the other, the fee is
/// struck and "Free" pops. Reduced motion: everything in place. Scrolls on a
/// short screen.
class HomeFirstOrderDialog extends StatelessWidget {
  const HomeFirstOrderDialog({
    super.key,
    required this.deliveryFeeKd,
    required this.minOrderKd,
    required this.needsSignIn,
    required this.onClose,
  });

  final double deliveryFeeKd;
  final double minOrderKd;
  final bool needsSignIn;
  final VoidCallback onClose;

  static const double _maxWidth = AppSize.s350;

  @override
  Widget build(BuildContext context) {
    final title = 'home.first_order_title'.tr();
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s24,
          vertical: AppSpacing.s16,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxWidth),
          child: Semantics(
            scopesRoute: true,
            namesRoute: true,
            explicitChildNodes: true,
            label: title,
            child: Material(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppRadius.sheet),
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    HomeFirstOrderArt(onClose: onClose),
                    HomeFirstOrderDetails(
                      title: title,
                      deliveryFeeKd: deliveryFeeKd,
                      minOrderKd: minOrderKd,
                      needsSignIn: needsSignIn,
                      onStart: onClose,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
