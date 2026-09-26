import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../config/routes/route_args/product_listing_args.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../language/presentation/cubit/localization_cubit.dart';
import '../../../language/presentation/cubit/localization_state.dart';
import '../cubit/listing_tabs_cubit.dart';
import '../cubit/listing_tabs_state.dart';
import '../cubit/product_listing_cubit.dart';
import '../widgets/listing/catalog_app_bar.dart';
import '../widgets/listing/catalog_cart_bar.dart';
import '../widgets/listing/listing_collection_scaffold.dart';
import '../widgets/listing/product_listing_body.dart';

/// Any product list of the backend (`GET /v1/products`): a brand, a
/// collection ("view all" of a home rail), a tag, the offers, search results.
/// A collection or a brand opens as a collection page (hero + category tabs,
/// [ListingCollectionScaffold]); search and tag lists keep the plain app bar
/// with the sort / filter toolbar. A language switch reloads the list and
/// the tabs (catalogue text arrives resolved for the request language).
class ProductListingPage extends StatelessWidget {
  const ProductListingPage({super.key, required this.args});

  final ProductListingArgs args;

  @override
  Widget build(BuildContext context) {
    final isCollection = args.isCollectionLook;
    return MultiBlocProvider(
      providers: [
        BlocProvider<ProductListingCubit>(
          create: (_) => sl<ProductListingCubit>(param1: args.query)..load(),
        ),
        if (isCollection)
          BlocProvider<ListingTabsCubit>(
            create: (_) => sl<ListingTabsCubit>(param1: args.query)..load(),
          ),
      ],
      child: Builder(
        builder: (context) => MultiBlocListener(
          listeners: [
            BlocListener<LocalizationCubit, LocalizationState>(
              listenWhen: (previous, current) =>
                  previous.locale != current.locale,
              listener: (context, _) {
                context.read<ProductListingCubit>().load();
                if (isCollection) context.read<ListingTabsCubit>().load();
              },
            ),
            // New tabs without the open one (a reload after a language
            // switch dropped it, or hid the tabs): back to "All", so the grid
            // never shows a scope that no tab names.
            if (isCollection)
              BlocListener<ListingTabsCubit, ListingTabsState>(
                listenWhen: (previous, current) =>
                    previous.categories != current.categories,
                listener: (context, tabs) {
                  final listing = context.read<ProductListingCubit>();
                  if (!tabs.hasTabFor(listing.state.query.categorySlug)) {
                    listing.setCategorySlug(null);
                  }
                },
              ),
          ],
          child: isCollection
              ? ListingCollectionScaffold(args: args)
              : Scaffold(
                  backgroundColor: AppColors.white,
                  appBar: CatalogAppBar(title: args.title),
                  body: const ProductListingBody(),
                  bottomNavigationBar: const CatalogCartBar(),
                ),
        ),
      ),
    );
  }
}
