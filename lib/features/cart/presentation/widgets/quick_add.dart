import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// TODO(P2.9-boundary): `quickAddToCart` is a public add-to-cart API called across
// feature boundaries (home / shop / product_details / discovery) with the core
// `Product` / `ProductVariant` DTOs, so it deliberately keeps the shared
// `core/data/models` types rather than a framework-free entity.
import '../../../../core/data/models/models.dart';
import '../../../../core/motion/fly_to_cart.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/keeta_image.dart';
import '../cubit/cart_cubit.dart';

/// KeeTa's synthetic single-supplier id for the unified Jameia basket — the
/// default shop for a quick add. Mirrors `core/data/keeta_repository.dart`'s
/// `kJameiaSupplierId`; redeclared privately here so the cart presentation no
/// longer imports the catalogue repository (and so callers that import both this
/// widget and the core constant don't hit an ambiguous-import clash).
const String _kJameiaSupplierId = 'jameia';

/// The one place a quick "add to cart" fires: a haptic tick, the fly-to-cart
/// flight from the tapped control ([context]'s render box), then the cart add.
///
/// Every quick-add "+" surface (shop rows, home rails, fixed-price cards) routes
/// through here so the marquee flight plays from ALL add paths — previously only
/// the multi-SKU sheet flew. Reduced-motion callers safely skip the flight (the
/// cart badge still pops on the quantity change).
void quickAddToCart(
  BuildContext context, {
  required Product product,
  ProductVariant? variant,
  double? unitPrice,
  int qty = 1,
  String shopId = _kJameiaSupplierId,
}) {
  HapticFeedback.selectionClick();
  final img = (variant != null && variant.image.isNotEmpty)
      ? variant.image
      : product.image;
  FlyToCart.flyFrom(
    context,
    thumbnail: KeetaCardImage(
      url: img,
      width: 56,
      height: 56,
      radius: AppRadius.r4,
    ),
  );
  context.read<CartCubit>().add(
        product,
        shopId,
        variant: variant,
        unitPrice: unitPrice,
        qty: qty,
      );
}
