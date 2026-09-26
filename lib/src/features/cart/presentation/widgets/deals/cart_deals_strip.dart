import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/change_bump.dart';
import '../../../../../core/motion/collapse_reveal.dart';
import '../../../../../core/motion/fade_through_switcher.dart';
import '../../../../../core/motion/haptics.dart';
import '../../../../../core/widgets/sticker_button.dart';
import '../../../domain/entities/cart_offers_view.dart';
import '../../cubit/cart_cubit.dart';
import '../../cubit/cart_state.dart';
import 'cart_deal_texts.dart';
import 'cart_deal_track.dart';
import 'cart_deals_sheet.dart';

/// The green strip over the checkout bar while the store runs cart offers:
/// the next one to unlock ("Add KD 2.750 more to get free delivery") or,
/// once every offer is in, "Congrats! You've got the best deal! 🎉" (with a
/// bump and a success haptic), the track towards it, and "Add item", which
/// opens the "Buy more, save more" sheet. Selects the cart's offers only.
class CartDealsStrip extends StatelessWidget {
  const CartDealsStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<CartCubit, CartState, CartOffersView>(
      selector: (cart) => CartOffersView.of(cart.cart),
      builder: (context, view) {
        final headline = CartDealTexts.headline(view);
        final done = view.allEarned;
        return CollapseReveal(
          visible: !view.isEmpty,
          child: view.isEmpty
              ? const SizedBox.shrink()
              : ColoredBox(
                  color: AppColors.brandLightBg,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      AppSpacing.gutter,
                      AppSpacing.s10,
                      AppSpacing.gutter,
                      AppSpacing.s12,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ChangeBump(
                                value: done,
                                haptic: done ? HapticKind.success : null,
                                alignment: AlignmentDirectional.centerStart,
                                child: FadeThroughSwitcher(
                                  stateKey: headline,
                                  alignment: AlignmentDirectional.centerStart,
                                  child: Text(
                                    headline,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.label.copyWith(
                                      color: AppColors.black,
                                      fontWeight: AppTextStyles.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.s8),
                              CartDealTrack(
                                fraction: view.next?.fraction ?? 1,
                                startReached: view.hasEarned,
                                endReached: done,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s12),
                        StickerButton.compact(
                          label: 'cart.add_item'.tr(),
                          onPressed: () => CartDealsSheet.show(context),
                        ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }
}
