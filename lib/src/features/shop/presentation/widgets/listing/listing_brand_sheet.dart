import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/motion/size_fade_switcher.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../cubit/product_listing_cubit.dart';
import '../../cubit/product_listing_state.dart';
import 'listing_brand_list.dart';

/// Bottom sheet of the listing's brand filter. It opens at once (B3-02) and
/// follows the listing's brand read: the loader while the first list is on
/// its way, then the brands (the saved list, then the server's) — the sheet
/// grows to them as they fade in. With nothing to offer it says so.
class ListingBrandSheet extends StatelessWidget {
  const ListingBrandSheet({super.key, required this.selected});

  /// The brand slug the list is filtered by, `null` for all of them.
  final String? selected;

  static const Object _loadingKey = #loading;
  static const Object _emptyKey = #empty;
  static const Object _listKey = #list;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: BlocBuilder<ProductListingCubit, ProductListingState>(
        buildWhen: (previous, current) =>
            previous.brands != current.brands ||
            previous.isLoadingBrands != current.isLoadingBrands,
        builder: (context, state) {
          final brands = state.brands;
          final waiting = brands.isEmpty && state.isLoadingBrands;
          return SizeFadeSwitcher(
            stateKey: brands.isNotEmpty
                ? _listKey
                : (waiting ? _loadingKey : _emptyKey),
            child: brands.isNotEmpty
                ? ListingBrandList(brands: brands, selected: selected)
                : Padding(
                    padding: const EdgeInsets.all(AppSpacing.s24),
                    child: waiting
                        ? const Center(child: AppLoader.inline())
                        : EmptyStateView(
                            message: 'shop.no_brands'.tr(),
                            icon: HeroIcons.tag,
                          ),
                  ),
          );
        },
      ),
    );
  }
}
