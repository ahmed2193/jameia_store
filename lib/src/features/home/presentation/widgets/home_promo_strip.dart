import 'package:flutter/material.dart';

import '../../../../config/theme/app_spacing.dart';
import '../../domain/entities/home_section_entity.dart';
import 'home_promo_strip_card.dart';

/// A stand-alone call-out block of the feed: the strip card, inset from the
/// page edges. When the backend links the strip to a rail, the same card
/// becomes the head of a themed block instead.
class HomePromoStrip extends StatelessWidget {
  const HomePromoStrip({super.key, required this.section, required this.onTap});

  final HomePromoStripSection section;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.pageMargin,
        0,
        AppSpacing.pageMargin,
        AppSpacing.s8,
      ),
      child: HomePromoStripCard(section: section, onTap: onTap),
    );
  }
}
