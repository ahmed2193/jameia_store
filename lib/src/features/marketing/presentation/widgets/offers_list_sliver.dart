import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../config/theme/app_spacing.dart';
import '../../../../core/domain/entities/offer_entity.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/motion/stagger_entrance.dart';
import 'offer_tile.dart';

/// The offers as a lazily built sliver in 16dp gutters. The cards on screen
/// when the list opens cascade in once (at once under reduced motion). A card
/// built later, whether scrolled into view, scrolled back to after the list
/// dropped it, or added by a refresh, is simply there: nothing replays and
/// nothing waits blank. A refresh moves the cards that stay instead of
/// rebuilding them.
class OffersListSliver extends StatefulWidget {
  const OffersListSliver({super.key, required this.offers});

  final List<OfferEntity> offers;

  static const EdgeInsetsDirectional padding = EdgeInsetsDirectional.fromSTEB(
    AppSpacing.s16,
    AppSpacing.s8,
    AppSpacing.s16,
    AppSpacing.s24,
  );
  static const double gap = AppSpacing.s12;

  @override
  State<OffersListSliver> createState() => _OffersListSliverState();
}

class _OffersListSliverState extends State<OffersListSliver> {
  /// Cards past this one start with it, so a long list is not held back.
  static const int _staggeredCards = 6;

  /// The delay between two cards of the cascade.
  static const Duration _step = Duration(milliseconds: 30);

  /// The ids of the cards built on the list's first frame. They keep their
  /// entrance until it has played, then render like every other card.
  final Set<String> _cascading = <String>{};
  bool _opening = true;
  Timer? _cascadeEnd;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _opening = false;
      // The last card waits its steps, then plays its entrance.
      _cascadeEnd = Timer(_step * _staggeredCards + AppMotion.medium, () {
        if (mounted) setState(_cascading.clear);
      });
    });
  }

  @override
  void dispose() {
    _cascadeEnd?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final offers = widget.offers;
    return SliverPadding(
      padding: OffersListSliver.padding,
      sliver: SliverList.separated(
        itemCount: offers.length,
        findItemIndexCallback: (key) {
          final index = offers.indexWhere(
            (offer) => ValueKey<String>(offer.id) == key,
          );
          return index < 0 ? null : index;
        },
        itemBuilder: (context, index) {
          final offer = offers[index];
          final key = ValueKey<String>(offer.id);
          if (_opening) _cascading.add(offer.id);
          if (!_cascading.contains(offer.id)) {
            return OfferTile(key: key, offer: offer);
          }
          return StaggerEntrance(
            key: key,
            index: index,
            stagger: _step,
            maxIndex: _staggeredCards,
            child: OfferTile(offer: offer),
          );
        },
        separatorBuilder: (_, _) =>
            const SizedBox(height: OffersListSliver.gap),
      ),
    );
  }
}
