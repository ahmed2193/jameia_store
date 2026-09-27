import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/theme/app_spacing.dart';
import '../../../../core/domain/entities/catalog_product_entity.dart';
import '../../../../core/motion/fly_to_cart.dart';
import '../../../../core/motion/haptics.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/catalog_product_card.dart';
import '../../../../core/widgets/hero_card_image.dart';
import '../../../auth/presentation/cubit/auth_session_cubit.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../cart/presentation/cubit/cart_state.dart';
import 'home_add_burst.dart';
import 'home_confetti.dart';
import 'home_pressable.dart';
import 'home_quick_look_sheet.dart';

/// One product of a home rail wired to the app-global cart: only THIS tile
/// rebuilds when its quantity changes (a [BlocSelector] on its own count), and
/// it is repaint-isolated from its neighbours. It answers the finger: the
/// card sinks a touch when pressed, and an add sends the picture flying to
/// the basket while a +1 rises from the add button ([HomeAddBurst]) — and
/// the very first thing into an empty basket gets a burst of confetti
/// ([HomeConfetti]). A long press opens a quick look ([HomeQuickLookSheet]).
class HomeProductTile extends StatefulWidget {
  const HomeProductTile({
    super.key,
    required this.product,
    required this.width,
    required this.onOpen,
    this.alignsTagLine = false,
  });

  final CatalogProductEntity product;
  final double width;
  final ValueChanged<CatalogProductEntity> onOpen;

  /// The tile sits in a grid row: keep the card's tag line even without a
  /// tag so the names of the row line up. A one-row strip leaves it off.
  final bool alignsTagLine;

  @override
  State<HomeProductTile> createState() => _HomeProductTileState();
}

class _HomeProductTileState extends State<HomeProductTile> {
  /// Ticks once per add tap on this card.
  final ValueNotifier<int> _adds = ValueNotifier<int>(0);

  @override
  void dispose() {
    _adds.dispose();
    super.dispose();
  }

  void _quickLook() {
    Haptics.tap();
    HomeQuickLookSheet.show(
      context,
      product: widget.product,
      onOpen: () => widget.onOpen(widget.product),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final isPro = context.select<AuthSessionCubit, bool>(
      (session) => session.state.customer?.isPro ?? false,
    );
    return RepaintBoundary(
      child: BlocSelector<CartCubit, CartState, int>(
        selector: (cart) => cart.qtyOfProduct(product.id),
        builder: (context, qty) => Semantics(
          onLongPress: _quickLook,
          onLongPressHint: 'home.quick_look'.tr(),
          child: GestureDetector(
            onLongPress: _quickLook,
            excludeFromSemantics: true,
            child: HomeAddBurst(
              trigger: _adds,
              width: widget.width,
              child: HomePressable(
                child: CatalogProductCard(
                  product: product,
                  qty: qty,
                  pro: isPro,
                  width: widget.width,
                  reservesTagLine: widget.alignsTagLine,
                  onTap: () => widget.onOpen(product),
                  onAdd: () {
                    final cart = context.read<CartCubit>();
                    if (cart.state.isEmpty) {
                      // The first thing into the basket: a little party.
                      Haptics.success();
                      HomeConfetti.burstFrom(context);
                    } else {
                      HapticFeedback.selectionClick();
                    }
                    FlyToCart.flyFrom(
                      context,
                      thumbnail: HeroCardImage(
                        url: product.image,
                        width: AppSize.s56,
                        height: AppSize.s56,
                        radius: AppRadius.r4,
                      ),
                    );
                    _adds.value++;
                    cart.addCatalogProduct(product);
                  },
                  onRemove: () {
                    HapticFeedback.lightImpact();
                    context.read<CartCubit>().removeProduct(product.id);
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
