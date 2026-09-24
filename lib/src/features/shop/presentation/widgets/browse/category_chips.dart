import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../domain/entities/category_browse.dart';
import '../../cubit/category_browse_cubit.dart';
import '../../cubit/category_browse_state.dart';
import 'category_chip.dart';

/// The deepest category row: the children of the picked sub-category as pills,
/// "All" first. Empty (and invisible) when that sub-category is a leaf.
class CategoryChips extends StatelessWidget {
  const CategoryChips({super.key, required this.level});

  /// The browse level these chips offer.
  final int level;

  static const double _height = AppSize.s48;

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
        final selected = browse.selectionAt(level);
        final cubit = context.read<CategoryBrowseCubit>();
        return Container(
          height: _height,
          color: AppColors.white,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.pageMargin,
              vertical: AppSpacing.s8,
            ),
            itemCount: options.length + 1,
            addAutomaticKeepAlives: false,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s8),
            itemBuilder: (context, index) {
              if (index == 0) {
                return CategoryChip(
                  label: 'shop.all'.tr(),
                  selected: selected == null,
                  onTap: () => cubit.select(level, null),
                );
              }
              final category = options[index - 1];
              return CategoryChip(
                key: ValueKey<String>(category.id),
                label: category.name,
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
