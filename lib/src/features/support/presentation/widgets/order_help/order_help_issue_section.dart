import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/domain/entities/order_line_entity.dart';
import '../../../domain/entities/order_help_issue.dart';
import 'order_help_issue_tile.dart';

/// One category of "What went wrong?" (Order, Delivery, Payment …): its
/// name as a quiet label, then its issues as choice cards.
class OrderHelpIssueSection extends StatelessWidget {
  const OrderHelpIssueSection({
    super.key,
    required this.group,
    required this.lines,
  });

  final OrderHelpIssueGroup group;
  final List<OrderLineEntity> lines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.gutter,
            AppSpacing.s16,
            AppSpacing.gutter,
            AppSpacing.s4,
          ),
          child: Semantics(
            header: true,
            child: Text(
              group.category.labelKey.tr(),
              style: AppTextStyles.label.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
          ),
        ),
        for (final issue in group.issues)
          OrderHelpIssueTile(
            key: ValueKey<OrderHelpIssue>(issue),
            issue: issue,
            lines: lines,
          ),
      ],
    );
  }
}
