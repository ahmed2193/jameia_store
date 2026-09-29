import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_shadows.dart';
import '../../../../../core/design/hero_assets.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/motion/float_loop.dart';
import '../../../../../core/motion/pop_switcher.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../domain/entities/order_journey.dart';

/// What the stage disc shows.
enum _Art {
  received,
  packing,
  packed,
  onTheWay,
  readyForPickup,
  delivered,
  attention,
  stopped,
}

/// The picture of where the order is, top-end of the status panel: a white
/// disc with the stage's glyph (the order, the basket, the packed receipt,
/// the scooter), the success art once delivered, a warning or a cross when
/// it stopped. A new stage pops in; while a stage is in progress the disc
/// floats over a soft breathing glow — both ambient loops, so they play a
/// few seconds per visit and never under reduced motion. Decorative: the
/// headline next to it says the same in words.
class TrackingStageArt extends StatelessWidget {
  const TrackingStageArt({super.key, required this.journey});

  final OrderJourney journey;

  static const double _disc = AppSize.s64;
  static const double _glyph = AppSize.s32;
  static const double _successArt = AppSize.s44;

  /// The glow reaches a little past the disc.
  static const double _glow = AppSize.s88;

  static _Art _artOf(OrderJourney journey) => switch (journey.tone) {
    OrderJourneyTone.stopped => _Art.stopped,
    OrderJourneyTone.attention => _Art.attention,
    OrderJourneyTone.done => _Art.delivered,
    OrderJourneyTone.active => switch (journey.stage) {
      OrderStage.received || null => _Art.received,
      OrderStage.packing when journey.stageComplete => _Art.packed,
      OrderStage.packing => _Art.packing,
      OrderStage.onTheWay when journey.pickup => _Art.readyForPickup,
      OrderStage.onTheWay => _Art.onTheWay,
      OrderStage.delivered => _Art.delivered,
    },
  };

  static IconData _glyphOf(_Art art) => switch (art) {
    _Art.received => HeroIcons.orders,
    _Art.packing => HeroIcons.cart,
    _Art.packed || _Art.readyForPickup => HeroIcons.confirmReceipt,
    _Art.onTheWay => HeroIcons.delivery,
    _Art.attention => HeroIcons.alert,
    _Art.stopped || _Art.delivered => HeroIcons.close,
  };

  @override
  Widget build(BuildContext context) {
    final art = _artOf(journey);
    final (Color fill, Color ink) = switch (art) {
      _Art.stopped => (AppColors.errorBg, AppColors.errorDeep),
      _Art.attention => (AppColors.warnBg, AppColors.warn),
      _ => (AppColors.white, AppColors.primary),
    };
    final disc = SizedBox.square(
      dimension: _disc,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: fill,
          shape: BoxShape.circle,
          boxShadow: AppShadows.low,
        ),
        child: Center(
          child: art == _Art.delivered
              ? SvgPicture.asset(
                  HeroAssets.stateSuccess,
                  width: _successArt,
                  height: _successArt,
                )
              : Icon(_glyphOf(art), size: _glyph, color: ink),
        ),
      ),
    );
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: _glow,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (journey.inProgress)
              const FloatLoop.glow(
                color: AppColors.brandLightBg,
                diameter: _glow,
              ),
            PopSwitcher(
              stateKey: art,
              child: journey.inProgress ? FloatLoop(child: disc) : disc,
            ),
          ],
        ),
      ),
    );
  }
}
