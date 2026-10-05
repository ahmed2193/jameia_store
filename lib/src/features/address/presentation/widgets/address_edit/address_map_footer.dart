import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/haptics.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/motion/shake_x.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../cubit/address_picker_cubit.dart';
import '../../cubit/address_picker_state.dart';
import 'pin_hint_card.dart';

/// The foot of the map picker, Glovo style: the hint card and a full pill
/// Confirm. While the map moves the hint steps aside (its room stays, so the
/// map's padding never jumps) and Confirm greys out; outside the delivery
/// area Confirm stays grey and a tap on it still answers: the reason shakes
/// and a warning haptic fires — the same "no" as every disabled submit
/// (docs/motion §9.4 #18) — and the card offers the areas Hero delivers to.
class AddressMapFooter extends StatefulWidget {
  const AddressMapFooter({
    super.key,
    required this.onConfirm,
    required this.onChooseArea,
  });

  final VoidCallback onConfirm;
  final VoidCallback onChooseArea;

  @override
  State<AddressMapFooter> createState() => _AddressMapFooterState();
}

class _AddressMapFooterState extends State<AddressMapFooter> {
  static const Offset _steppedAside = Offset(0, 0.2);
  static const int _shakeCycles = 3;

  /// Taps on the grey Confirm; each one shakes the reason.
  int _refusals = 0;

  void _refuse() {
    Haptics.refuse();
    setState(() => _refusals++);
  }

  static bool _changed(AddressPickerState previous, AddressPickerState next) =>
      previous.pin != next.pin ||
      previous.confirming != next.confirming ||
      previous.canConfirm != next.canConfirm;

  @override
  Widget build(BuildContext context) {
    // The view padding, which the keyboard never changes: the map's padding
    // follows this foot, and a resize re-pads the native map.
    final bottomPad = MediaQuery.viewPaddingOf(context).bottom;
    final fast = MotionGuard.duration(context, AppMotion.fast);
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        AppSpacing.gutter,
        0,
        AppSpacing.gutter,
        bottomPad + AppSpacing.s16,
      ),
      child: BlocBuilder<AddressPickerCubit, AddressPickerState>(
        buildWhen: _changed,
        builder: (context, state) {
          final moving = state.pin == PinStatus.moving;
          final outside = state.pin == PinStatus.outside;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSlide(
                offset: moving ? _steppedAside : Offset.zero,
                duration: fast,
                curve: moving ? AppMotion.exit : AppMotion.signature,
                child: AnimatedOpacity(
                  opacity: moving ? 0 : 1,
                  duration: fast,
                  child: ShakeX(
                    shakeKey: _refusals,
                    amplitude: AppSize.s8,
                    cycles: _shakeCycles,
                    child: PinHintCard(
                      outside: outside,
                      onChooseArea: widget.onChooseArea,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s12),
              GestureDetector(
                // The grey button has no tap of its own, so this wins; its
                // "disabled" state stays what a screen reader hears.
                onTap: outside ? _refuse : null,
                excludeFromSemantics: true,
                child: AppButton(
                  label: 'addr.confirm_location'.tr(),
                  enabled: state.canConfirm,
                  loading: state.confirming,
                  onPressed: widget.onConfirm,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
