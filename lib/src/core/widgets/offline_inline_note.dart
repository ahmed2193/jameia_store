import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_text_styles.dart';
import '../design/hero_icons.dart';
import '../responsive/app_size.dart';
import './hero_icon.dart';

/// One calm line saying that something needs the connection — the search
/// list offline, a list's "load more" footer, a product page whose details
/// could not load (while the app checks the connection, [leading] is a
/// loader instead of the no-Wi-Fi mark). Screen readers announce it once
/// when it appears.
class OfflineInlineNote extends StatelessWidget {
  const OfflineInlineNote({
    super.key,
    required this.message,
    this.padding = defaultPadding,
    this.leading = _offlineMark,
  });

  static const Widget _offlineMark = HeroIcon(
    HeroIcons.offline,
    size: AppSize.s20,
    color: AppColors.secondaryText,
  );

  static const EdgeInsetsGeometry defaultPadding =
      EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.gutter,
        vertical: AppSpacing.s12,
      );

  final String message;
  final EdgeInsetsGeometry padding;

  /// Before the text, on the start side.
  final Widget leading;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    liveRegion: true,
    child: Padding(
      padding: padding,
      child: Row(
        children: [
          leading,
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
