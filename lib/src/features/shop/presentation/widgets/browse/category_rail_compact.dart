import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/domain/entities/catalog_category_entity.dart';
import '../../../domain/entities/category_browse.dart';
import '../../cubit/category_browse_cubit.dart';
import '../../cubit/category_browse_state.dart';
import 'category_rail_chip.dart';

/// The sub-category rail folded into one row of chips — the same entries as
/// `CategoryRail`, "All" first — for while the listing is scrolled. Each time
/// it comes into view it brings the open sub-category into sight, and a pick
/// here calls [onPicked] (the header takes the list back to the top).
class CategoryRailCompact extends StatefulWidget {
  const CategoryRailCompact({
    super.key,
    required this.level,
    required this.shown,
    required this.onPicked,
  });

  /// The browse level this row offers.
  final int level;

  /// Whether the row is the one in view (the header has folded).
  final bool shown;
  final VoidCallback onPicked;

  @override
  State<CategoryRailCompact> createState() => _CategoryRailCompactState();
}

class _CategoryRailCompactState extends State<CategoryRailCompact> {
  static const double _centered = 0.5;

  /// Where the open sub-category's chip is, to bring it into sight.
  final GlobalKey _selectedChip = GlobalKey();

  @override
  void didUpdateWidget(CategoryRailCompact oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shown && !oldWidget.shown) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _revealSelected());
    }
  }

  void _revealSelected() {
    final chip = _selectedChip.currentContext;
    final box = chip?.findRenderObject();
    if (!mounted || chip == null || box == null) return;
    // Only this row moves (`Scrollable.ensureVisible` would scroll the list
    // too), and with no glide: the row is still fading in.
    Scrollable.of(chip).position.ensureVisible(box, alignment: _centered);
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      CategoryBrowseCubit,
      CategoryBrowseState,
      CategoryBrowse
    >(
      selector: (state) => state.browse,
      builder: (context, browse) {
        final level = widget.level;
        final options = browse.optionsAt(level);
        if (options.isEmpty) return const SizedBox.shrink();
        final selected = browse.selectionAt(level);
        final cubit = context.read<CategoryBrowseCubit>();
        void pick(CatalogCategoryEntity? category) {
          cubit.select(level, category);
          widget.onPicked();
        }

        // "All" first; a handful of chips, all built, so the open one is
        // always there to bring into sight.
        final entries = [null, ...options];
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.s16,
          ),
          child: Row(
            children: [
              for (final (index, category) in entries.indexed) ...[
                if (index > 0) const SizedBox(width: AppSpacing.s8),
                CategoryRailChip(
                  key: category?.id == selected?.id
                      ? _selectedChip
                      : ValueKey<int>(index),
                  label: category?.name ?? 'shop.all'.tr(),
                  image: category?.image ?? '',
                  all: category == null,
                  selected: category?.id == selected?.id,
                  onTap: () => pick(category),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
