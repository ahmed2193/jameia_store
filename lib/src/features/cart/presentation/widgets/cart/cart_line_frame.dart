import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/widgets/jameia_line_thumb.dart';

/// The frame every row of the cart list shares — the picture, the text
/// [body], then the [trailing] control — so paid lines and gifts line up in
/// the one list.
class CartLineFrame extends StatelessWidget {
  const CartLineFrame({
    super.key,
    required this.imageUrl,
    required this.body,
    required this.trailing,
  });

  final String imageUrl;
  final Widget body;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.gutter,
        vertical: AppSpacing.s12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          JameiaLineThumb(url: imageUrl),
          const SizedBox(width: AppSpacing.s12),
          Expanded(child: body),
          const SizedBox(width: AppSpacing.s8),
          trailing,
        ],
      ),
    );
  }
}
