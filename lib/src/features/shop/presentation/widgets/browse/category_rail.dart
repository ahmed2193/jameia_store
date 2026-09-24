import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../domain/entities/category_browse.dart';
import '../../cubit/category_browse_cubit.dart';
import '../../cubit/category_browse_state.dart';
import 'category_rail_item.dart';

/// The sub-categories of the open category as a circle rail, "All" first.
/// Picking one re-scopes the chips and the product grid below; picking "All"
/// goes back to the whole category (the backend's `categorySlug` filter
/// includes every descendant, so the parent row is a real list).
///
/// Renders nothing while the level above has no pick, or when the open
/// category has no sub-categories.
class CategoryRail extends StatelessWidget {
  const CategoryRail({super.key, required this.level});

  /// The browse level this rail offers.
  final int level;

  static const double _height = AppSize.s108;
  static const double _itemWidth = AppSize.s78;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      CategoryBrowseCubit,
      CategoryBrowseState,
      CategoryBrowse
    >(
      selector: (state) => state.browse,
      builder: (context, browse) {
        final options = browse.optionsAt(level);
        if (options.isEmpty) return const SizedBox.shrink();
        final parent = browse.parentAt(level);
        final selected = browse.selectionAt(level);
        final cubit = context.read<CategoryBrowseCubit>();
        return Container(
          height: _height,
          color: AppColors.white,
          padding: const EdgeInsetsDirectional.symmetric(
            vertical: AppSpacing.s6,
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.s8,
            ),
            itemExtent: _itemWidth,
            itemCount: options.length + 1,
            addAutomaticKeepAlives: false,
            itemBuilder: (context, index) {
              if (index == 0) {
                return CategoryRailItem(
                  label: 'shop.all'.tr(),
                  image: parent?.image ?? '',
                  selected: selected == null,
                  onTap: () => cubit.select(level, null),
                );
              }
              final category = options[index - 1];
              return CategoryRailItem(
                key: ValueKey<String>(category.id),
                label: category.name,
                image: category.image,
                selected: category.id == selected?.id,
                onTap: () => cubit.select(level, category),
              );
            },
          ),
        );
      },
    );
  }
}
