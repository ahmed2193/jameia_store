import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/routes.dart';
import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/responsive/app_size.dart';
import 'catalog_app_bar_title.dart';
import 'catalog_round_button.dart';

/// App bar of the catalogue pages: a round back button, the title at the
/// start, a round search shortcut — and, on the store's own page, the
/// top-level category tabs underneath. The title fades across when it
/// changes (a category page names the sub-category tree once it loads).
class CatalogAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CatalogAppBar({super.key, required this.title, this.bottom});

  final String title;

  /// Pinned under the title (the category tab bar), so it never scrolls away.
  final PreferredSizeWidget? bottom;

  static const double _barHeight = AppSize.s64;

  @override
  Size get preferredSize =>
      Size.fromHeight(_barHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final strings = MaterialLocalizations.of(context);
    final canGoBack = context.canPop();
    return AppBar(
      backgroundColor: AppColors.white,
      surfaceTintColor: AppColors.white,
      elevation: 0,
      toolbarHeight: _barHeight,
      automaticallyImplyLeading: false,
      titleSpacing: AppSpacing.s16,
      centerTitle: false,
      title: Row(
        children: [
          if (canGoBack) ...[
            CatalogRoundButton(
              icon: Icons.arrow_back_rounded,
              label: strings.backButtonTooltip,
              onTap: () => context.pop(),
            ),
            const SizedBox(width: AppSpacing.s12),
          ],
          Expanded(child: CatalogAppBarTitle(title: title)),
        ],
      ),
      actions: [
        CatalogRoundButton(
          icon: Icons.search_rounded,
          label: strings.searchFieldLabel,
          onTap: () => context.push(Routes.search),
        ),
        const SizedBox(width: AppSpacing.s16),
      ],
      bottom: bottom,
    );
  }
}
