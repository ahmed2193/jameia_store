import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/responsive/app_size.dart';
import 'invoice_perforation_painter.dart';

/// The receipt's tear line above the total: a dashed hairline with room
/// around it. Decoration only — screen readers skip it.
class InvoicePerforation extends StatelessWidget {
  const InvoicePerforation({super.key});

  static const InvoicePerforationPainter _painter = InvoicePerforationPainter(
    color: AppColors.divider,
    dash: AppSize.s6,
    gap: AppSize.s4,
    thickness: AppSize.s2,
  );

  @override
  Widget build(BuildContext context) {
    return const ExcludeSemantics(
      child: Padding(
        padding: EdgeInsetsDirectional.symmetric(vertical: AppSpacing.s8),
        child: SizedBox(
          height: AppSize.s2,
          width: double.infinity,
          child: CustomPaint(painter: _painter),
        ),
      ),
    );
  }
}
