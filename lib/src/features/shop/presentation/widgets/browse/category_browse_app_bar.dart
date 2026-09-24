import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubit/category_browse_cubit.dart';
import '../../cubit/category_browse_state.dart';
import '../listing/catalog_app_bar.dart';

/// App bar of a category page: the name whoever opened it passed, replaced by
/// the backend's (language-resolved) name as soon as the tree arrives.
class CategoryBrowseAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const CategoryBrowseAppBar({super.key, required this.fallbackTitle});

  final String fallbackTitle;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return BlocSelector<CategoryBrowseCubit, CategoryBrowseState, String>(
      selector: (state) => state.browse.base?.name ?? fallbackTitle,
      builder: (context, title) => CatalogAppBar(title: title),
    );
  }
}
