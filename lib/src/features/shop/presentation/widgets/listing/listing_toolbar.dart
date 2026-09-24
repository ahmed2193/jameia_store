import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/domain/entities/catalog_product_query.dart';
import '../../../../../core/navigation/navigation.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../cubit/product_listing_cubit.dart';
import '../../cubit/product_listing_state.dart';
import 'listing_brand_sheet.dart';
import 'listing_filter_pill.dart';
import 'listing_sort_label.dart';
import 'listing_sort_sheet.dart';

/// Sort + filters of a product listing. All of them are server-side: a change
/// restarts the list. Rebuilds only when the query or the brand list changes.
class ListingToolbar extends StatelessWidget {
  const ListingToolbar({super.key});

  Future<void> _pickSort(
    BuildContext context,
    CatalogProductSort? current,
  ) async {
    final cubit = context.read<ProductListingCubit>();
    final picked = await showJameiaBottomSheet<({CatalogProductSort? sort})>(
      context,
      backgroundColor: AppColors.white,
      builder: (_) => ListingSortSheet(selected: current),
    );
    if (picked != null) await cubit.setSort(picked.sort);
  }

  /// The brand list is read the first time the filter is opened, so a listing
  /// nobody filters never asks for it.
  Future<void> _pickBrand(BuildContext context, String? current) async {
    final cubit = context.read<ProductListingCubit>();
    await cubit.loadBrands();
    if (!context.mounted) return;
    final picked = await showJameiaBottomSheet<({String? slug})>(
      context,
      backgroundColor: AppColors.white,
      builder: (_) =>
          ListingBrandSheet(brands: cubit.state.brands, selected: current),
    );
    if (picked != null) await cubit.setBrandSlug(picked.slug);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductListingCubit, ProductListingState>(
      buildWhen: (previous, current) =>
          previous.query != current.query ||
          previous.brands != current.brands ||
          previous.isLoadingBrands != current.isLoadingBrands,
      builder: (context, state) {
        final query = state.query;
        final brand = query.brandSlug;
        return SizedBox(
          height: AppSize.s48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.pageMargin,
              vertical: AppSpacing.s8,
            ),
            children: [
              ListingFilterPill(
                label: ListingSortLabel.keyOf(query.sort).tr(),
                icon: Icons.swap_vert_rounded,
                isDropdown: true,
                selected: query.sort != null,
                onTap: () => _pickSort(context, query.sort),
              ),
              if (!state.brandLocked) ...[
                const SizedBox(width: AppSpacing.s8),
                ListingFilterPill(
                  label: brand == null
                      ? 'shop.brand'.tr()
                      : state.brandNameOf(brand),
                  isDropdown: true,
                  selected: brand != null,
                  onTap: () => _pickBrand(context, brand),
                ),
              ],
              const SizedBox(width: AppSpacing.s8),
              ListingFilterPill(
                label: 'shop.in_stock_only'.tr(),
                selected: query.inStockOnly,
                onTap: () =>
                    context.read<ProductListingCubit>().toggleInStockOnly(),
              ),
              const SizedBox(width: AppSpacing.s8),
              ListingFilterPill(
                label: 'shop.on_sale_only'.tr(),
                selected: query.onSaleOnly,
                onTap: () =>
                    context.read<ProductListingCubit>().toggleOnSaleOnly(),
              ),
            ],
          ),
        );
      },
    );
  }
}
