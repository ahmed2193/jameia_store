import 'package:flutter/material.dart';

import '../../../../config/theme/app_spacing.dart';
import '../../../../core/responsive/app_size.dart';
import 'home_popup_close_ring.dart';
import 'home_welcome_gift_art.dart';

/// The first-order free-delivery welcome gift: the animated gift card (its
/// "Order now" baked in — the whole card is the button) centred over the
/// scrim, the round close ring under it. On a short screen (landscape) the
/// card shrinks to fit; the ring keeps its size.
class HomeWelcomePopupView extends StatelessWidget {
  const HomeWelcomePopupView({
    super.key,
    required this.onOrderNow,
    required this.onClose,
  });

  final VoidCallback onOrderNow;
  final VoidCallback onClose;

  static const double _maxWidth = AppSize.s320;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Material(
          type: MaterialType.transparency,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s32,
              vertical: AppSpacing.s16,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _maxWidth),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(child: HomeWelcomeGiftArt(onTap: onOrderNow)),
                  const SizedBox(height: AppSpacing.s12),
                  HomePopupCloseRing(onTap: onClose),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
