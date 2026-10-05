import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../cubit/address_picker_cubit.dart';
import '../../cubit/address_picker_state.dart';
import 'picker_pin.dart';
import 'picker_pin_mark.dart';
import 'picker_pin_tooltip.dart';
import 'pinned_place_text.dart';

/// The pin, its shadow on the ground and its bubble, laid out around the
/// middle of the space it is given — the map's middle once its padding is
/// taken off — so the pin's tip is exactly on the point the picker reads.
/// Rebuilds only when the pin's state or the place under it changes; takes
/// no touch (the map under it does). A screen reader hears the place as it
/// changes.
class PickerPinOverlay extends StatelessWidget {
  const PickerPinOverlay({super.key});

  static const double _tooltipGap = AppSpacing.s6;

  static bool _changed(AddressPickerState previous, AddressPickerState next) =>
      previous.pin != next.pin ||
      previous.place != next.place ||
      previous.opened != next.opened;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: BlocBuilder<AddressPickerCubit, AddressPickerState>(
        buildWhen: _changed,
        builder: (context, state) {
          final lifted = state.pin == PinStatus.moving;
          final outside = state.pin == PinStatus.outside;
          final place = state.place;
          // No map yet: it waits to open on the customer.
          final finding = !state.opened;
          final text = finding
              ? 'addr.map.finding_you'.tr()
              : outside
              ? 'addr.map.outside_tooltip'.tr()
              : place == null
              ? ''
              : pinTitle(
                  place,
                  rtl: Directionality.of(context) == TextDirection.rtl,
                );
          return Center(
            child: SizedBox.shrink(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  PickerPinMark(
                    lifted: lifted,
                    outside: outside,
                    // Finding the customer, or reading the address there.
                    reading:
                        !lifted &&
                        (finding || state.pin == PinStatus.resolving),
                  ),
                  Positioned(
                    left: -PickerPinTooltip.maxWidth / 2,
                    width: PickerPinTooltip.maxWidth,
                    bottom: PickerPin.tip + _tooltipGap,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Semantics(
                        liveRegion: true,
                        label: text.isEmpty
                            ? 'addr.map.reading'.tr()
                            : 'addr.map.pin_at'.tr(namedArgs: {'place': text}),
                        excludeSemantics: true,
                        child: PickerPinTooltip(text: text, visible: !lifted),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
