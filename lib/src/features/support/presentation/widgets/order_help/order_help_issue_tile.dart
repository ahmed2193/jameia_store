import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/domain/entities/order_line_entity.dart';
import '../../../../../core/motion/collapse_reveal.dart';
import '../../../../../core/widgets/option_row.dart';
import '../../../domain/entities/order_help_issue.dart';
import '../../cubit/order_help_cubit.dart';
import 'order_help_items_picker.dart';

/// One answer to "What went wrong?": a choice card (mint once chosen), and
/// — for an issue about particular items — the item picker opening right
/// under it while it is the chosen one. It selects only "am I chosen", so
/// a pick rebuilds the two rows that change.
class OrderHelpIssueTile extends StatelessWidget {
  const OrderHelpIssueTile({
    super.key,
    required this.issue,
    required this.lines,
  });

  final OrderHelpIssue issue;

  /// The order's items, for the picker.
  final List<OrderLineEntity> lines;

  @override
  Widget build(BuildContext context) {
    final selected = context.select<OrderHelpCubit, bool>(
      (cubit) => cubit.state.request.issue == issue,
    );
    final row = Padding(
      // The card look pads 12 dp itself: together, the page's gutter.
      padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.s4),
      child: OptionRow(
        title: issue.labelKey.tr(),
        selected: selected,
        look: OptionRowLook.card,
        onTap: () => context.read<OrderHelpCubit>().selectIssue(issue),
      ),
    );
    if (!issue.requireProducts) return row;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        row,
        CollapseReveal(
          visible: selected,
          child: OrderHelpItemsPicker(lines: lines),
        ),
      ],
    );
  }
}
