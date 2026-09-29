import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/fly_to_cart.dart';
import '../../../../../core/motion/haptics.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/hero_card_image.dart';
import '../../../../../core/widgets/summary_row.dart';
import '../../../domain/entities/assistant_block.dart';
import 'assistant_card_frame.dart';
import 'assistant_cart_action_footer.dart';
import 'assistant_cart_action_line.dart';

/// `cart_action`: a cart change the assistant PROPOSES. The lines and the
/// estimate, then the footer that confirms it (nothing is in the cart until
/// then).
///
/// Confirmed here and now (docs/motion §9.6 §2.6, approval #10): the items
/// go into the cart the way every add does — up to three line thumbnails
/// fly to the app-bar cart ([FlyToCart], `staggerStep` apart), its count
/// bumps where they land, and the first landing ticks like an add
/// (`Haptics.cartAdd`; at once when nothing could fly). No confetti. A
/// spent proposal (cancelled / expired) cross-fades to the muted palette —
/// colours only, no lasting opacity layer — and never vibrates.
class AssistantCartActionCard extends StatefulWidget {
  const AssistantCartActionCard({
    super.key,
    required this.block,
    this.live = false,
  });

  final AssistantCartActionBlock block;

  /// The reply is still streaming: the proposal cannot be confirmed yet.
  final bool live;

  @override
  State<AssistantCartActionCard> createState() =>
      _AssistantCartActionCardState();
}

class _AssistantCartActionCardState extends State<AssistantCartActionCard> {
  /// The thumbnails a confirm may fly from (the first [FlyToCart.maxFlights]).
  final List<GlobalKey> _thumbs = List<GlobalKey>.generate(
    FlyToCart.maxFlights,
    (_) => GlobalKey(),
  );
  final List<Timer> _launches = <Timer>[];
  bool _waitingLanding = false;

  @override
  void didUpdateWidget(AssistantCartActionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.block.status == AssistantActionStatus.pending &&
        widget.block.status == AssistantActionStatus.confirmed) {
      // After this frame: a flight joins the root overlay (never from a
      // build) and leaves from the lines where they were laid out.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _flyToCart();
      });
    }
  }

  /// Up to three thumbnails, `staggerStep` apart; the cart haptic on the
  /// first landing.
  void _flyToCart() {
    final items = widget.block.items.take(FlyToCart.maxFlights).toList();
    final firstFlew = items.isNotEmpty && _launch(0, items.first);
    for (var index = 1; index < items.length; index++) {
      final item = items[index];
      final slot = index;
      _launches.add(
        Timer(AppMotion.staggerStep * slot, () {
          if (mounted) _launch(slot, item);
        }),
      );
    }
    if (!firstFlew) {
      Haptics.cartAdd();
      return;
    }
    _waitingLanding = true;
    FlyToCart.landings.addListener(_onLanding);
  }

  bool _launch(int index, AssistantCartActionItem item) => FlyToCart.fly(
    context,
    sourceKey: _thumbs[index],
    thumbnail: HeroCardImage(
      url: item.product?.image ?? '',
      width: FlyToCart.defaultThumbSize,
      height: FlyToCart.defaultThumbSize,
      radius: AppRadius.r4,
    ),
  );

  void _onLanding() {
    if (!_waitingLanding) return;
    _waitingLanding = false;
    FlyToCart.landings.removeListener(_onLanding);
    Haptics.cartAdd();
  }

  @override
  void dispose() {
    FlyToCart.landings.removeListener(_onLanding);
    for (final launch in _launches) {
      launch.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final block = widget.block;
    final estimate = block.estimatedTotalKd;
    final spent =
        block.status == AssistantActionStatus.cancelled ||
        block.status == AssistantActionStatus.expired;
    return AssistantCardFrame(
      title: 'assistant.action_title'.tr(),
      icon: Icons.add_shopping_cart_rounded,
      muted: spent,
      borderColor: block.status == AssistantActionStatus.confirmed
          ? AppColors.success
          : AppColors.divider,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, item) in block.items.indexed)
            AssistantCartActionLine(
              item: item,
              muted: spent,
              thumbKey: index < _thumbs.length ? _thumbs[index] : null,
            ),
          if (estimate != null)
            SummaryRow(
              label: 'assistant.estimated_total'.tr(),
              value: Formatters.price(estimate),
              emphasized: true,
              valueColor: spent ? AppColors.secondaryText : null,
            ),
          const SizedBox(height: AppSpacing.s8),
          AssistantCartActionFooter(block: block, live: widget.live),
        ],
      ),
    );
  }
}
