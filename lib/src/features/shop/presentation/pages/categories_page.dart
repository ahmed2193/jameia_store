import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/domain/entities/catalog_product_query.dart';
import '../../../language/presentation/cubit/localization_cubit.dart';
import '../../../language/presentation/cubit/localization_state.dart';
import '../cubit/category_browse_cubit.dart';
import '../cubit/category_browse_state.dart';
import '../cubit/product_listing_cubit.dart';
import '../widgets/browse/categories_body.dart';
import '../widgets/browse/category_tab_bar.dart';
import '../widgets/listing/catalog_app_bar.dart';
import '../widgets/listing/catalog_cart_bar.dart';

/// The store (`GET /v1/categories` + `GET /v1/products`): the top-level
/// categories as tabs, the sub-categories of the open tab as a rail, their own
/// children as chips, and the products of whatever is picked. Opening the page
/// picks the first category, so products are there without a tap.
///
/// Catalogue text is resolved by the backend for the request language, so a
/// language switch reloads both reads.
class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  /// `CategoryBrowseCubit`'s "no base category — browse the whole store".
  static const String _wholeStore = '';

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
          create: (_) => sl<CategoryBrowseCubit>(param1: _wholeStore)..load(),
        ),
        // Deliberately not loaded here: the first category the tree offers
        // scopes the list, so the products are fetched once — for that
        // category — instead of once for the whole store and again right after.
        BlocProvider<ProductListingCubit>(
          create: (_) =>
              sl<ProductListingCubit>(param1: const CatalogProductQuery()),
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
            appBar: CatalogAppBar(
              title: 'shop.all_categories'.tr(),
              bottom: const CategoryTabBar(),
            ),
            body: CategoriesBody(onRefresh: () => _refresh(context)),
            bottomNavigationBar: const CatalogCartBar(),
          ),
        ),
      ),
    );
  }
}
