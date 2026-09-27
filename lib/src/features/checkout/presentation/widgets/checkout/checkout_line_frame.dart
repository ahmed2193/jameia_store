import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/jameia_line_thumb.dart';

/// The frame every row of the items sheet shares — so paid lines and gifts
/// line up in the one list: the 56 dp thumb, then a text column at least as
/// tall as the thumb with [top] (the name) at its top and [bottom] (tags and
/// price) at its bottom, read as one element; an optional [below] (its own
/// control, e.g. "Remove") under it.
class CheckoutLineFrame extends StatelessWidget {
  const CheckoutLineFrame({
    super.key,
    required this.imageUrl,
    required this.top,
    required this.bottom,
    this.below,
  });

  final String imageUrl;
  final Widget top;
  final Widget bottom;
  final Widget? below;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: AppSpacing.s8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          JameiaLineThumb(url: imageUrl),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                MergeSemantics(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: AppSize.s56),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [top, bottom],
                    ),
                  ),
                ),
                ?below,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
