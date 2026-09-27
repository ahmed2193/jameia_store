import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/theme/app_spacing.dart';
import '../../../../core/domain/entities/offer_entity.dart';
import '../../../../core/motion/motion.dart';
import '../cubit/product_detail_cubit.dart';
import '../cubit/product_detail_state.dart';
import 'pdp_promo_tag.dart';

/// The cart offer that counts this product ("2 KWD off dairy (3 items)", as
/// the backend words it) under the product's text, as the red deal tag. The
/// offer is read after the product, so the sheet eases open for it and the
/// tag pops in. Only this note follows the offer, never the page; nothing
/// without one.
class PdpOfferNote extends StatelessWidget {
  const PdpOfferNote({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: MotionGuard.duration(context, AppMotion.medium),
      curve: AppMotion.signature,
      alignment: AlignmentDirectional.topStart,
      child: BlocSelector<ProductDetailCubit, ProductDetailState, OfferEntity?>(
        selector: (state) => state.promo,
        builder: (context, promo) => promo == null
            ? const SizedBox.shrink()
            : Padding(
                padding: const EdgeInsetsDirectional.only(top: AppSpacing.s12),
                child: PdpPromoTag(label: promo.name),
              ),
      ),
    );
  }
}
