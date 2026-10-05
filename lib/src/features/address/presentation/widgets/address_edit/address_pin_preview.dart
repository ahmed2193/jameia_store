import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/motion/press_scale.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../domain/entities/building_type.dart';
import '../../cubit/address_edit_cubit.dart';
import '../../cubit/address_edit_state.dart';
import 'adjust_pin_chip.dart';
import 'building_type_labels.dart';
import 'map_band_image.dart';
import 'picker_pin_mark.dart';
import 'pin_preview_ground_painter.dart';
import 'section_header.dart';

/// "Mark your entrance": the map around the confirmed pin — the map's own
/// snapshot, so the pin sits on the very spot it marks ([MapBandImage]),
/// the pin showing the kind of place — and "Adjust pin", which goes back to
/// the map. Until there is a snapshot
/// (an address being edited whose pin was not moved) it shows a drawn
/// street plan, and the picture fades in over it.
class AddressPinPreview extends StatelessWidget {
  const AddressPinPreview({
    super.key,
    required this.snapshot,
    required this.onAdjust,
  });

  /// The map as last confirmed (PNG bytes, the map's middle = the pin).
  final ValueListenable<Uint8List?> snapshot;
  final VoidCallback onAdjust;

  static const double height = AppSize.s160;

  @override
  Widget build(BuildContext context) {
    final adjust = 'addr.details.adjust_pin'.tr();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'addr.details.pin_title'.tr(),
          hint: 'addr.details.pin_hint'.tr(),
        ),
        Semantics(
          button: true,
          label: adjust,
          excludeSemantics: true,
          onTap: onAdjust,
          child: PressScale(
            onTap: onAdjust,
            pressedScale: AppMotion.pressedScaleSmall,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.card),
              child: SizedBox(
                height: height,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const CustomPaint(painter: PinPreviewGroundPainter()),
                    MapBandImage(snapshot: snapshot),
                    Center(
                      child:
                          BlocSelector<
                            AddressEditCubit,
                            AddressEditState,
                            BuildingType
                          >(
                            selector: (state) => state.draft.buildingType,
                            builder: (context, type) =>
                                PickerPinMark(glyph: buildingTypeIcon(type)),
                          ),
                    ),
                    Align(
                      alignment: AlignmentDirectional.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsetsDirectional.only(
                          bottom: AppSpacing.s12,
                        ),
                        child: AdjustPinChip(label: adjust),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
