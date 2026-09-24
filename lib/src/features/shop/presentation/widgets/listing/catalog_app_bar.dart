import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/routes.dart';
import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';

/// App bar of the catalogue pages: title, a search shortcut and — on the
/// store's own page — the top-level category tabs underneath.
class CatalogAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CatalogAppBar({super.key, required this.title, this.bottom});

  final String title;

  /// Pinned under the title (the category tab bar), so it never scrolls away.
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.white,
      surfaceTintColor: AppColors.white,
      elevation: 0,
      centerTitle: false,
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.headingMedium.copyWith(
          fontWeight: AppTextStyles.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search_rounded, color: AppColors.primaryText),
          onPressed: () => context.push(Routes.search),
        ),
        const SizedBox(width: AppSpacing.s4),
      ],
      bottom: bottom,
    );
  }
}
