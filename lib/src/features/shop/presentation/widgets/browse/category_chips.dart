import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/motion.dart';
import '../../../domain/entities/category_browse.dart';
import '../../cubit/category_browse_cubit.dart';
import '../../cubit/category_browse_state.dart';
import 'category_chip.dart';

/// The deepest category row: the children of the picked sub-category as pills,
/// "All" first. The open pill glides to the middle of the row when picked.
/// Empty (and invisible) when that sub-category is a leaf.
class CategoryChips extends StatefulWidget {
  const CategoryChips({super.key, required this.level});

  /// The browse level these chips offer.
  final int level;

  @override
  State<CategoryChips> createState() => _CategoryChipsState();
}

class _CategoryChipsState extends State<CategoryChips> {
  static const double _centered = 0.5;

  /// The open pill, to bring it into sight.
  final GlobalKey _selectedChip = GlobalKey();

  /// The pill last brought into sight.
  String? _revealed;

  /// Glides the open pill to the middle — only this row moves
  /// (`Scrollable.ensureVisible` would scroll the listing too).
  void _reveal(String pick) {
    if (pick == _revealed) return;
    final first = _revealed == null;
    _revealed = pick;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chip = _selectedChip.currentContext;
      final box = chip?.findRenderObject();
      if (!mounted || chip == null || box == null) return;
      Scrollable.of(chip).position.ensureVisible(
        box,
        alignment: _centered,
        duration: first || MotionGuard.reduced(context)
            ? Duration.zero
            : AppMotion.page,
        curve: AppMotion.emphasizedDecelerate,
      );
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
          _revealed = null;
          return const SizedBox.shrink();
        }
        final selected = browse.selectionAt(level);
        final cubit = context.read<CategoryBrowseCubit>();
        // Keyed by the row too: another sub-category's pills start over.
        _reveal('${browse.parentAt(level)?.id}/${selected?.id ?? ''}');
        // "All" first; a handful of pills, all built, so the open one is
        // always there to bring into sight.
        final entries = [null, ...options];
        return ColoredBox(
          color: AppColors.white,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.s16,
              vertical: AppSpacing.s8,
            ),
            child: Row(
              children: [
                for (final (index, category) in entries.indexed) ...[
                  if (index > 0) const SizedBox(width: AppSpacing.s8),
                  CategoryChip(
                    key: category?.id == selected?.id
                        ? _selectedChip
                        : ValueKey<int>(index),
                    label: category?.name ?? 'shop.all'.tr(),
                    selected: category?.id == selected?.id,
                    onTap: () => cubit.select(level, category),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
