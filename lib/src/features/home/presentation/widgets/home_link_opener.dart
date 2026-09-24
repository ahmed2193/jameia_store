import 'dart:developer';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/route_args/category_args.dart';
import '../../../../config/routes/route_args/product_listing_args.dart';
import '../../../../config/routes/routes.dart';
import '../../domain/entities/home_link.dart';

/// Opens a backend-configured [HomeLink] (promo card, promo strip, banner,
/// marketing popup) through the router. [title] names the page it opens.
abstract final class HomeLinkOpener {
  static void open(BuildContext context, HomeLink link, {String title = ''}) {
    if (!link.isNavigable) return;
    switch (link.type) {
      case HomeLinkType.collection:
        context.push(
          Routes.productListing,
          extra: ProductListingArgs.collection(slug: link.target, title: title),
        );
      case HomeLinkType.brand:
        context.push(
          Routes.productListing,
          extra: ProductListingArgs.brand(slug: link.target, title: title),
        );
      case HomeLinkType.category:
        context.push(
          Routes.category,
          extra: CategoryArgs(slug: link.target, name: title),
        );
      case HomeLinkType.recipes:
        context.push(Routes.recipes);
      case HomeLinkType.url:
        // The app ships no URL launcher yet: an external link is inert.
        log('external link not opened: ${link.target}', name: 'home');
      case HomeLinkType.none:
        break;
    }
  }
}
