import 'package:flutter/material.dart';

import '../../domain/entities/home_section_entity.dart';
import 'home_layout.dart';
import 'home_promo_strip_card.dart';

/// A stand-alone call-out block of the feed: the strip as an edge-to-edge
/// band. When the backend links the strip to a rail, the strip becomes the
/// head of a campaign block instead.
class HomePromoStrip extends StatelessWidget {
  const HomePromoStrip({super.key, required this.section, required this.onTap});

  final HomePromoStripSection section;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: HomeLayout.blockGap),
      child: HomePromoStripCard(section: section, onTap: onTap),
    );
  }
}
