import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/widgets/jameia_section_header.dart';
import '../../../../../core/widgets/jameia_surface_card.dart';

/// One invoice section: a group title over a hairline card of summary rows
/// in the page gutters. Every section of the invoice uses this shell, so they
/// share one rhythm.
class InvoiceSection extends StatelessWidget {
  const InvoiceSection({
    super.key,
    required this.title,
    required this.children,
    this.headerPadding = between,
  });

  /// The first section: close under the title bar.
  static const EdgeInsetsGeometry pageTop = EdgeInsetsDirectional.fromSTEB(
    AppSpacing.gutter,
    AppSpacing.s16,
    AppSpacing.gutter,
    AppSpacing.s8,
  );

  /// Any later section: a section gap above it.
  static const EdgeInsetsGeometry between = EdgeInsetsDirectional.fromSTEB(
    AppSpacing.gutter,
    AppSpacing.section,
    AppSpacing.gutter,
    AppSpacing.s8,
  );

  final String title;
  final List<Widget> children;
  final EdgeInsetsGeometry headerPadding;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        JameiaSectionHeader(
          title: title,
          titleStyle: AppTextStyles.groupTitle,
          padding: headerPadding,
        ),
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.gutter,
          ),
          child: JameiaSurfaceCard(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.s16,
              vertical: AppSpacing.s8,
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: children),
          ),
        ),
      ],
    );
  }
}
