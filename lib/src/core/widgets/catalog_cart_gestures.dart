import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../config/theme/app_spacing.dart';
import '../motion/fly_to_cart.dart';
import '../motion/haptics.dart';
import 'hero_card_image.dart';

/// The ONE add-to-cart gesture of every product surface (docs/motion §9.4 #2,
/// D16; CC-19): card "+", stepper "+", quick look, product page, recipe
/// ingredient, assistant product, cart deals, checkout rail, reorder
/// ([added]).
///
/// [add]: one haptic at the tap (`Haptics.cartAdd`, the first add of a
/// session on Home a success), then the product's thumbnail flies to the
/// cart on screen (`FlyToCart`, at most 3 in the air, none under reduced
/// motion or with no cart on screen), then [commit] changes the cart — the
/// card's own "Add" pops into a stepper in place and the cart badge bumps
/// when the thumbnail lands. [remove]: one light tap, then [commit].
///
/// A core widget may not read the cart feature's cubit, so the caller hands
/// the cart call in as [commit] (`() => cart.addCatalogProduct(product)`).
abstract final class CatalogCartGestures {
  /// The side of the flying thumbnail.
  static const double thumbSize = FlyToCart.defaultThumbSize;

  /// Adds with the full sequence. The flight leaves from [from] when its box
  /// is on screen, else from [context]'s own box; [thumbnail] replaces the
  /// default rounded 56 dp photo of [image] (e.g. a card-sized image that is
  /// already in the memory cache). Returns whether a thumbnail took off.
  static bool add(
    BuildContext context, {
    required String image,
    required VoidCallback commit,
    bool first = false,
    GlobalKey? from,
    Widget? thumbnail,
  }) {
    Haptics.cartAdd(first: first);
    final flying =
        thumbnail ??
        HeroCardImage(
          url: image,
          width: thumbSize,
          height: thumbSize,
          radius: AppRadius.r4,
        );
    final source = from;
    final flew = source != null && _isOnScreen(source)
        ? FlyToCart.fly(context, sourceKey: source, thumbnail: flying)
        : FlyToCart.flyFrom(context, thumbnail: flying);
    commit();
    return flew;
  }

  /// The same sequence for a request that has ALREADY added (a reorder puts
  /// every paid line back in one call, so its "commit" is the awaited
  /// request): the add's haptic and the flight of [image] from [context]'s
  /// box to the cart on screen. Completes once the thumbnail lands (or is
  /// dropped), at once when nothing flew — so a follow-up (opening the cart)
  /// never covers the flight.
  static Future<void> added(
    BuildContext context, {
    required String image,
    Widget? thumbnail,
  }) {
    final flew = add(
      context,
      image: image,
      thumbnail: thumbnail,
      commit: _alreadyCommitted,
    );
    if (!flew) return Future<void>.value();
    final landed = Completer<void>();
    void onLanding() {
      FlyToCart.landings.removeListener(onLanding);
      if (!landed.isCompleted) landed.complete();
    }

    FlyToCart.landings.addListener(onLanding);
    return landed.future;
  }

  static void _alreadyCommitted() {}

  /// One less of a product (a stepper "−" / bin).
  static void remove({required VoidCallback commit}) {
    Haptics.cartRemove();
    commit();
  }

  /// Whether some of [key]'s box still shows below the top of the screen.
  static bool _isOnScreen(GlobalKey key) {
    final box = key.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return false;
    return box.localToGlobal(box.size.bottomLeft(Offset.zero)).dy > 0;
  }
}
