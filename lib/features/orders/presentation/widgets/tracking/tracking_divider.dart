import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

// ── Real KeeTa divider (d41d38) ───────────────────────────────────────────────
//
// bundle.css.json d41d38: height=0.5dp, bg=#00000014 (= overlayDivider 8% black).
// Used inside section cards between rows; thinner and more subtle than ThinDivider.

class TrackingDivider extends StatelessWidget {
  const TrackingDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 0.5,
      child: DecoratedBox(
        decoration: BoxDecoration(color: AppColors.overlayDivider),
        child: SizedBox.expand(),
      ),
    );
  }
}
