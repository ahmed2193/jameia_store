import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import 'jameia_map.dart';

/// Rounded map card (embedded preview, e.g. address/shop detail).
class JameiaMapCard extends StatelessWidget {
  const JameiaMapCard({
    super.key,
    required this.target,
    this.height = 160,
    this.markers = const {},
    this.radius = 12,
  });

  final LatLng target;
  final double height;
  final Set<Marker> markers;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        height: height,
        color: AppColors.smallBackground,
        child: JameiaMap(
          target: target,
          markers: markers,
          liteMode: true,
          interactive: false,
        ),
      ),
    );
  }
}
