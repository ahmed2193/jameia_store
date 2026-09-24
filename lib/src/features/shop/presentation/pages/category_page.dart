import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../config/routes/route_args/category_args.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/domain/entities/catalog_product_query.dart';
import '../../../language/presentation/cubit/localization_cubit.dart';
import '../../../language/presentation/cubit/localization_state.dart';
import '../cubit/category_browse_cubit.dart';
import '../cubit/category_browse_state.dart';
import '../cubit/product_listing_cubit.dart';
import '../widgets/browse/category_body.dart';
import '../widgets/browse/category_browse_app_bar.dart';
import '../widgets/listing/catalog_cart_bar.dart';

/// One category and everything under it: its sub-categories as a circle rail,
/// their children as chips and the products of whatever is picked
/// (`GET /v1/products?categorySlug=` — a parent includes its descendants).
///
/// Rows and grid load in parallel; catalogue text is resolved by the backend
/// for the request language, so a language switch reloads both.
class CategoryPage extends StatelessWidget {
  const CategoryPage({super.key, required this.args});

  final CategoryArgs args;

  Future<void> _refresh(BuildContext context) async {
    await Future.wait(<Future<void>>[
      context.read<CategoryBrowseCubit>().refresh(),
      context.read<ProductListingCubit>().refresh(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<CategoryBrowseCubit>(
          create: (_) => sl<CategoryBrowseCubit>(param1: args.slug)..load(),
        ),
        BlocProvider<ProductListingCubit>(
          create: (_) => sl<ProductListingCubit>(
            param1: CatalogProductQuery(categorySlug: args.slug),
          )..load(),
        ),
      ],
      child: Builder(
        builder: (context) => MultiBlocListener(
          listeners: [
            BlocListener<LocalizationCubit, LocalizationState>(
              listenWhen: (previous, current) =>
                  previous.locale != current.locale,
              listener: (context, _) {
                context.read<CategoryBrowseCubit>().load();
                context.read<ProductListingCubit>().load();
              },
            ),
            BlocListener<CategoryBrowseCubit, CategoryBrowseState>(
              listenWhen: (previous, current) =>
                  previous.browse.activeSlug != current.browse.activeSlug,
              listener: (context, state) => context
                  .read<ProductListingCubit>()
                  .setCategorySlug(state.browse.activeSlug),
            ),
          ],
          child: Scaffold(
            backgroundColor: AppColors.mediumBackground,
            appBar: CategoryBrowseAppBar(fallbackTitle: args.name),
            body: CategoryBody(onRefresh: () => _refresh(context)),
            bottomNavigationBar: const CatalogCartBar(),
          ),
        ),
      ),
    );
  }
}
