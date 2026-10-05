import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/responsive/content_clamp.dart';
import '../../../../../core/widgets/hero_map.dart';
import '../../../../../core/widgets/size_reporter.dart';
import 'address_locate_button.dart';
import 'address_map_footer.dart';
import 'address_map_layer.dart';
import 'address_map_top_bar.dart';
import 'picker_pin_overlay.dart';

/// The map picker, Google-Maps style: a full-bleed map that moves under a
/// fixed pin, back and search floating at the top, "show my location" over
/// the foot, the hint and Confirm at the foot.
///
/// The map keeps the same room at the top and the bottom — the taller of
/// the top chrome and the foot — so the pin, the map's middle and the
/// middle of a snapshot of the map are one point, and the Google logo stays
/// in sight above the foot.
class AddressMapStage extends StatefulWidget {
  const AddressMapStage({
    super.key,
    required this.onMapCreated,
    required this.onBack,
    required this.onSearch,
    required this.onConfirm,
    required this.panelUp,
  });

  final ValueChanged<GoogleMapController> onMapCreated;
  final VoidCallback onBack;
  final VoidCallback onSearch;
  final VoidCallback onConfirm;

  /// The building-type panel is up over the map.
  final ValueListenable<bool> panelUp;

  @override
  State<AddressMapStage> createState() => _AddressMapStageState();
}

class _AddressMapStageState extends State<AddressMapStage> {
  static const double _chromeGap = AppSpacing.s8;
  static const double _buttonGap = AppSpacing.s12;

  double _foot = 0;

  void _footSized(Size size) {
    if (size.height != _foot) setState(() => _foot = size.height);
  }

  @override
  Widget build(BuildContext context) {
    // The view padding: the keyboard never changes it (a change re-pads
    // the native map).
    final top = MediaQuery.viewPaddingOf(context).top;
    final topChrome = top + _chromeGap + AddressMapTopBar.height + _chromeGap;
    final edge = math.max(topChrome, _foot);
    return Stack(
      fit: StackFit.expand,
      children: [
        AddressMapLayer(
          padding: EdgeInsets.symmetric(vertical: edge),
          onMapCreated: widget.onMapCreated,
        ),
        Positioned(
          top: edge,
          bottom: edge,
          left: 0,
          right: 0,
          child: const PickerPinOverlay(),
        ),
        PositionedDirectional(
          top: top + _chromeGap,
          start: AppSpacing.gutter,
          end: AppSpacing.gutter,
          child: AddressMapTopBar(
            onBack: widget.onBack,
            onSearch: widget.onSearch,
            searchHidden: widget.panelUp,
          ),
        ),
        // On the right in both directions, as in Google Maps: the map draws
        // the Google logo bottom-left whatever the language, and it must
        // stay in sight.
        Positioned(
          right: AppSpacing.gutter,
          bottom: _foot + _buttonGap,
          child: const AddressLocateButton(),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SizeReporter(
            onSize: _footSized,
            // A readable foot on a tablet, centred over the map.
            child: ContentClamp(
              alignment: Alignment.bottomCenter,
              child: AddressMapFooter(
                onConfirm: widget.onConfirm,
                onChooseArea: widget.onSearch,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
