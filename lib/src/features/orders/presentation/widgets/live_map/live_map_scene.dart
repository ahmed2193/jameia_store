import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../core/motion/motion.dart';
import '../../../../../core/navigation/after_route_entrance.dart';
import '../../../../../core/widgets/size_reporter.dart';
import '../../../domain/entities/courier_trip.dart';
import 'live_map_layer.dart';
import 'live_map_panel.dart';
import 'live_map_top_bar.dart';

/// The live map screen once the ride is known: the map full-bleed, the panel
/// over its foot (the top bar floats over both, from [LiveMapBody], and the
/// map keeps room for it). The panel sizes itself
/// (text size, a rider found); its height is measured and handed to the map
/// as padding, so the camera frames the ride in the part that can be seen.
///
/// The native map is created once the page has slid in (creating it mid-
/// slide drops frames of the slide), and the panel's height reaches it once
/// the panel has settled, not on every frame of the panel's own animation
/// (a padding change re-lays the native map out).
class LiveMapScene extends StatefulWidget {
  const LiveMapScene({super.key, required this.trip});

  final CourierTrip trip;

  @override
  State<LiveMapScene> createState() => _LiveMapSceneState();
}

class _LiveMapSceneState extends State<LiveMapScene> {
  double _panelHeight = 0;
  Timer? _settle;

  @override
  void dispose() {
    _settle?.cancel();
    super.dispose();
  }

  /// The first height is taken at once; a later one once it has held for
  /// [AppMotion.medium].
  void _onPanelSize(Size size) {
    _settle?.cancel();
    if (!mounted || size.height == _panelHeight) return;
    if (_panelHeight == 0) {
      setState(() => _panelHeight = size.height);
      return;
    }
    _settle = Timer(AppMotion.medium, () {
      if (mounted) setState(() => _panelHeight = size.height);
    });
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top + LiveMapTopBar.height;
    return Stack(
      children: [
        Positioned.fill(
          child: AfterRouteEntrance(
            child: LiveMapLayer(
              trip: widget.trip,
              padding: EdgeInsets.only(top: top, bottom: _panelHeight),
            ),
          ),
        ),
        PositionedDirectional(
          start: 0,
          end: 0,
          bottom: 0,
          child: SizeReporter(
            onSize: _onPanelSize,
            child: LiveMapPanel(trip: widget.trip),
          ),
        ),
      ],
    );
  }
}
