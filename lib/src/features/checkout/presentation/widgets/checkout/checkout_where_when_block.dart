import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/motion/shake_x.dart';
import '../../../../../core/motion/size_fade_switcher.dart';
import '../../../domain/entities/checkout_block_reason.dart';
import '../../cubit/checkout_cubit.dart';
import 'checkout_address_section.dart';
import 'checkout_band.dart';
import 'checkout_branch_section.dart';
import 'checkout_eta_card.dart';
import 'checkout_eta_row.dart';
import 'checkout_maintenance_banner.dart';
import 'checkout_mode_toggle.dart';
import 'checkout_ui_controller.dart';

/// Block A of the checkout — where and when, on white with no title: the
/// maintenance banner (only in maintenance), the delivery / pickup switch,
/// the destination row (address ↔ branch swap in place), the "Expected" row
/// and the ETA card.
///
/// The destination and the "Expected" row are the anchors a blocked "Place
/// order" scrolls to (`CheckoutUiController.destinationAnchor` /
/// `timingAnchor`); each shakes when the tap was blocked for its reason
/// (`destination` / `slot`). The anchor wraps the switcher, not a section,
/// so the address and the branch row never hold the same key while they
/// cross-fade.
class CheckoutWhereWhenBlock extends StatefulWidget {
  const CheckoutWhereWhenBlock({super.key});

  @override
  State<CheckoutWhereWhenBlock> createState() => _CheckoutWhereWhenBlockState();
}

class _CheckoutWhereWhenBlockState extends State<CheckoutWhereWhenBlock> {
  late final CheckoutUiController _ui = context.read<CheckoutUiController>();

  /// Blocked taps per row: a new count shakes that row once.
  int _destinationShakes = 0;
  int _slotShakes = 0;

  @override
  void initState() {
    super.initState();
    _ui.blocked.addListener(_onBlocked);
  }

  @override
  void dispose() {
    _ui.blocked.removeListener(_onBlocked);
    super.dispose();
  }

  void _onBlocked() {
    switch (_ui.blocked.value?.$1) {
      case CheckoutBlockReason.destination:
        setState(() => _destinationShakes++);
      case CheckoutBlockReason.slot:
        setState(() => _slotShakes++);
      case _:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPickup = context.select<CheckoutCubit, bool>(
      (cubit) => cubit.state.draft.isPickup,
    );
    final destination = isPickup
        ? const CheckoutBranchSection()
        : const CheckoutAddressSection();
    return CheckoutBand(
      bandAbove: false,
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.s16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CheckoutMaintenanceBanner(),
          const CheckoutModeToggle(),
          KeyedSubtree(
            key: _ui.destinationAnchor,
            child: ShakeX(
              shakeKey: _destinationShakes,
              // The address and the branch row swap in place: the height
              // eases to the new one while the old fades out. Reduced
              // motion swaps at once — and skips the switcher, whose
              // AnimatedSize trips a layout assertion at a zero duration.
              child: MotionGuard.reduced(context)
                  ? destination
                  : SizeFadeSwitcher(stateKey: isPickup, child: destination),
            ),
          ),
          KeyedSubtree(
            key: _ui.timingAnchor,
            child: ShakeX(shakeKey: _slotShakes, child: const CheckoutEtaRow()),
          ),
          const CheckoutEtaCard(),
        ],
      ),
    );
  }
}
