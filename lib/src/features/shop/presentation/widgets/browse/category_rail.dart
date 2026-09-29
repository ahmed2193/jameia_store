import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../domain/entities/category_browse.dart';
import '../../cubit/category_browse_cubit.dart';
import '../../cubit/category_browse_state.dart';
import 'category_rail_item.dart';

/// The sub-categories of the open category as a circle rail, "All" first.
/// Picking one re-scopes the chips and the product grid below; picking "All"
/// goes back to the whole category (the backend's `categorySlug` filter
/// includes every descendant, so the parent row is a real list). The rail
/// glides the open one to its middle, so the next pick is always in reach.
///
/// Renders nothing while the level above has no pick, or when the open
/// category has no sub-categories. On a listing it rides in a
/// `CategoryRailHeader`, which folds it into a row of chips while scrolling.
class CategoryRail extends StatefulWidget {
  const CategoryRail({super.key, required this.level});

  /// The browse level this rail offers.
  final int level;

  /// The rail's full height; `CategoryRailHeader` shrinks it from here.
  static const double height = AppSize.s108;

  @override
  State<CategoryRail> createState() => _CategoryRailState();
}

class _CategoryRailState extends State<CategoryRail> {
  static const double _itemWidth = AppSize.s78;
  static const double _edge = AppSpacing.s8;

  final ScrollController _rail = ScrollController();

  /// The entry last brought to the middle (null before the first layout),
  /// and the category whose rail that was.
  int? _centered;
  String? _railOf;

  @override
  void dispose() {
    _rail.dispose();
    super.dispose();
  }

  /// Brings entry [index] to the middle of the rail: at once the first time
  /// (a page opened on a sub-category), gliding after a pick.
  void _center(int index) {
    if (index == _centered) return;
    final first = _centered == null;
    _centered = index;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_rail.hasClients) return;
      final position = _rail.position;
      final target =
          (_edge +
                  index * _itemWidth +
                  _itemWidth / 2 -
                  position.viewportDimension / 2)
              .clamp(position.minScrollExtent, position.maxScrollExtent);
      if (first) {
        _rail.jumpTo(target);
      } else {
        MotionGuard.scrollTo(
          context,
          position,
          target,
          curve: AppMotion.emphasizedDecelerate,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final level = widget.level;
    return BlocSelector<
      CategoryBrowseCubit,
      CategoryBrowseState,
      CategoryBrowse
    >(
      selector: (state) => state.browse,
      builder: (context, browse) {
        final options = browse.optionsAt(level);
        if (options.isEmpty) {
          _centered = null;
          return const SizedBox.shrink();
        }
        final parent = browse.parentAt(level);
        if (parent?.id != _railOf) {
          // Another category's rail: it starts over, without a glide.
          _railOf = parent?.id;
          _centered = null;
        }
        final selected = browse.selectionAt(level);
        final cubit = context.read<CategoryBrowseCubit>();
        final selectedIndex = selected == null
            ? 0
            : options.indexWhere((option) => option.id == selected.id) + 1;
        _center(selectedIndex);
        return Container(
          height: CategoryRail.height,
          color: AppColors.white,
          padding: const EdgeInsetsDirectional.symmetric(
            vertical: AppSpacing.s6,
          ),
          child: ListView.builder(
            controller: _rail,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsetsDirectional.symmetric(horizontal: _edge),
            itemExtent: _itemWidth,
            itemCount: options.length + 1,
            addAutomaticKeepAlives: false,
            itemBuilder: (context, index) {
              if (index == 0) {
                return CategoryRailItem(
                  label: 'shop.all'.tr(),
                  image: '',
                  all: true,
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
