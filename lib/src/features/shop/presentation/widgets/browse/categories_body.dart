import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/utils/failure_message.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../cubit/category_browse_cubit.dart';
import '../../cubit/category_browse_state.dart';
import '../listing/product_listing_body.dart';
import 'category_chips.dart';
import 'category_rail.dart';

/// Body of the store page. The tabs live in the app bar; here comes the
/// sub-category rail of the open tab, its chips and the products. The tree is
/// what the whole page is built from, so its loader / error / empty state
/// replace the body — unlike a category page, where the products load on their
/// own and only the rows wait for the tree.
class CategoriesBody extends StatelessWidget {
  const CategoriesBody({super.key, required this.onRefresh});

  /// Reloads the tree and the products.
  final Future<void> Function() onRefresh;

  /// Level 0 is the app bar's tab row.
  static const int _railLevel = 1;
  static const int _chipsLevel = 2;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CategoryBrowseCubit, CategoryBrowseState>(
      buildWhen: (previous, current) =>
          previous.status != current.status ||
          previous.isEmpty != current.isEmpty,
      builder: (context, state) {
        final cubit = context.read<CategoryBrowseCubit>();
        return switch (state.status) {
          CategoryBrowseStatus.initial ||
          CategoryBrowseStatus.loading => const AppLoader(),
          CategoryBrowseStatus.error => ErrorView(
            message: state.failure?.localizedMessage,
            onRetry: cubit.load,
          ),
          CategoryBrowseStatus.loaded when state.isEmpty => EmptyStateView(
            message: 'shop.no_categories'.tr(),
            icon: Icons.category_outlined,
          ),
          CategoryBrowseStatus.loaded => ProductListingBody(
            onRefresh: onRefresh,
            headerSlivers: const [
              SliverToBoxAdapter(child: CategoryRail(level: _railLevel)),
              SliverToBoxAdapter(child: CategoryChips(level: _chipsLevel)),
            ],
          ),
        };
      },
    );
  }
}
