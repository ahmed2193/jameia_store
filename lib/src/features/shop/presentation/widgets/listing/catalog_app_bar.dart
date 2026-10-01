import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/routes.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/widgets/hero_bar_action.dart';
import '../../../../../core/widgets/hero_title_bar.dart';

/// Title bar of the catalogue pages (the shared [HeroTitleBar]): the round
/// back button, the title at the start (it flips when it changes — a
/// category page names the sub-category tree once it loads), the search
/// shortcut — and, on the store's own page, the top-level category tabs
/// pinned underneath.
class CatalogAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CatalogAppBar({super.key, required this.title, this.bottom});

  final String title;

  /// Pinned under the title (the category tab bar), so it never scrolls away.
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize => Size.fromHeight(
    HeroTitleBar.height + (bottom?.preferredSize.height ?? 0),
  );

  @override
  Widget build(BuildContext context) {
    return HeroTitleBar(
      title: title,
      bottom: bottom,
      actions: [
        HeroBarAction(
          icon: HeroIcons.search,
          tooltip: MaterialLocalizations.of(context).searchFieldLabel,
          onPressed: () => context.push(Routes.search),
        ),
      ],
    );
  }
}
