import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../domain/entities/category_browse.dart';
import '../../cubit/category_browse_cubit.dart';
import '../../cubit/category_browse_state.dart';
import 'category_tab.dart';

/// The store's top-level categories as the app bar's tab row. Picking one
/// re-scopes everything below it (the sub-category rail, the chips and the
/// product grid); the bar keeps its height while the tree loads so the page
/// does not jump.
class CategoryTabBar extends StatelessWidget implements PreferredSizeWidget {
  const CategoryTabBar({super.key, this.level = 0});

  /// Which browse level this bar offers (the store tab's top level).
  final int level;

  static const double _height = AppSize.s48;

  @override
  Size get preferredSize => const Size.fromHeight(_height);

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.white,
      child: SizedBox(
        height: _height,
        child:
            BlocSelector<
              CategoryBrowseCubit,
              CategoryBrowseState,
              CategoryBrowse
            >(
              selector: (state) => state.browse,
              builder: (context, browse) {
                final options = browse.optionsAt(level);
                if (options.isEmpty) return const SizedBox.shrink();
                final selected = browse.selectionAt(level);
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpacing.s8,
                  ),
                  itemCount: options.length,
                  addAutomaticKeepAlives: false,
                  itemBuilder: (context, index) => CategoryTab(
                    key: ValueKey<String>(options[index].id),
                    label: options[index].name,
                    selected: options[index].id == selected?.id,
                    onTap: () => context.read<CategoryBrowseCubit>().select(
                      level,
                      options[index],
                    ),
                  ),
                );
              },
            ),
      ),
    );
  }
}
